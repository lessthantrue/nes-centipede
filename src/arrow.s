.include "macros.inc"
.include "constants.inc"
.include "arrow.inc"
.include "player.inc"
.include "board.inc"

.segment "BSS"
; Game variables
arrow_x:    .res 1
arrow_y:    .res 1
arrow_f:    .res 1 ; flags: active, ???

MASK_ACTIVE = %10000000

SPEED = 5 ; velocity in px/frame (everything will work as long as this is less than 8)

.segment "CODE"

.proc arrow_init
    lda #MASK_ACTIVE
    sta arrow_f
    rts
.endproc

.proc arrow_launch
    lda #MASK_ACTIVE
    bit arrow_f
    bne :+
        ; arrow not active
        lda player_yhi
        sta arrow_y
        lda player_xhi
        sta arrow_x
        lda arrow_f
        ora #MASK_ACTIVE
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
    lda #MASK_ACTIVE
    not
    and arrow_f
    sta arrow_f
    rts
.endproc

.proc arrow_move
    lda #MASK_ACTIVE
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
    lda #MASK_ACTIVE
    bit arrow_f
    beq done_collision
    lda arrow_y
    and #$07
    ; bne done_collision
        lda arrow_x
        lsr a
        lsr a
        lsr a ; divide x by 8
        tax
        lda arrow_y
        lsr a
        lsr a
        lsr a ; divide y by 8
        tay
        jsr board_xy_to_addr
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
    lda #MASK_ACTIVE
    bit arrow_f
    bne :+
        ; arrow inactive
        lda #$F0
        sta $0208
        sta $0209
        sta $020A
        sta $020B
        rts
    :
    ; arrow active
    lda arrow_y
    add #SPRITE_VERT_OFFSET
    sta $0208
    lda #$04
    sta $0209
    lda #0
    sta $020A
    lda arrow_x
    sta $020B
    rts
.endproc

.proc arrow_load_collision
    ldx arrow_x
    ldy arrow_y
    rts
.endproc