#ifndef AUDIOCHECK_H
#define AUDIOCHECK_H

#include <opus.h>
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

class AudioCheck
{
public:
  AudioCheck();
  ~AudioCheck();

  AudioCheck(const AudioCheck&) = delete;
  AudioCheck& operator=(const AudioCheck&) = delete;

  void start(const std::string& callsign);
  void stop();
  bool process(const uint8_t* data, std::size_t size);

  // AGC-Audio als OPUS-Paket ausgeben.
  // Bei ausgeschalteter AGC bleibt das Originalpaket erhalten.
  bool processAndEncode(const uint8_t* data,
                        std::size_t size,
                        std::vector<uint8_t>& output);

  void setAgcEnabled(bool enabled);
  bool agcEnabled() const { return m_agc_enabled; }

  bool setTargetDbfs(float value);
  float targetDbfs() const { return m_target_dbfs; }

  const std::string& callsign() const { return m_callsign; }
  bool active() const { return m_active; }

  // Eingang vor AGC
  float rmsDbfs() const { return m_rms_dbfs; }
  float peakDbfs() const { return m_peak_dbfs; }
  bool clipping() const { return m_clipping; }

  // Ausgang nach AGC
  float outputRmsDbfs() const { return m_output_rms_dbfs; }
  float outputPeakDbfs() const { return m_output_peak_dbfs; }
  float gainDb() const { return m_gain_db; }

private:
  OpusDecoder* m_decoder = nullptr;
  OpusEncoder* m_encoder = nullptr;

  // PCM-Ausgang der AGC für die anschließende OPUS-Codierung
  std::vector<float> m_output_samples;
  std::string m_callsign;

  bool m_active = false;
  bool m_agc_enabled = false;
  float m_target_dbfs = -12.0f;

  float m_rms_dbfs = -120.0f;
  float m_peak_dbfs = -120.0f;
  bool m_clipping = false;

  float m_output_rms_dbfs = -120.0f;
  float m_output_peak_dbfs = -120.0f;
  float m_gain_db = 0.0f;
};

#endif
