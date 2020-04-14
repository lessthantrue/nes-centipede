.include "game.inc"
.include "../spritegfx.inc"
.include "../collision.inc"
.include "../events/events.inc"

SEGMENT_SIZE = 8

.segment "BSS"

centipede_speed_temp: .res 1

.segment "CODE"

.proc segment_init
    lda centipede_speed
    sta centipede_speed_temp ; terrible temp solution

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
    sta segment_anims, x

    ; setting flags is a bit more involved
    lda #SEGMENT_FLAG_ALIVE
    cpx #0
    beq set_head
    jmp end_flags
    set_head:
        ora #SEGMENT_FLAG_HEAD
    end_flags:
    sta segment_flags, x
    inc centipede_segments
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
    lda segment_anims, y
    and #SEGMENT_MASK_ANIM_OFFSET
    ora segment_flags, y
    and #(SEGMENT_MASK_ANIM_OFFSET|SEGMENT_FLAG_HEAD)

    ; lda segment_flags, y
    ; and #SEGMENT_FLAG_HEAD
    ; ora segment_anims, y
    ; and #(SEGMENT_FLAG_HEAD|SEGMENT_MASK_ANIM_OFFSET)
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
    jmp end_anim
    :
        ; 2 or 6 above a multiple of 8
        lda segment_anims, y
        and #%00000001 ; reverse bit
        bne :++
            lda segment_anims, y
            add #%00100000
            cmp #$E0
            bne :+
                ora #%00000001
            :
            jmp :++
        :
            lda segment_anims, y
            sub #%00100000
            cmp #01
            bne :+
                and #($FF-%00000001)
            :

        sta segment_anims, y
    end_anim:
    rts
.endproc

.proc segment_step
    ; skip everything if it isn't alive
    lda #SEGMENT_FLAG_ALIVE
    and segment_flags, y
    bne :+
        rts
    :

    lda segment_flags, y
    and #SEGMENT_FLAG_HEAD
    beq :+
        ; only if head
        jsr head_step
        jmp :++
    :
        ; if not head
        jsr body_step
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
            ; only if head
            jsr head_step_tile
            jmp :++
        :
            ; if body
            jsr body_step_tile
        :
        jsr segment_init_next           ; init next segment if necessary
    not_tile:

    jsr segment_step_animation
    jsr segment_collide_arrow
    jsr segment_collide_player
    rts
.endproc
