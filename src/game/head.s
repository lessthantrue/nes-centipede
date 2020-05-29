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

.proc head_collide_segments
    lda segment_dirs, y
    and #DIR_RIGHT
    bne right_collision
        ; check for left collision
        ldx #CENTIPEDE_LEN
        :
            dex
            lda segment_ys, y
            cmp segment_ys, x
            bne :+ ; skip if not on same y level
            lda segment_xs, y
            sub {segment_xs, x}
            cmp #8
            beq lr_collision
            cmp #9
            beq lr_collision
            cmp #7
            beq lr_collision
            :
            cpx #0
            beq no_collision
            jmp :--
    right_collision:
        ; check for right collision
        ldx #CENTIPEDE_LEN
        :
            dex
            lda segment_ys, y
            cmp segment_ys, x
            bne :+ ; skip if not on same y level
            lda segment_xs, x
            sub {segment_xs, y}
            cmp #8
            beq lr_collision
            cmp #9
            beq lr_collision
            cmp #7
            beq lr_collision
            :
            cpx #0
            beq no_collision
            jmp :--
    
    lr_collision:
        lda segment_flags, y
        ora #SEGMENT_FLAG_COLLIDE
        sta segment_flags, y
    no_collision:
    rts
.endproc

.proc head_turn
    ; first, special logic for the vertical turnaround
    lda segment_dirs, y
    and #DIR_DOWN|DIR_UP
    beq :+
        lda segment_dirs, y
        and #<~(DIR_DOWN|DIR_UP) ; switch down/up bit off
        sta segment_dirs, y
    :

    lda segment_flags, y
    and #SEGMENT_FLAG_COLLIDE ; collision flag set
    beq no_collide
        ; check for turn back upwards
        lda segment_flags, y
        and #SEGMENT_FLAG_UP
        bne :+
        lda segment_ys, y
        cmp #200
        bls :+
            lda segment_flags, y
            ora #SEGMENT_FLAG_UP
            and #<~(SEGMENT_FLAG_POISON)
            sta segment_flags, y
        :

        ; check for turn back downwards
        lda segment_flags, y
        and #SEGMENT_FLAG_UP
        beq :+
        lda segment_ys, y
        cmp #176
        bge :+
            lda segment_flags, y
            and #<~(SEGMENT_FLAG_UP|SEGMENT_FLAG_POISON)
            sta segment_flags, y
        :

        ; set appropriate up/down direction
        lda segment_flags
        and #SEGMENT_FLAG_UP
        bne :+
            lda segment_dirs, y
            ora #DIR_DOWN
            jmp :++
        :
            lda segment_dirs, y
            ora #DIR_UP
        :        
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
    jsr segment_move
    rts
.endproc

.proc head_step_tile
    jsr head_collide_walls
    jsr head_collide_board
    jsr head_turn
    jsr head_collide_segments
    rts
.endproc

.proc head_step
    jsr head_move
    rts
.endproc