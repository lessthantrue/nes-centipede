.include "gamestates.inc"
.include "../pads.inc"
.include "../nes.inc"
.include "../core/macros.inc"
.include "../core/common.inc"
.include "../ppuclear.inc"
.include "../game/game.inc"
.include "../printer.inc"

.segment "BSS"

name:           .res 3
name_cursor:     .res 1

.segment "CODE"

highscore_msg1: pstring "GREAT SCORE"
highscore_msg2: pstring "ENTER YOUR INITIALS"

MSG1_LEN = 13
MSG2_LEN = 21

.proc load
    ; reset input
    lda #'A'
    sta name
    lda #0
    sta name+1
    sta name+2
    sta name_cursor
    rts
.endproc

.proc bg
    ; print high score message
    st_addr (highscore_msg1+1), strptr
    lda highscore_msg1
    sta strlen
    call_with_args print_centered, #12

    st_addr (highscore_msg2+1), strptr
    lda highscore_msg2
    sta strlen
    call_with_args print_centered, #13

    ; print characters input
    st_addr (name), strptr
    lda #3
    sta strlen
    call_with_args print_centered, #15

    rts
.endproc

.proc logic
    ; move to next on A press
    lda #KEY_A
    bit new_keys 
    beq NO_A
        lda name_cursor
        add #1
        cmp #3
        bls :+
            ; loop back to start
            lda #0
        :
        sta name_cursor
    NO_A:

    ; if name at cursor is zero, then put 'A' in it
    ldy name_cursor
    lda name, y
    bne :+
        lda #'A'
        sta name, y
    :

    ; on up, increment character up to 'Z', then loop
    lda #KEY_UP
    bit new_keys
    beq NO_UP
        ldy name_cursor
        lda name, y
        cmp #'Z'
        bne :+
            lda #'A'
            sta name, y
            jmp NO_UP
        :
        add #1
        sta name, y
    NO_UP:

    lda #KEY_DOWN
    bit new_keys
    beq NO_DOWN
        ldy name_cursor
        lda name, y
        cmp #'A'
        bne :+
            lda #'Z'
            sta name, y
            jmp NO_UP
        :
        sub #1
        sta name, y
    NO_DOWN:

    rts
.endproc

.proc transition
    ; go to menu on start
    lda #KEY_START
    bit cur_keys
    beq :+
        swap_state menu
    :

    ; also save here but we'll deal with that later
    rts
.endproc

.export state_highscore_logic := logic-1
.export state_highscore_bg := bg-1
.export state_highscore_load := load-1
.export state_highscore_transition := transition-1