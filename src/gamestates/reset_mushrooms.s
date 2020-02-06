.include "gamestates.inc"
.include "../core/macros.inc"
.include "../game/game.inc"
.include "../nes.inc"

.segment "BSS"
reset_mushrooms_done:   .res 1
reset_mushroom_delay:   .res 1
RESET_MUSHROOM_DELAY = 10

.segment "CODE"
WIDTH = 32
HEIGHT = 26

.proc load
    lda #0
    sta board_arg_x
    sta board_arg_y
    sta reset_mushrooms_done
    sta reset_mushroom_delay
    rts
.endproc

.proc logic
    jsr game_draw
    lda reset_mushroom_delay
    bne END_DONE
    lda #RESET_MUSHROOM_DELAY
    sta reset_mushroom_delay

    START:
        ; move to next grid space
        ldx board_arg_x
        cpx #WIDTH
        bne :++
            ldx #0
            ldy board_arg_y
            iny
            cpy #HEIGHT
            bne :+
                ; reached end of board? flag end of state
                lda #1
                sta reset_mushrooms_done
                jmp END_DONE
            :
            stx board_arg_x
            sty board_arg_y
        :

        ; check if it is a damaged mushroom
        jsr board_xy_to_addr
        jsr board_get_value
        cmp #4
        beq :+
        cmp #0
        beq :+
            ; mushroom is borken
            jsr board_xy_to_nametable
            call_with_args board_set_value, #4
            jmp END_FOUND ; end this loop for now
        :
        ; Not a damaged mushroom? continue
        inc board_arg_x
        jmp START
    END_FOUND:
    lda #%00001111
    sta APU_NSE_ENV
    lda #$0E
    sta APU_NSE_PRD
    lda #0
    sta APU_NSE_LEN
    statusbar_add_score 5
    END_DONE:
    dec reset_mushroom_delay
    rts
.endproc

.proc bg
    jsr board_update_background
    jsr statusbar_draw_score
    rts
.endproc

.proc transition
    lda reset_mushrooms_done
    beq :+
        swap_state playing
    :
    rts
.endproc

.export state_reset_mushrooms_logic := logic-1
.export state_reset_mushrooms_bg := bg-1
.export state_reset_mushrooms_transition := transition-1
.export state_reset_mushrooms_load := load