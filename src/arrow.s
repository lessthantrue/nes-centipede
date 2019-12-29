
.include "arrow.inc"
.include "player.inc"
.include "board.inc"
.include "spritegfx.inc"
.include "gamestate.inc"

.segment "BSS"
; Game variables
arrow_x:    .res 1
arrow_y:    .res 1
arrow_f:    .res 1

SPEED = 5 ; velocity in px/frame (everything will work as long as this is less than 8)

.segment "CODE"

.proc arrow_init
    lda #0
    sta arrow_f
    rts
.endproc

.proc arrow_launch
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    bne :+
        ; arrow not active
        lda player_yhi
        sta arrow_y
        lda player_xhi
        adc #2
        sta arrow_x
        lda arrow_f
        ora #ARROW_FLAG_ACTIVE
        sta arrow_f
    :
    rts
.endproc

.proc arrow_step
    jsr arrow_move
    jsr arrow_collide
    rts
.endproc

.proc arrow_del
    lda #ARROW_FLAG_ACTIVE
    not
    and arrow_f
    sta arrow_f
    rts
.endproc

.proc arrow_move
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    beq :+
        ; arrow active
        lda arrow_y
        clc
        sbc #SPEED
        sta arrow_y
        bcs :+
            jsr arrow_del
    :
    rts
.endproc

.proc arrow_collide
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    beq done_collision
        call_with_args board_convert_sprite_xy, arrow_x, arrow_y
        jsr board_xy_to_addr
        jsr board_get_value
        cmp #0
        beq done_collision ; no mushroom -> no collision
        ; collision -> "destroy" arrow, "reduce" mushroom
        sub #1
        pha
        bne :+ ; increment score if the mushroom was completely destroyed
            php
            gamestate_add_score MUSHROOM_SCORE
            plp
        :
        call_with_args board_set_value
        pla

        jsr board_xy_to_nametable
        jsr board_request_update_background
        jsr arrow_del
    done_collision:
    rts
.endproc

.proc arrow_draw
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    bne :+
        ; arrow inactive
        call_with_args spritegfx_load_oam, #OFFSCREEN, #$30, #0, #0
        jmp :++
    :
        ; arrow active
        call_with_args spritegfx_load_oam, arrow_y, #$30, #0, arrow_x
    :
    rts
.endproc
