
.include "core/eventprocessor.inc"
.include "board.inc"
.include "arrow.inc"
.include "segment.inc"
.include "spritegfx.inc"
.include "global.inc"
.include "centipede.inc"
.include "collision.inc"
.include "statusbar.inc"

SEGMENT_SIZE = 8

DIR_RIGHT =     %00000001
DIR_LEFT =      %00000010
DIR_DOWN =      %00000100

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
    ; keep last 2 bits of segment counter for animation offset
    txa
    and #SEGMENT_MASK_ANIM_OFFSET
    ora segment_flags, x
    sta segment_flags, x
    inc centipede_segments
    rts
.endproc

.proc segment_collide_board
    lda segment_xs, y
    and #$07
    beq :+
        rts
    :
    lda segment_ys, y
    and #$07
    beq :+
        rts
    : ; else
        ; first, check if we need to init another centipede segment
        lda #SEGMENT_FLAG_INIT
        and segment_flags, y
        bne :+ ; bit is set
        lda segment_xs, y
        cmp #CENTIPEDE_INIT_X + 8
        bne :+ ; correct X position
        lda segment_ys, y
        cmp #CENTIPEDE_INIT_Y
        bne :+ ; correct Y position
        ; set init bit
        lda segment_flags, y
        ora #SEGMENT_FLAG_INIT
        sta segment_flags, y
        jsr segment_init
        :
        ; on a grid position, do collision checks
        lda segment_dirs, y
        and #$0F
        cmp #DIR_DOWN
        bne not_down ; need special logic when moving down that doesn't involve collisions
            lda #%00000111
            and segment_ys, y
            bne done_collision ; only check on pixel multiples of 8
            ; set direction to inverted last direction (stored in high nibble)
            lda segment_dirs, y
            lsr
            lsr
            lsr
            lsr
            not
            and #%00000011
            sta segment_dirs, y
        not_down:
        ldx segment_xs, y
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
            lda segment_ys, y
            pha
            lda segment_xs, y
            pha
            call_with_args_manual board_convert_sprite_xy, 2
            lda segment_dirs, y
            cmp #DIR_RIGHT
            beq :+
                dec board_arg_x
                dec board_arg_x ; check one space to the left
            :
            inc board_arg_x ; check one space to the right
            jsr board_xy_to_addr
            jsr board_get_value
            beq done_collision ; no mushroom -> no collision
        lr_collision:
            ; save last direction, set new direction to down
            lda segment_dirs, y
            asl
            asl
            asl
            asl
            ora #DIR_DOWN
            sta segment_dirs, y
    done_collision:
    rts
.endproc

.proc segment_move
    lda segment_dirs, y
    and #$0F
    cmp #DIR_DOWN
    beq move_down
        cmp #DIR_LEFT
        php ; cUz LdA cHaNgEs SoMe PrOcEsSoR fLaGs
        lda segment_xs, y
        plp
        beq :+
        ; move right
            add #SPEED
            add #SPEED
        :
            ; move left
            sub #SPEED
        sta segment_xs, y
        jmp done_moving
    move_down:
        lda segment_ys, y
        add #SPEED
        sta segment_ys, y
    done_moving:
    rts
.endproc

.proc segment_collide_arrow
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    bne :+
        jmp no_collision ; no arrow -> no collision
    :
    lda #SEGMENT_FLAG_ALIVE
    and segment_flags, y
    bne :+
        jmp no_collision
    :
    lda segment_xs, y
    sta collision_box1_l
    add #SEGMENT_SIZE
    sta collision_box1_r
    lda segment_ys, y
    sta collision_box1_t
    add #SEGMENT_SIZE
    sta collision_box1_b
    call_with_args collision_box1_contains, arrow_x, arrow_y
    lda collision_ret
    beq no_collision
        ; kill segment
        lda #SEGMENT_FLAG_ALIVE
        not
        and segment_flags, y
        sta segment_flags, y
        jsr arrow_del
        ; place mushroom where segment was
        lda segment_ys, y
        pha
        lda segment_xs, y
        pha
        call_with_args_manual board_convert_sprite_xy, 2
        jsr board_xy_to_addr
        jsr board_xy_to_nametable
        call_with_args board_set_value, #$04
        ; set next segment's head flag true
        iny
        lda segment_flags, y
        ora #SEGMENT_FLAG_HEAD
        sta segment_flags, y
        dey
        ; add score to game state
        lda #SEGMENT_FLAG_HEAD
        and segment_flags, y
        beq :+
            statusbar_add_score HEAD_SCORE ; head is worth more points
            jmp :++
        :
            statusbar_add_score SEGMENT_SCORE
        :
    no_collision:
    rts
.endproc

.proc segment_draw
    ; arg 4: sprite x
    lda segment_xs, y
    pha

    ; arg 3: sprite flags
    lda segment_dirs, y
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
    lda segment_dirs, y
    and #$0F
    cmp #DIR_DOWN
    beq :+
        lda #$10
        jmp :++
    :
        lda #$20
    :
    tax
    lda #SEGMENT_FLAG_HEAD
    and segment_flags, y
    beq :+
        inx
    :
    lda segment_flags, y
    and #SEGMENT_MASK_ANIM_OFFSET
    clc
    adc segment_xs, y
    and #%00001000
    beq :+
        ; add 2 for animation state 2
        inx
        inx
    :
    txa
    pha

    ; arg 1: sprite y
    lda #SEGMENT_FLAG_ALIVE
    and segment_flags, y
    bne :+
        ; don't draw
        lda #OFFSCREEN
        jmp :++
    :
        lda segment_ys, y
    :
    pha

    call_with_args_manual spritegfx_load_oam, 4
    rts
.endproc

.proc segment_collide_player
    lda segment_xs, y
    sta collision_box1_l
    add #SEGMENT_SIZE
    sta collision_box1_r
    lda segment_ys, y
    sta collision_box1_t
    add #SEGMENT_SIZE
    sta collision_box1_b    
    jsr collision_box_overlap
    lda collision_ret
    beq :+ ; ret = 0 -> no collision
        ; collision found, do stuff
        jsr statusbar_dec_lives
    :
    rts
.endproc

.proc segment_step
    ; skip everything if it isn't alive
    lda #SEGMENT_FLAG_ALIVE
    and segment_flags, y
    bne :+
        rts
    :

    jsr segment_collide_board
    jsr segment_move
    jsr segment_collide_arrow
    jsr segment_collide_player
    rts
.endproc
