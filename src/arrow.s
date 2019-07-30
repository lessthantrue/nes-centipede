.include "macros.inc"
.include "constants.inc"
.include "arrow.inc"
.include "player.inc"
.include "board.inc"
.include "spritegfx.inc"

.segment "BSS"
; Game variables
arrow_x:    .res 1
arrow_y:    .res 1
arrow_f:    .res 1 ; flags: active, ???

SPEED = 5 ; velocity in px/frame (everything will work as long as this is less than 8)

.segment "CODE"

.proc arrow_init
    lda #ARROW_FLAG_ACTIVE
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
        ldx arrow_x
        ldy arrow_y
        jsr board_convert_sprite_xy
        jsr board_xy_to_addr
        ldx arrow_x
        ldy arrow_y
        jsr board_convert_sprite_xy
        jsr board_xy_to_nametable
        jsr board_get_value
        cmp #0
        beq done_collision ; no mushroom -> no collision
        ; collision -> "destroy" arrow, "reduce" mushroom
        sub #1
        jsr board_set_value
        jsr board_update_background
        jsr arrow_del
    done_collision:
    rts
.endproc

.proc arrow_draw
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    bne :+
        ; arrow inactive
        lda #$F0
        sta spritegfx_oam_arg+oam::ycord
        jmp :++
    :
        ; arrow active
        lda arrow_y
        add #SPRITE_VERT_OFFSET
        sta spritegfx_oam_arg+oam::ycord
    :
    lda #$30
    sta spritegfx_oam_arg+oam::tile
    lda #0
    sta spritegfx_oam_arg+oam::flags
    lda arrow_x
    sta spritegfx_oam_arg+oam::xcord
    jsr spritegfx_load_oam
    rts
.endproc

.proc arrow_load_collision
    ldx arrow_x
    ldy arrow_y
    rts
.endproc