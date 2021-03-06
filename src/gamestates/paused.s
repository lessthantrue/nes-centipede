.include "gamestates.inc"
.include "../core/macros.inc"
.include "../gamestaterunner.inc"
.include "../pads.inc"
.include "../nes.inc"
.include "../core/common.inc"
.include "../game/game.inc"
.include "../ppuclear.inc"
.include "../printer.inc"

.segment "BSS"

pause_buf:  .res 1

.segment "CODE"

pause_msg: pstring "PAUSED"

.proc load
    lda #0
    sta pause_buf
    rts
.endproc

.proc logic
    jsr game_draw
    rts
.endproc

.proc bg
    lda pause_buf
    beq :+
        call_with_args board_redraw_count, #13, #13, #6
        jmp :++
    :
        st_addr (pause_msg+1), strptr
        lda pause_msg
        sta strlen
        call_with_args print_centered, #13
    :
    rts
.endproc

.proc transition
    lda pause_buf
    beq :+
        swap_state playing
    :
    lda #KEY_START
    bit new_keys
    beq :+
        lda #1
        sta pause_buf
    :
    rts
.endproc

.export state_paused_logic := logic-1
.export state_paused_bg := bg-1
.export state_paused_load := load
.export state_paused_transition := transition-1