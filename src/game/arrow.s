
.include "arrow.inc"
.include "player.inc"
.include "board.inc"
.include "../spritegfx.inc"
.include "statusbar.inc"
.include "../events/events.inc"
.include "../nes.inc"

.segment "BSS"
; Game variables
arrow_x:    .res 1
arrow_y:    .res 1
arrow_f:    .res 1

oam_offset: .res 1

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
        notify arrow_shoot
        jsr oam_alloc
        sty oam_offset
        
        lda player_yhi
        sta arrow_y
        add #SPRITE_VERT_OFFSET
        sta OAM+oam::ycord, y
        lda player_xhi
        adc #2
        sta arrow_x
        sta OAM+oam::xcord, y
        lda #$20
        sta OAM+oam::tile, y
        lda #0
        sta OAM+oam::flags, y

        lda arrow_f
        ora #ARROW_FLAG_ACTIVE
        sta arrow_f
    :
    ; arrow not active
    rts
.endproc

.proc arrow_step
    jsr arrow_collide
    jsr arrow_move
    rts
.endproc

.proc arrow_del
    lda #ARROW_FLAG_ACTIVE
    not
    and arrow_f
    sta arrow_f
    ldy oam_offset
    jsr oam_free
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
        jsr board_xy_to_nametable
        jsr board_get_value
        cmp #0
        beq done_collision ; no mushroom -> no collision
        ; collision -> "destroy" arrow, "reduce" mushroom
        sub #1
        pha ; manual argument 1: new mushroom growth level
        bne :+ ; increment score if the mushroom was completely destroyed
            php
            statusbar_add_score MUSHROOM_SCORE
            plp
        :
        call_with_args_manual board_set_value, 1

        jsr arrow_del
    done_collision:
    rts
.endproc

.proc arrow_draw
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    beq :+
        ldy oam_offset
        lda arrow_y
        add #SPRITE_VERT_OFFSET
        sta OAM+oam::ycord, y
    :
    rts
.endproc
