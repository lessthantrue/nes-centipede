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
DIR_DOWN  =     %00000010 
DIR_UP    =     %00000100 ; straight = not up or down

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
    lda #0

    ; setting flags is a bit more involved
    lda #SEGMENT_FLAG_ALIVE
    cpx #0
    beq set_head
    cpx #(SEGMENT_SIZE-1)
    beq set_tail
    jmp end_flags
    set_tail:
        ora #SEGMENT_FLAG_TAIL
        jmp end_flags
    set_head:
        ora #SEGMENT_FLAG_HEAD
    end_flags:
    sta segment_flags, x
    ; keep last 3 bits of segment counter for animation offset
    txa
    asl
    asl
    asl
    asl
    asl
    and #SEGMENT_MASK_ANIM_OFFSET
    sta segment_anims, X
    inc centipede_segments
    rts
.endproc

.proc segment_collide_walls
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

; what to do after a collision
.proc segment_turn
    ; first special logic for the moving-down turnaround
    lda segment_dirs, y
    and #DIR_DOWN
    beq :+
    lda segment_flags, y
    and #SEGMENT_FLAG_POISON
    bne :+ ; skip not going down if the segment is poisoned
        lda segment_dirs, y
        and #($FF-DIR_DOWN) ; switch down bit off
        sta segment_dirs, y
        jmp done_turn
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

    ; clear collision flag
    lda segment_flags, y
    and #($FF-SEGMENT_FLAG_COLLIDE)
    sta segment_flags, y

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
    :
    rts
.endproc

.proc segment_init_next
    lda #SEGMENT_FLAG_INIT
    and segment_flags, y
    bne :+ ; init bit is clear
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
        jsr segment_init ; create next segment
    :
    rts
.endproc

.proc segment_collide_board
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
    php ; because lda changes zero flag
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
        cpy #CENTIPEDE_LEN
        beq :+ ; skip if next segment is past last segment
            lda segment_flags, y
            ora #SEGMENT_FLAG_HEAD
            sta segment_flags, y
        :
        dey
        ; set the previous segment's tail flag to true
        dey
        cpy #$FF ; skip if prev segment is before 0th segment
        beq :+
            lda segment_flags, y
            ora #SEGMENT_FLAG_TAIL
            sta segment_flags, y
        :
        iny
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
    and #SEGMENT_FLAG_HEAD
    ora segment_anims, y
    and #(SEGMENT_FLAG_HEAD|SEGMENT_MASK_ANIM_OFFSET)
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
        lda segment_anims, y
        add #%00100000
        sta segment_anims, y
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

    ; only do some things once per tile length (8 pixels)
    lda segment_xs, y
    and #$07
    bne not_tile
    lda segment_ys, y
    and #$07
    bne not_tile
        ; on a tile-aligned spot
        lda segment_flags, y
        and #SEGMENT_FLAG_HEAD
        beq :+
            ; do these if head
            jsr segment_collide_board   ; collide with mushrooms
            jsr segment_collide_walls   ; collide with walls
        :
        jsr segment_turn                ; resolve collisions
        jsr segment_init_next           ; init next segment if necessary
    not_tile:

    jsr segment_step_animation
    jsr segment_move
    jsr segment_collide_arrow
    jsr segment_collide_player
    rts
.endproc
