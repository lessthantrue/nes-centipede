.include "../core/eventprocessor.inc"
.include "board.inc"
.include "arrow.inc"
.include "segment.inc"
.include "particles.inc"
.include "../spritegfx.inc"
.include "centipede.inc"
.include "../collision.inc"
.include "statusbar.inc"
.include "../events/events.inc"

SEGMENT_SIZE = 8

DIR_RIGHT =     %00000001 ; left = not right
DIR_DOWN =      %00000010

.segment "CODE"

.proc segment_init
    ldx centipede_segments
    cpx #CENTIPEDE_LEN
    bne init_segment
    rts ; already have 8 segments, don't make any more
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
    ; keep last 3 bits of segment counter for animation offset
    txa
    asl
    asl
    asl
    asl
    asl
    and #SEGMENT_MASK_ANIM_OFFSET
    ora segment_flags, x
    sta segment_flags, x
    inc centipede_segments
    rts
.endproc

.proc segment_collide_board
    ; only check collisions on pixel multiples of 8
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
        ; ############################ segment init
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
        ; ############################# collision checks
        lda segment_dirs, y
        and #DIR_DOWN
        beq not_down
            ; need special logic when moving down that doesn't involve collisions
            lda segment_flags, y
            and #SEGMENT_FLAG_POISON
            bne :+ ; skip not going down if the segment is poisoned
                lda segment_dirs, y
                and #%00000001 ; switch down bit off
                sta segment_dirs, y
            :
            ; jmp done_collision
        not_down:
        ldx segment_xs, y
        lda segment_dirs, y
        and #DIR_RIGHT
        bne right_collision
            ; check for left collision
            cpx #16
            bcs mushroom_collision ; no wall collision here
            jmp lr_collision
        right_collision:
            ; check for right collision
            cpx #240
            bcc mushroom_collision ; no wall collision here
            jmp lr_collision
        mushroom_collision:
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
            tax
            and #MUSHROOM_POISON_FLAG ; if it's a poison mushroom,
            beq :+
                lda segment_flags, y ; set the poisoned flag for that segment
                ora #SEGMENT_FLAG_POISON
                sta segment_flags, y
            :
            txa
            beq done_collision ; no mushroom -> no collision
        lr_collision:
            ; set new direction to down + previous direction
            lda segment_dirs, y
            ora #DIR_DOWN
            sta segment_dirs, y
    done_collision:
    rts
.endproc

.proc segment_move
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
        add centipede_speed
        sta segment_ys, y
    :
    lda segment_dirs, y
    and #DIR_RIGHT
    php ; cUz LdA cHaNgEs SoMe PrOcEsSoR fLaGs
    lda segment_xs, y
    plp
    bne :+
    ; move left
        sub centipede_speed
        sub centipede_speed
    :
        ; move right
        add centipede_speed
    sta segment_xs, y
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
    bne :+
        jmp no_collision
    :
        ; kill segment
        lda #SEGMENT_FLAG_ALIVE
        not
        and segment_flags, y
        sta segment_flags, y
        jsr arrow_del
        ; notify people subscribed to the event
        notify segment_kill
        ; place mushroom where segment was plus direction
        lda segment_ys, y
        pha
        lda segment_xs, y
        pha
        call_with_args_manual board_convert_sprite_xy, 2
        lda segment_dirs, y
        and #DIR_RIGHT
        bne :+
            ; was moving left
            dec board_arg_x
            dec board_arg_x
        :
        inc board_arg_x
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
        tya
        pha ; preserve y
        lda #SEGMENT_FLAG_HEAD
        and segment_flags, y
        beq :+
            statusbar_add_score HEAD_SCORE ; head is worth more points
            jmp :++
        :
            statusbar_add_score SEGMENT_SCORE
        :
        pla
        tay ; restore y
        ; add death particle
        lda segment_ys, y
        pha
        lda segment_xs, y
        pha
        call_with_args_manual particle_add, 2
    no_collision:
    rts
.endproc

.proc segment_draw
    ; arg 4: sprite x
    lda segment_xs, y
    pha

    ; arg 3: sprite flags
    lda segment_dirs, y
    and #%00000001
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a ; shift dir bits left 6 times, lines up perfectly with sprite mirroring
    pha

    ; arg 2: sprite tile index
    ; there is a LOT of bit arithmetic about to happen
    lda segment_flags, y
    and #SEGMENT_MASK_ANIM_OFFSET|SEGMENT_FLAG_HEAD
    lsr
    lsr
    lsr
    lsr
    add #$10
    pha
    lda segment_dirs, y
    and #DIR_DOWN
    beq :+
        ; dir down set
        pla
        add #DIR_DOWN
        pha
    :

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
        ; collision found, notify player death subscribers
        notify player_dead
    :
    rts
.endproc

.proc segment_step_animation
    lda segment_xs, y
    and #$7
    cmp #2
    beq :+
    cmp #6
    beq :+
    jmp :++
    :
        ; 2 or 6 above a multiple of 8
        lda segment_flags, y
        add #%00100000
        sta segment_flags, y
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

    jsr segment_step_animation
    jsr segment_collide_board
    jsr segment_move
    jsr segment_collide_arrow
    jsr segment_collide_player
    rts
.endproc
