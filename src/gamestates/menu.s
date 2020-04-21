.include "gamestates.inc"
.include "../pads.inc"
.include "../nes.inc"
.include "../gamestaterunner.inc"
.include "../core/macros.inc"
.include "../core/common.inc"
.include "../ppuclear.inc"
.include "../game/game.inc"
.include "../printer.inc"

.segment "CODE"

menu_begin_msg: pstring "PRESS START TO PLAY"
menu_extralife_msg: pstring "BONUS EVERY 12000"
; MENU_EXTRALIFE_MSG_LEN = 19
; menu_extralife_msg: .byte " BONUS EVERY 12000 "

.proc bg
    st_addr (menu_begin_msg+1), strptr
    lda menu_begin_msg
    sta strlen
    call_with_args print_centered, #13

    ; extra life message
    st_addr (menu_extralife_msg+1), strptr
    lda menu_extralife_msg
    sta strlen
    call_with_args print_centered, #14

    rts
.endproc

.proc transition
    lda #KEY_START
    bit cur_keys
    beq :+
        jsr statusbar_init
        jsr game_full_reset
        swap_state redraw_board
    :
    rts
.endproc

.export state_menu_logic := menu_step-1
.export state_menu_bg := bg-1
.export state_menu_load := empty
.export state_menu_transition := transition-1