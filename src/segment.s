.include "core/macros.inc"
.include "core/eventprocessor.inc"
.include "board.inc"
.include "arrow.inc"
.include "segment.inc"
.include "spritegfx.inc"
.include "global.inc"
.include "centipede.inc"
.include "collision.inc"

SEGMENT_WIDTH = 8

DIR_RIGHT =     %00000001
DIR_LEFT =      %00000010
DIR_DOWN =      %00000100

.segment "ZEROPAGE"

segment_active :    .tag segment

.segment "CODE"

.proc segment_init
    ldx centipede_segments
    cpx #CENTIPEDE_LEN
    bne init_segment
    rts
    init_segment:

    lda #CENTIPEDE_INIT_X
    sta segment_xs, x
    lda #CENTIPEDE_INIT_Y
    sta segment_ys, x
    lda #DIR_RIGHT
    sta segment_dirs, x

    ; setting flags is a bit more involved
    lda #SEGMENT_FLAG_ALIVE
    cpx #0
    bne :+
        ora #SEGMENT_FLAG_HEAD
    :
    sta segment_flags, x
    inc centipede_segments
    rts
.endproc

.proc segment_collide_board
    lda segment_active+segment::xcord
    and #$07
    beq :+
        rts
    :
    lda segment_active+segment::ycord
    and #$07
    bne done_collision
        ; first, check if we need to init another centipede segment
        lda #SEGMENT_FLAG_INIT
        bit segment_active+segment::flags
        bne :+ ; bit is set
        lda segment_active+segment::xcord
        cmp #CENTIPEDE_INIT_X + 8
        bne :+ ; correct X position
        lda segment_active+segment::ycord
        cmp #CENTIPEDE_INIT_Y
        bne :+ ; correct Y position
        ; set init bit
        lda segment_active+segment::flags
        ora #SEGMENT_FLAG_INIT
        sta segment_active+segment::flags
        jsr segment_init
        :
        ; on a grid position, do collision checks
        lda segment_active+segment::dir
        and #$0F
        cmp #DIR_DOWN
        bne not_down ; need special logic when moving down that doesn't involve collisions
            lda #%00000111
            bit segment_active+segment::ycord
            bne done_collision ; only check on pixel multiples of 8
            ; set direction to inverted last direction (stored in high nibble)
            lda segment_active+segment::dir
            lsr
            lsr
            lsr
            lsr
            not
            and #%00000011
            sta segment_active+segment::dir
        not_down:
        ldx segment_active+segment::xcord
        cmp #DIR_RIGHT
        beq right_collision
            ; check for left collision
            cpx #8
            bne mushroom_collision ; no wall collision here
            jmp lr_collision
        right_collision:
            ; check for right collision
            cpx #240
            bne mushroom_collision ; no wall collision here
            jmp lr_collision
        mushroom_collision:
            call_with_args board_convert_sprite_xy, segment_active+segment::xcord, segment_active+segment::ycord
            lda segment_active+segment::dir
            cmp #DIR_RIGHT
            beq :+
                dec board_arg_x
                dec board_arg_x ; check one space to the left
            :
            inc board_arg_x ; check one space to the right
            jsr board_xy_to_addr
            jsr board_get_value
            cmp #0
            beq done_collision ; no mushroom -> no collision
        lr_collision:
            ; save last direction, set new direction to down
            lda segment_active+segment::dir
            asl
            asl
            asl
            asl
            ora #DIR_DOWN
            sta segment_active+segment::dir
    done_collision:
    rts
.endproc

.proc segment_move
    lda segment_active+segment::dir
    and #$0F
    cmp #DIR_DOWN
    beq move_down
        cmp #DIR_LEFT
        php
        lda segment_active+segment::xcord
        plp
        beq :+
        ; move right
            add #SPEED
            add #SPEED
        :
            ; move left
            sub #SPEED
        sta segment_active+segment::xcord
        jmp done_moving
    move_down:
        lda segment_active+segment::ycord
        add #SPEED
        sta segment_active+segment::ycord
    done_moving:
    rts
.endproc

.proc segment_collide_arrow
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    beq no_collision ; no arrow -> no collision
    lda #SEGMENT_FLAG_ALIVE
    bit segment_active+segment::flags
    bne :+
        jmp no_collision
    :
    lda segment_active+segment::xcord
    sta collision_box1_l
    add #SEGMENT_WIDTH
    sta collision_box1_r
    lda segment_active+segment::ycord
    sta collision_box1_t
    add #SEGMENT_WIDTH
    sta collision_box1_b
    call_with_args collision_box1_contains, arrow_x, arrow_y
    lda collision_ret
    beq no_collision
        ; kill segment
        lda #SEGMENT_FLAG_ALIVE
        not
        and segment_active+segment::flags
        sta segment_active+segment::flags
        jsr arrow_del
        ; place mushroom where segment was
        call_with_args board_convert_sprite_xy, segment_active+segment::xcord, segment_active+segment::ycord
        jsr board_xy_to_addr
        jsr board_xy_to_nametable
        call_with_args board_set_value, #$04
    no_collision:
    rts
.endproc

.proc segment_draw
    ; arg 4: sprite x
    lda segment_active+segment::xcord
    pha

    ; arg 3: sprite flags
    lda segment_active+segment::dir
    and #%00000010
    asl a
    asl a
    asl a
    asl a
    asl a ; shift dir bits left 5 times, lines up perfectly with sprite mirroring
    pha

    ; arg 2: sprite tile index
    ; anchor sprite index is $10 
    ; add 16 for downwards
    lda segment_active+segment::dir
    and #$0F
    cmp #DIR_DOWN
    beq :+
        lda #$10
        jmp :++
    :
        lda #$20
    :
    tay
    ; add 1 if head, or if next segment is not alive
    lda #SEGMENT_FLAG_HEAD
    bit segment_active+segment::flags
    beq :+
        iny
    :
    lda segment_active+segment::xcord
    lsr
    lsr ; change animation state each 4 x pixels
    and #%00000001
    beq :+
        ; add 2 for animation state 2
        iny
        iny
    :
    tya
    pha

    ; arg 1: sprite y
    lda #SEGMENT_FLAG_ALIVE
    bit segment_active+segment::flags
    bne :+
        ; don't draw
        lda #OFFSCREEN
        jmp :++
    :
        lda segment_active+segment::ycord
    :
    pha

    call_with_args_manual spritegfx_load_oam, 4

    done_draw:
    rts
.endproc

.proc segment_step
    ; skip everything if it isn't alive
    lda #SEGMENT_FLAG_ALIVE
    bit segment_active+segment::flags
    bne :+
        rts
    :

    jsr segment_collide_board
    jsr segment_move
    jsr segment_collide_arrow
    rts
.endproc
