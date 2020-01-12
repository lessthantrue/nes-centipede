.include "gamestates.inc"
.include "../gamestaterunner.inc"
.include "../core/macros.inc"
.include "../nes.inc"
.include "../ppuclear.inc"
.include "../game/game.inc"

; this state exists because some background drawing needs to be done
; before moving from main menu to playing

.segment "CODE"

.proc state_play_init_logic
    rts
.endproc

.proc state_play_init_bg
    ; turn off background drawing for this
    lda #0
    sta PPUMASK
    jsr board_draw
    rts
.endproc

.proc state_play_init_transition
    swap_state playing
    rts
.endproc