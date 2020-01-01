.include "dead.inc"
.include "../centipede.inc"
.include "../arrow.inc"

.segment "BSS"
dead_timer:     .byte $FF

.segment "CODE"

.proc state_dead_logic
    rts
.endproc

.proc state_dead_bg
    rts
.endproc

.proc state_dead_transition
    rts
.endproc