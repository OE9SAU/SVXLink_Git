# Parrot AudioCheck V1.10 - Sprachbewertung
# ==================================================

namespace eval Parrot {

    proc audiocheck_result {rms peak result peak_warning} {

        playSilence 500

        switch -- $result {
            VERY_LOW  { playMsg "level_very_low" }
            LOW       { playMsg "level_low" }
            OPTIMAL   { playMsg "level_ok" }
            HIGH      { playMsg "level_high" }
            VERY_HIGH { playMsg "level_very_high" }
            default   { playMsg "test_invalid" }
        }

        playSilence 500
    }

    proc audiocheck_invalid {} {
        playSilence 500
        playMsg "test_invalid"
        playSilence 500
    }
}
