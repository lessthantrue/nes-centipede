.include "gamestates.inc"
.include "../gamestaterunner.inc"
.include "menu.inc"
.include "../nes.inc"
.include "../core/macros.inc"
.include "../core/common.inc"
.include "../game/statusbar.inc"
.include "../printer.inc"
.include "../highscores.inc"

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
    bne :++
        call_with_args highscore_cmp, score+2, score+1, score, #SCORES_COUNT-1
        cpy #0
        beq :+
            swap_state highscore
            jmp :++
        :
            swap_state menu
    :
    rts
.endproc

.export state_gameover_load := load
.export state_gameover_transition := transition-1
.export state_gameover_bg := bg-1
.export state_gameover_logic := empty-1