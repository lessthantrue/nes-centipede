.include "gamestates.inc"
.include "../pads.inc"
.include "../nes.inc"
.include "../core/macros.inc"
.include "../core/common.inc"
.include "../ppuclear.inc"
.include "../game/game.inc"
.include "../printer.inc"
.include "../highscores.inc"
.include "../core/bin2dec.inc"

.segment "BSS"

name:           .res 3
name_cursor:    .res 1
done:           .res 1 ; player is done entering name

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
    sta done
    rts
.endproc

.proc bg
    lda done
    beq :+
        ; redraw board where we put text
        call_with_args board_redraw_count, #(16 - 6), #12, #12
        call_with_args board_redraw_count, #14, #15, #4

        ; menu will draw over this row anyways
        ; call_with_args board_redraw_count, #(16-10), #13, #20
        jmp :++
    :
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
    END_BG: 

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
            jmp NO_DOWN
        :
        sub #1
        sta name, y
    NO_DOWN:

    rts
.endproc

.proc transition
    lda done
    beq :+
        swap_state menu
    :

    ; go to menu on start
    lda #KEY_START
    bit cur_keys
    bne :+
        jmp NO_START
    :
        sta done
        ; save this high score over the current lowest
        ldy highscores_sorted+(SCORES_COUNT-1)

        ; name
        lda name
        sta highscores, y
        lda name+1
        sta highscores+1, y
        lda name+2
        sta highscores+2, y

        ; score
        lda score+2
        sta highscores+3, y
        lda score+1
        sta highscores+4, y
        lda score
        sta highscores+5, y

        ; score in decimal
        lda decimal
        sta highscores+6, y
        lda decimal+1
        sta highscores+7, y
        lda decimal+2
        sta highscores+8, y
        lda decimal+3
        sta highscores+9, y
        lda decimal+4
        sta highscores+10, y
        lda decimal+5
        sta highscores+11, y
        lda decimal+6
        sta highscores+12, y
        lda decimal+7
        sta highscores+13, y

        ; sort the new score in
        jsr highscores_sort

    NO_START:
    rts
.endproc

.export state_highscore_logic := logic-1
.export state_highscore_bg := bg-1
.export state_highscore_load := load
.export state_highscore_transition := transition-1