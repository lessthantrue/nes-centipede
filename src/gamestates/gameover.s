.include "gamestates.inc"
.include "../gamestaterunner.inc"
.include "menu.inc"
.include "../nes.inc"
.include "../core/macros.inc"
.include "../core/common.inc"
.include "../game/statusbar.inc"
.include "../printer.inc"

.segment "BSS"
state_gameover_delay:   .res 1

.segment "CODE"
gameover_msg: pstring "GAME OVER"

.proc load
    lda #240
    sta state_gameover_delay
    rts
.endproc

.proc bg
    st_addr (gameover_msg+1), strptr
    lda gameover_msg
    sta strlen
    call_with_args print_centered, #13
    rts
.endproc

.proc transition
    dec state_gameover_delay
    bne :+
        jsr statusbar_init
        swap_state highscore
    :
    rts
.endproc

.export state_gameover_load := load
.export state_gameover_transition := transition-1
.export state_gameover_bg := bg-1
.export state_gameover_logic := empty-1