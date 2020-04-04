.include "flea.inc"
.include "board.inc"
.include "game.inc"
.include "../random.inc"
.include "../events/events.inc"
.include "../collision.inc"
.include "../nes.inc"
.include "../spritegfx.inc"

.segment "BSS"

flea_x:     .res 1
flea_y:     .res 1

flea_hp:   .res 1
flea_anim: .res 1
flea_timer:.res 2

FLEA_SPEED_SLOW = 2
FLEA_SPEED_HIGH = 4

BOUNDS_BOT = 200

.segment "CODE"

.proc flea_init
    lda #0
    sta flea_x
    sta flea_anim
    sta flea_hp
    sta flea_y

    jsr flea_set_respawn_time

    clear game_enemy_statuses, #FLAG_ENEMY_FLEA

    rts
.endproc

; same thing as everything else
.proc flea_set_respawn_time
    ; jsr rand8
    ; and #$01 ; 0 to 5 seconds
    lda #1
    sta flea_timer+1
    jsr rand8
    sta flea_timer
    rts
.endproc

.proc flea_reset
    jsr rand8
    and #%11111000 ; aligned to 8
    cmp #16
    bge :+
        ; too close to left edge
        add #16
    :
    cmp #(256-16)
    bls :+
        ; too close to right edge
        sub #16
    :
    sta flea_x
    lda #0
    sta flea_y
    lda #2
    sta flea_hp

    set game_enemy_statuses, #FLAG_ENEMY_FLEA

    jsr flea_set_respawn_time
    rts
.endproc

.proc flea_collide_walls
    lda flea_y
    cmp #BOUNDS_BOT
    bls end
        ; remove flea
        clear game_enemy_statuses, #FLAG_ENEMY_FLEA
    end:
    rts
.endproc

.proc flea_move
    lda flea_hp
    cmp #2
    bne :+
        ; flea not hit yet
        lda flea_y
        add #FLEA_SPEED_SLOW
        sta flea_y
        jmp :++
    :
    cmp #1
    bne :+
        lda flea_y
        add #FLEA_SPEED_HIGH
        sta flea_y
    :

    rts
.endproc

.proc flea_collide_arrow
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    bne :+
        jmp END_COLLISION
    :
    
    lda flea_x
    sta collision_box1_l
    add #8
    sta collision_box1_r

    lda flea_y
    sta collision_box1_t
    add #8
    sta collision_box1_b

    call_with_args collision_box1_contains, arrow_x, arrow_y
    lda collision_ret
    beq END_COLLISION
        ; arrow hit
        jsr arrow_del
        dec flea_hp
        bne END_COLLISION ; 2 HP
        statusbar_add_score FLEA_SCORE
        call_with_args particle_add, flea_x, flea_y
        jsr flea_init

        ; sound
        lda #%00000100
        sta APU_NSE_ENV
        lda #$0D
        sta APU_NSE_PRD
        lda #%10010000
        sta APU_NSE_LEN
    END_COLLISION:
    rts
.endproc

.proc flea_collide_player
    lda flea_x
    sta collision_box1_l
    add #8
    sta collision_box1_r
    lda flea_y
    sta collision_box1_t
    add #8
    sta collision_box1_b
    jsr player_setup_collision
    jsr collision_box_overlap
    cmp #1
    bne :+
        notify player_dead
    :
    rts
.endproc

.proc flea_draw
    lda #FLAG_ENEMY_FLEA
    bit game_enemy_statuses
    bne :+
        call_with_args spritegfx_load_oam, #OFFSCREEN, #$20, #0, #0
        rts
    :
    
    ; arg 4: sprite x
    lda flea_x
    pha

    ; arg 3: sprite flags
    lda #0
    pha

    ; arg 2: sprite tile index
    lda flea_anim
    and #%00001100
    lsr
    lsr
    add #$80
    pha

    ; arg 1: sprite y
    lda flea_y
    pha

    call_with_args_manual spritegfx_load_oam, 4 

    rts
.endproc

.proc flea_place_shroom
    ; 50% chance of place for every board space at normal speed
    ; normal speed: 2 px per frame
    ; 4 frames spent in each possible mushroom space
    ; 7/8^4 = 0.58 ~= 0.5, therefore 1/8 to place is close enough
    jsr rand8
    and #%00000111
    bne no_place

    call_with_args board_convert_sprite_xy, flea_x, flea_y
    jsr board_xy_to_addr
    jsr board_xy_to_nametable
    call_with_args board_set_value, #4

    no_place:
    rts
.endproc

.proc flea_step
    lda #FLAG_ENEMY_FLEA
    bit game_enemy_statuses
    bne :++
        ; flea not alive
        lda flea_timer
        sub #1
        sta flea_timer
        lda flea_timer+1
        sbc #0
        sta flea_timer+1
        bne :+
            jsr flea_reset
        :
        rts
    :

    inc flea_anim

    jsr flea_collide_arrow
    jsr flea_collide_player
    jsr flea_move
    jsr flea_place_shroom
    jsr flea_collide_walls

    rts
.endproc