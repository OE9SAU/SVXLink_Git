/**
@file	 ModuleParrot.cpp
@brief   A module that implements a "parrot" function.
@author  Tobias Blomberg / SM0SVX
@date	 2004-03-21

This module implements a "parrot" function. It plays back everything you say
to it. This can be used as a simplex repeater or just so you can hear how
you sound.

\verbatim
A module (plugin) for the multi purpose tranciever frontend system.
Copyright (C) 2004-2015 Tobias Blomberg / SM0SVX

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
\endverbatim
*/



/****************************************************************************
 *
 * System Includes
 *
 ****************************************************************************/

#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <sstream>
#include <cmath>
#include <iomanip>


/****************************************************************************
 *
 * Project Includes
 *
 ****************************************************************************/

#include <AsyncConfig.h>
#include <AsyncTimer.h>
#include <AsyncAudioFifo.h>
#include <AsyncAudioPassthrough.h>
#include <AsyncAudioValve.h>


/****************************************************************************
 *
 * Local Includes
 *
 ****************************************************************************/

#include "version/MODULE_PARROT.h"
#include "ModuleParrot.h"



/****************************************************************************
 *
 * Namespaces to use
 *
 ****************************************************************************/

using namespace std;
using namespace Async;



/****************************************************************************
 *
 * Defines & typedefs
 *
 ****************************************************************************/



/****************************************************************************
 *
 * Local class definitions
 *
 ****************************************************************************/

class ModuleParrot::FifoAdapter : public AudioPassthrough
{
  public:
    FifoAdapter(ModuleParrot *parrot) : parrot(parrot) {}
    
    virtual int writeSamples(const float *samples, int count) override
    {
      int written = sinkWriteSamples(samples, count);

      if (written > 0)
      {
        parrot->measureAudioSamples(samples, written);
      }

      return written;
    }

    virtual void flushSamples(void)
    {
      sourceAllSamplesFlushed();
      sinkFlushSamples();
    }
    
    virtual void allSamplesFlushed(void)
    {
      parrot->allSamplesWritten();
    }
  
  private:
    ModuleParrot *parrot;
    
}; /* class ModuleParrot::FifoAdapter */


/****************************************************************************
 *
 * Prototypes
 *
 ****************************************************************************/



/****************************************************************************
 *
 * Exported Global Variables
 *
 ****************************************************************************/




/****************************************************************************
 *
 * Local Global Variables
 *
 ****************************************************************************/



/****************************************************************************
 *
 * Pure C-functions
 *
 ****************************************************************************/


extern "C" {
  Module *module_init(void *dl_handle, Logic *logic, const char *cfg_name)
  {
    return new ModuleParrot(dl_handle, logic, cfg_name);
  }
} /* extern "C" */



/****************************************************************************
 *
 * Public member functions
 *
 ****************************************************************************/


ModuleParrot::ModuleParrot(void *dl_handle, Logic *logic,
      	      	      	   const string& cfg_name)
  : Module(dl_handle, logic, cfg_name), adapter(0), fifo(0), valve(0),
    squelch_is_open(false), repeat_delay_timer(-1)
{
  cout << "\tModule Parrot v" MODULE_PARROT_VERSION " starting...\n";
  repeat_delay_timer.expired.connect(
      sigc::hide(mem_fun(*this, &ModuleParrot::onRepeatDelayExpired)));
  
} /* ModuleParrot */


ModuleParrot::~ModuleParrot(void)
{
  AudioSink::clearHandler();
  AudioSource::clearHandler();
  delete adapter; // This will delete all chained audio objects
} /* ~ModuleParrot */


bool ModuleParrot::initialize(void)
{
  if (!Module::initialize())
  {
    return false;
  }
  
  string fifo_len;
  if (!cfg().getValue(cfgName(), "FIFO_LEN", fifo_len))
  {
    std::cerr << "*** ERROR: Config variable " << cfgName()
              << "/FIFO_LEN not set" << std::endl;
    return false;
  }
  int repeat_delay = -1;
  if (cfg().getValue(cfgName(), "REPEAT_DELAY", repeat_delay))
  {
    repeat_delay_timer.setTimeout(repeat_delay);
  }
  
  // Parrot AudioCheck V1.10
  cfg().getValue(cfgName(), "AUDIOCHECK", audio_check_enabled);
  cfg().getValue(cfgName(), "AUDIOCHECK_TARGET_RMS",
                 audio_check_target_rms);
  cfg().getValue(cfgName(), "AUDIOCHECK_TOLERANCE",
                 audio_check_tolerance);
  cfg().getValue(cfgName(), "AUDIOCHECK_PEAK_LIMIT",
                 audio_check_peak_limit);
  cfg().getValue(cfgName(), "AUDIOCHECK_MIN_DURATION",
                 audio_check_min_duration);

  if (!std::isfinite(audio_check_target_rms) ||
      audio_check_target_rms < -60.0 ||
      audio_check_target_rms > 0.0)
  {
    audio_check_target_rms = -20.0;
  }

  if (!std::isfinite(audio_check_tolerance) ||
      audio_check_tolerance <= 0.0 ||
      audio_check_tolerance > 12.0)
  {
    audio_check_tolerance = 3.0;
  }

  if (!std::isfinite(audio_check_peak_limit) ||
      audio_check_peak_limit < -60.0 ||
      audio_check_peak_limit > 0.0)
  {
    audio_check_peak_limit = -6.0;
  }

  if (audio_check_min_duration < 100 ||
      audio_check_min_duration > 60000)
  {
    audio_check_min_duration = 2000;
  }

  if (audio_check_enabled)
  {
    cout << "Parrot: AudioCheck V1.10 initialisiert" << endl;
    cout << "Parrot: RMS-Zielpegel: "
         << audio_check_target_rms << " dBFS" << endl;
    cout << "Parrot: RMS-Toleranz: +/-"
         << audio_check_tolerance << " dB" << endl;
    cout << "Parrot: Spitzenpegelgrenze: "
         << audio_check_peak_limit << " dBFS" << endl;
    cout << "Parrot: Abtastrate: "
         << INTERNAL_SAMPLE_RATE << " Hz" << endl;
    cout << "Parrot: Mindestmessdauer: "
         << audio_check_min_duration << " ms" << endl;
  }

  adapter = new FifoAdapter(this);
  AudioSink::setHandler(adapter);
  
  fifo = new AudioFifo(atoi(fifo_len.c_str())*INTERNAL_SAMPLE_RATE);
  fifo->setOverwrite(true);
  adapter->registerSink(fifo, true);
  
  valve = new AudioValve;
  valve->setBlockWhenClosed(true);
  valve->setOpen(false);
  fifo->registerSink(valve, true);
  
  AudioSource::setHandler(valve);
  
  return true;
  
} /* ModuleParrot::initialize */






/****************************************************************************
 *
 * Protected member functions
 *
 ****************************************************************************/


void ModuleParrot::logicIdleStateChanged(bool is_idle)
{
  /*
  printf("ModuleParrot::logicIdleStateChanged: is_idle=%s fifo->empty()=%s\n",
      is_idle ? "TRUE" : "FALSE",
      fifo->empty() ? "TRUE" : "FALSE");
  */
  Module::logicIdleStateChanged(is_idle);
  
  if (is_idle)
  {
    if (!fifo->empty())
    {
      if (repeat_delay_timer.timeout() > 0)
      {
        repeat_delay_timer.setEnable(true);
      }
      else
      {
        onRepeatDelayExpired();
      }
    }
    else if (!cmd_queue.empty())
    {
      execCmdQueue();
    }
  }
  else
  {
    repeat_delay_timer.setEnable(false);
  }
} /* ModuleParrot::logicIdleStateChanged */




/****************************************************************************
 *
 * Private member functions
 *
 ****************************************************************************/


/*
 *----------------------------------------------------------------------------
 * Method:    activateInit
 * Purpose:   Called by the core system when this module is activated.
 * Input:     None
 * Output:    None
 * Author:    Tobias Blomberg / SM0SVX
 * Created:   2004-03-07
 * Remarks:   
 * Bugs:      
 *----------------------------------------------------------------------------
 */
void ModuleParrot::activateInit(void)
{
  resetAudioCheck();
  fifo->clear();
  cmd_queue.clear();
  valve->setOpen(false);  
} /* activateInit */


/*
 *----------------------------------------------------------------------------
 * Method:    deactivateCleanup
 * Purpose:   Called by the core system when this module is deactivated.
 * Input:     None
 * Output:    None
 * Author:    Tobias Blomberg / SM0SVX
 * Created:   2004-03-07
 * Remarks:   Do NOT call this function directly unless you really know what
 *    	      you are doing. Use Module::deactivate() instead.
 * Bugs:      
 *----------------------------------------------------------------------------
 */
void ModuleParrot::deactivateCleanup(void)
{
  resetAudioCheck();
  audio_check_playback = true;
  valve->setOpen(true);
  fifo->clear();
  repeat_delay_timer.setEnable(false);
} /* deactivateCleanup */


/*
 *----------------------------------------------------------------------------
 * Method:    dtmfDigitReceived
 * Purpose:   Called by the core system when a DTMF digit has been
 *    	      received.
 * Input:     digit   	- The DTMF digit received (0-9, A-D, *, #)
 *    	      duration	- The duration in milliseconds
 * Output:    Return true if the digit is handled or false if not
 * Author:    Tobias Blomberg / SM0SVX
 * Created:   2004-03-07
 * Remarks:   
 * Bugs:      
 *----------------------------------------------------------------------------
 */
bool ModuleParrot::dtmfDigitReceived(char digit, int duration)
{
  //cout << "DTMF digit received in module " << name() << ": " << digit << endl;
  
  return false;
  
} /* dtmfDigitReceived */


/*
 *----------------------------------------------------------------------------
 * Method:    dtmfCmdReceived
 * Purpose:   Called by the core system when a DTMF command has been
 *    	      received. A DTMF command consists of a string of digits ended
 *    	      with a number sign (#). The number sign is not included in the
 *    	      command string.
 * Input:     cmd - The received command.
 * Output:    None
 * Author:    Tobias Blomberg / SM0SVX
 * Created:   2004-03-07
 * Remarks:   
 * Bugs:      
 *----------------------------------------------------------------------------
 */
void ModuleParrot::dtmfCmdReceived(const string& cmd)
{
  cout << "DTMF command received in module " << name() << ": " << cmd << endl;
  
  cmd_queue.push_back(cmd);
  if (fifo->empty() && !squelch_is_open)
  {
    execCmdQueue();
  }
} /* dtmfCmdReceived */


void ModuleParrot::dtmfCmdReceivedWhenIdle(const std::string &cmd)
{
  stringstream ss;
  ss << "spell_digits " << cmd;
  processEvent(ss.str());
} /* dtmfCmdReceivedWhenIdle */


void ModuleParrot::squelchOpen(bool is_open)
{
  squelch_is_open = is_open;
} /* ModuleParrot::squelchOpen */


void ModuleParrot::allSamplesWritten(void)
{
  //cout << "ModuleParrot::allSamplesWritten\n";
  
  if (!cmd_queue.empty())
  {
    execCmdQueue();
  }
  valve->setOpen(false);

  processEvent("all_played");

  if (audio_check_enabled && isActive() &&
      audio_result_pending)
  {
    reportAudioCheck();
    resetAudioCheck();
  }
} /* ModuleParrot::allSamplesWritten */


void ModuleParrot::onRepeatDelayExpired(void)
{
  repeat_delay_timer.setEnable(false);

  if (audio_check_enabled && !audio_check_playback)
  {
    finalizeAudioCheck();
    audio_check_playback = true;
  }

  valve->setOpen(true);
} /* ModuleParrot::onRepeatDelayExpired */


void ModuleParrot::execCmdQueue(void)
{
  //printf("ModuleParrot::execCmdQueue\n");
  
  list<string> cq = cmd_queue;
  cmd_queue.clear();
  
  list<string>::iterator it;
  for (it=cq.begin(); it!=cq.end(); ++it)
  {
    string cmd(*it);
    
    if (cmd == "")
    {
      deactivateMe();
    }
    else
    {
      if (cmd == "0")
      {
	playHelpMsg();
      }
      else
      {
      	stringstream ss;
	ss << "spell_digits " << cmd;
      	processEvent(ss.str());
      }
    }
  }
} /* ModuleParrot::execCmdQueue */




/*
 * This file has not been truncated
 */


/****************************************************************************
 *
 * Parrot AudioCheck V1.10
 *
 ****************************************************************************/

void ModuleParrot::resetAudioCheck(void)
{
  audio_sum_squares = 0.0;
  audio_peak = 0.0;
  audio_sample_count = 0;
  audio_check_invalid = false;
  audio_check_playback = false;

  audio_result_pending = false;
  audio_result_valid = false;
  audio_result_rms = -120.0;
  audio_result_peak = -120.0;
  audio_result_duration = 0.0;
}


void ModuleParrot::measureAudioSamples(
    const float *samples, int count)
{
  if (!audio_check_enabled ||
      !isActive() ||
      audio_check_playback)
  {
    return;
  }

  for (int i = 0; i < count; ++i)
  {
    const double sample = samples[i];

    if (!std::isfinite(sample))
    {
      audio_check_invalid = true;
      continue;
    }

    audio_sum_squares += sample * sample;

    const double amplitude = std::fabs(sample);

    if (amplitude > audio_peak)
    {
      audio_peak = amplitude;
    }

    ++audio_sample_count;
  }
}


void ModuleParrot::finalizeAudioCheck(void)
{
  audio_result_pending = true;
  audio_result_valid = false;

  audio_result_duration =
      static_cast<double>(audio_sample_count) /
      INTERNAL_SAMPLE_RATE;

  if (audio_sample_count == 0 ||
      audio_check_invalid ||
      audio_result_duration * 1000.0 <
          audio_check_min_duration)
  {
    return;
  }

  if (audio_sum_squares <= 0.0 || audio_peak <= 0.0)
  {
    return;
  }

  audio_result_rms = 10.0 * std::log10(
      audio_sum_squares /
      static_cast<double>(audio_sample_count));

  audio_result_peak = 20.0 * std::log10(audio_peak);

  audio_result_valid =
      std::isfinite(audio_result_rms) &&
      std::isfinite(audio_result_peak);
}


void ModuleParrot::reportAudioCheck(void)
{
  if (!audio_result_pending)
  {
    return;
  }

  audio_result_pending = false;

  if (!audio_result_valid)
  {
    cout << "Parrot: AudioCheck V1.10: Messung ungültig oder zu kurz"
         << endl;

    processEvent("audiocheck_invalid");
    return;
  }

  const double lower =
      audio_check_target_rms - audio_check_tolerance;

  const double upper =
      audio_check_target_rms + audio_check_tolerance;

  const char *result;

  if (audio_result_rms < lower - 7.0)
  {
    result = "VERY_LOW";
  }
  else if (audio_result_rms < lower)
  {
    result = "LOW";
  }
  else if (audio_result_rms <= upper)
  {
    result = "OPTIMAL";
  }
  else if (audio_result_rms <= upper + 3.0)
  {
    result = "HIGH";
  }
  else
  {
    result = "VERY_HIGH";
  }

  const bool peak_warning =
      audio_result_peak > audio_check_peak_limit;


  const char *bewertung = "Unbekannt";

  if (std::string(result) == "VERY_LOW")
    bewertung = "Deutlich zu leise";
  else if (std::string(result) == "LOW")
    bewertung = "Etwas zu leise";
  else if (std::string(result) == "OPTIMAL")
    bewertung = "Optimal";
  else if (std::string(result) == "HIGH")
    bewertung = "Etwas zu laut";
  else if (std::string(result) == "VERY_HIGH")
    bewertung = "Deutlich zu laut";

  std::ostringstream log;

  log << std::fixed << std::setprecision(2)
      << "Parrot: AudioCheck V1.10: RMS="
      << audio_result_rms << " dBFS, Peak="
      << audio_result_peak << " dBFS, Bewertung="
      << bewertung;

  cout << log.str() << endl;

  std::ostringstream event;

  event << "audiocheck_result "
        << static_cast<int>(std::round(audio_result_rms))
        << " "
        << static_cast<int>(std::round(audio_result_peak))
        << " "
        << result
        << " "
        << (peak_warning ? 1 : 0);

  processEvent(event.str());
}
