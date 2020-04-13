.include "game.inc"

.segment "CODE"

.proc head_collide_walls
    ldx segment_xs, y
    lda segment_dirs, y
    and #DIR_RIGHT
    bne right_collision
        ; check for left collision
        cpx #16
        bge no_collision ; no wall collision here
        jmp lr_collision
    right_collision:
        ; check for right collision
        cpx #240
        bls no_collision ; no wall collision here
    
    lr_collision:
        ; set collision flag
        lda segment_flags, y
        ora #SEGMENT_FLAG_COLLIDE
        sta segment_flags, y
    no_collision:
    rts
.endproc

.proc head_turn
    ; first special logic for the moving-down turnaround
    lda segment_dirs, y
    and #DIR_DOWN
    beq :+
        lda segment_dirs, y
        and #($FF-DIR_DOWN) ; switch down bit off
        sta segment_dirs, y
        ; jmp done_turn
    :

    lda segment_flags, y
    and #SEGMENT_FLAG_COLLIDE ; collision flag set
    beq no_collide
        lda segment_dirs, y
        ora #DIR_DOWN
        sta segment_dirs, y
        ; set prev collision flag
        lda segment_flags, y
        ora #SEGMENT_FLAG_COLLIDE_PREV
        sta segment_flags, y
        jmp done_turn
    no_collide:
        ; clear prev collision flag
        lda segment_flags, y
        and #($FF-SEGMENT_FLAG_COLLIDE_PREV)
        sta segment_flags, y
    done_turn:

    ; clear collision flag unless poisoned
    lda segment_flags, y
    and #SEGMENT_FLAG_POISON
    bne :+
        lda segment_flags, y
        and #($FF-SEGMENT_FLAG_COLLIDE)
        sta segment_flags, y
    :

    ; if not head, move collision status of prev segment to this one
    lda segment_flags, y
    and #SEGMENT_FLAG_HEAD
    bne :+
        ; first one is always head, so don't need to check for y=0
        dey
        lda segment_flags, y
        and #SEGMENT_FLAG_COLLIDE_PREV
        lsr a
        iny
        ora segment_flags, y
        sta segment_flags, y

        ; also copy poison flag
        dey
        lda segment_flags, y
        and #SEGMENT_FLAG_POISON
        iny
        ora segment_flags, y
        sta segment_flags, y
    :
    rts
.endproc

.proc head_collide_board
    ; check mushroom collisions
    lda segment_ys, y
    pha
    lda segment_xs, y
    pha
    call_with_args_manual board_convert_sprite_xy, 2
    lda segment_dirs, y
    and #DIR_RIGHT
    bne :+
        dec board_arg_x
        dec board_arg_x ; check one space to the left
    :
    inc board_arg_x ; check one space to the right
    jsr board_xy_to_addr
    jsr board_get_value
    cmp #0
    beq done_collision; no mushroom -> no collision
        tax
        and #MUSHROOM_POISON_FLAG ; if it's a poison mushroom,
        beq :+
            lda segment_flags, y ; set the poisoned flag for that segment
            ora #SEGMENT_FLAG_POISON
            sta segment_flags, y
        :
        txa
        ; set collide flag
        lda segment_flags, y
        ora #SEGMENT_FLAG_COLLIDE
        sta segment_flags, y
    done_collision:
    rts
.endproc

.proc head_move
    ; if speed is 2 but centipede is on an odd tile, only move 1
    lda segment_xs, y
    and #1
    bne :+
    lda segment_ys, y
    and #1
    bne :+
        ; on an even tile
        lda centipede_speed
        sta centipede_speed_temp
        jmp :++
    :
        ; still on an odd tile
        lda #1
        sta centipede_speed_temp
    :

    lda segment_dirs, y
    and #DIR_DOWN
    beq :++
        ; turn back to finish diagonal movement if y value is 4 more than a multiple of 8
        lda segment_ys, y
        and #$07
        cmp #4
        bne :+
            ; change directions
            lda segment_dirs, y
            eor #%00000001 ; swap last bit
            sta segment_dirs, y
        :

        ; finish moving down
        lda segment_ys, y
        add centipede_speed_temp
        sta segment_ys, y
    :
    lda segment_dirs, y
    and #DIR_RIGHT
    php ; because lda changes zero flag
    lda segment_xs, y
    plp
    bne :+
    ; move left
        sub centipede_speed_temp
        sub centipede_speed_temp
    :
        ; move right
        add centipede_speed_temp
    sta segment_xs, y
    rts
.endproc

.proc head_step_tile
    jsr head_collide_walls
    jsr head_collide_board
    jsr head_turn
    rts
.endproc

.proc head_step
    jsr head_move
    rts
.endproc