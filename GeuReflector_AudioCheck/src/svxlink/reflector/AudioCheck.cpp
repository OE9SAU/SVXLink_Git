#include "AudioCheck.h"

#include <algorithm>
#include <cmath>
#include <vector>

namespace
{
constexpr int SAMPLE_RATE = 16000;
constexpr float MIN_GAIN_DB = -24.0f;
constexpr float MAX_GAIN_DB = 12.0f;
constexpr float ATTACK_SECONDS = 0.100f;
constexpr float RELEASE_SECONDS = 1.0f;
constexpr float NOISE_GATE_DBFS = -34.0f;
constexpr float PEAK_LIMIT_DBFS = -1.0f;

float toDbfs(double value)
{
  return value > 0.0
      ? static_cast<float>(20.0 * std::log10(value))
      : -120.0f;
}
}

AudioCheck::AudioCheck()
{
  int error = OPUS_OK;
  m_decoder = opus_decoder_create(SAMPLE_RATE, 1, &error);

  if (error != OPUS_OK)
  {
    m_decoder = nullptr;
  }

  error = OPUS_OK;
  m_encoder = opus_encoder_create(
      SAMPLE_RATE, 1, OPUS_APPLICATION_AUDIO, &error);

  if (error != OPUS_OK)
  {
    m_encoder = nullptr;
  }
  else
  {
    opus_encoder_ctl(m_encoder, OPUS_SET_BITRATE(20000));
    opus_encoder_ctl(m_encoder, OPUS_SET_VBR(1));
    opus_encoder_ctl(m_encoder, OPUS_SET_SIGNAL(OPUS_SIGNAL_VOICE));
    opus_encoder_ctl(m_encoder, OPUS_SET_DTX(0));
  }
}

AudioCheck::~AudioCheck()
{
  if (m_decoder != nullptr)
  {
    opus_decoder_destroy(m_decoder);
  }

  if (m_encoder != nullptr)
  {
    opus_encoder_destroy(m_encoder);
  }
}

void AudioCheck::start(const std::string& callsign)
{
  m_callsign = callsign;
  m_active = true;

  m_rms_dbfs = -120.0f;
  m_peak_dbfs = -120.0f;
  m_clipping = false;

  m_output_rms_dbfs = -120.0f;
  m_output_peak_dbfs = -120.0f;
  m_gain_db = 0.0f;

  if (m_decoder != nullptr)
  {
    opus_decoder_ctl(m_decoder, OPUS_RESET_STATE);
  }

  if (m_encoder != nullptr)
  {
    opus_encoder_ctl(m_encoder, OPUS_RESET_STATE);
  }
}

void AudioCheck::stop()
{
  m_active = false;
}

void AudioCheck::setAgcEnabled(bool enabled)
{
  if (m_agc_enabled != enabled)
  {
    m_agc_enabled = enabled;
    m_gain_db = 0.0f;
  }
}

bool AudioCheck::setTargetDbfs(float value)
{
  if (!std::isfinite(value) || value < -36.0f || value > -6.0f)
  {
    return false;
  }

  m_target_dbfs = value;
  return true;
}

bool AudioCheck::process(const uint8_t* data, std::size_t size)
{
  if (!m_active || m_decoder == nullptr ||
      data == nullptr || size == 0 || size > 1500)
  {
    return false;
  }

  constexpr int MAX_SAMPLES = SAMPLE_RATE * 120 / 1000;
  std::vector<float> samples(MAX_SAMPLES);

  int count = opus_decode_float(
      m_decoder,
      data,
      static_cast<opus_int32>(size),
      samples.data(),
      MAX_SAMPLES,
      0);

  if (count <= 0)
  {
    return false;
  }

  double sum = 0.0;
  float peak = 0.0f;

  for (int i = 0; i < count; ++i)
  {
    float value = std::abs(samples[i]);
    sum += static_cast<double>(samples[i]) * samples[i];
    peak = std::max(peak, value);
  }

  const double rms = std::sqrt(sum / count);

  m_rms_dbfs = toDbfs(rms);
  m_peak_dbfs = toDbfs(peak);
  m_clipping = peak >= 0.999f;

  // AGC ausgeschaltet: Ausgang entspricht Eingang
  if (!m_agc_enabled)
  {
    m_output_samples.assign(samples.begin(), samples.begin() + count);
    m_gain_db = 0.0f;
    m_output_rms_dbfs = m_rms_dbfs;
    m_output_peak_dbfs = m_peak_dbfs;
    return true;
  }

  const float duration =
      static_cast<float>(count) / SAMPLE_RATE;

  float desired_gain = m_gain_db;

  // In Sprechpausen keine zusätzliche Verstärkung aufbauen.
  if (m_rms_dbfs > NOISE_GATE_DBFS)
  {
    desired_gain = std::max(MIN_GAIN_DB,
        std::min(MAX_GAIN_DB, m_target_dbfs - m_rms_dbfs));
  }

  // Peak-Reserve bereits bei der Verstärkungswahl berücksichtigen.
  if (peak > 0.0f)
  {
    desired_gain = std::min(
        desired_gain,
        PEAK_LIMIT_DBFS - m_peak_dbfs);
  }

  desired_gain = std::max(MIN_GAIN_DB,
      std::min(MAX_GAIN_DB, desired_gain));

  // Schneller absenken, langsamer anheben.
  const float tau =
      desired_gain < m_gain_db
          ? ATTACK_SECONDS
          : RELEASE_SECONDS;

  const float alpha =
      1.0f - std::exp(-duration / tau);

  m_gain_db += alpha * (desired_gain - m_gain_db);

  const float gain =
      std::pow(10.0f, m_gain_db / 20.0f);

  // Bearbeitetes PCM speichern und auswerten.
  m_output_samples.resize(count);
  double output_sum = 0.0;
  float output_peak = 0.0f;

  const float peak_limit =
      std::pow(10.0f, PEAK_LIMIT_DBFS / 20.0f);

  for (int i = 0; i < count; ++i)
  {
    float value = samples[i] * gain;

    // Sicherheitsbegrenzung der Spitzen.
    value = std::max(-peak_limit, std::min(peak_limit, value));
    m_output_samples[i] = value;

    output_sum += static_cast<double>(value) * value;
    output_peak = std::max(output_peak, std::abs(value));
  }

  m_output_rms_dbfs =
      toDbfs(std::sqrt(output_sum / count));

  m_output_peak_dbfs = toDbfs(output_peak);

  return true;
}

// AudioCheck TG 9998: OPUS-Ausgabe mit optionaler AGC
bool AudioCheck::processAndEncode(
    const uint8_t* data,
    std::size_t size,
    std::vector<uint8_t>& output)
{
  output.clear();

  if (data == nullptr || size == 0 || size > 1500)
  {
    return false;
  }

  // Originalsignal immer messen und AGC-PCM vorbereiten.
  if (!process(data, size))
  {
    return false;
  }

  // AGC AUS: Original-OPUS unverändert weitergeben.
  if (!m_agc_enabled)
  {
    output.assign(data, data + size);
    return true;
  }

  if (m_encoder == nullptr || m_output_samples.empty())
  {
    return false;
  }

  const int total_samples =
      static_cast<int>(m_output_samples.size());

  // Paketdauer und Frameaufteilung des Originals ermitteln.
  const int frame_count =
      opus_packet_get_nb_frames(data, static_cast<opus_int32>(size));

  if (frame_count <= 0)
  {
    return false;
  }

  const int frame_size =
      opus_packet_get_samples_per_frame(data, SAMPLE_RATE);

  if (frame_size <= 0 ||
      frame_size > 960 ||
      frame_count * frame_size != total_samples)
  {
    return false;
  }

  OpusRepacketizer* rp = opus_repacketizer_create();
  if (rp == nullptr)
  {
    return false;
  }

  bool success = true;

  for (int i = 0; i < frame_count; ++i)
  {
    unsigned char encoded[1275];

    const opus_int32 encoded_size = opus_encode_float(
        m_encoder,
        m_output_samples.data() + i * frame_size,
        frame_size,
        encoded,
        sizeof(encoded));

    if (encoded_size <= 0 ||
        opus_repacketizer_cat(rp, encoded, encoded_size) != OPUS_OK)
    {
      success = false;
      break;
    }
  }

  if (success)
  {
    unsigned char packet[1275];

    const opus_int32 packet_size =
        opus_repacketizer_out(rp, packet, sizeof(packet));

    if (packet_size > 0)
    {
      output.assign(packet, packet + packet_size);
    }
    else
    {
      success = false;
    }
  }

  opus_repacketizer_destroy(rp);
  return success;
}
