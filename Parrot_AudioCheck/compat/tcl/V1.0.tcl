# Parrot AudioCheck V1.0 - Testbetrieb
# ==================================================

namespace eval Parrot {

    proc playAudioLevel {level} {
        set level [expr {int(round($level))}]

        if {$level < 0} {
            ::playMsg "Default" "minus"
            set level [expr {abs($level)}]
        }

        ::playNumber $level
    }


    proc audiocheck_result {rms peak result peak_warning} {

        printInfo "AudioCheck V1.0: RMS=$rms dBFS, Peak=$peak dBFS, Result=$result, PeakWarning=$peak_warning"

        playSilence 500
        playAudioLevel $rms

        playSilence 1000
        playAudioLevel $peak

        playSilence 500
    }


    proc audiocheck_invalid {} {
        printInfo "AudioCheck V1.0: Invalid measurement"
    }
}
