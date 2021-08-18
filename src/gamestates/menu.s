.include "gamestates.inc"
.include "../pads.inc"
.include "../nes.inc"
.include "../gamestaterunner.inc"
.include "../core/macros.inc"
.include "../core/common.inc"
.include "../ppuclear.inc"
.include "../game/game.inc"
.include "../printer.inc"
.include "../highscores.inc"

.segment "CODE"

menu_begin_msg: pstring "PRESS START TO PLAY"
menu_extralife_msg: pstring "BONUS EVERY 12000"
; MENU_EXTRALIFE_MSG_LEN = 19
; menu_extralife_msg: .byte " BONUS EVERY 12000 "

.proc bg
    ; press start message
    st_addr (menu_begin_msg+1), strptr
    lda menu_begin_msg
    sta strlen
    call_with_args print_centered, #13

    ; extra life message
    st_addr (menu_extralife_msg+1), strptr
    lda menu_extralife_msg
    sta strlen
    call_with_args print_centered, #14

    ; make sure pallette is reset
    load_palette palette_set_1

    ; high score
    jsr statusbar_draw_highscore

    rts
.endproc

.proc logic
    jsr menu_step

    ; reset the high scores by holding start + select on controller 2 at the same time
    lda #KEY_START|KEY_SELECT
    and cur_keys+1
    cmp #KEY_START|KEY_SELECT
    bne :+
        jsr highscores_hard_reset
    :
    rts
.endproc

.proc transition
    lda #KEY_START
    bit new_keys
    beq :+
        jsr game_full_reset
        swap_state redraw_board
    :
    rts
.endproc

.export state_menu_logic := logic-1
.export state_menu_bg := bg-1
.export state_menu_load := empty
.export state_menu_transition := transition-1