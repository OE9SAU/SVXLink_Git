# Parrot AudioCheck V1.01 - Testbetrieb
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

        # Logfile-Ausgabe erfolgt direkt in C++

        playSilence 500
        playAudioLevel $rms

        playSilence 1000
        playAudioLevel $peak

        playSilence 500
    }


    proc audiocheck_invalid {} {
        # Ungueltige Messung wird bereits in C++ protokolliert
    }
}
