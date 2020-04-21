.include "spider.inc"
.include "../spritegfx.inc"
.include "../core/macros.inc"
.include "../random.inc"
.include "player.inc"
.include "arrow.inc"
.include "board.inc"
.include "statusbar.inc"
.include "particles.inc"
.include "scoreparticle.inc"
.include "game.inc"
.include "../collision.inc"
.include "../events/events.inc"
.include "../nes.inc"

; Spider : These appear from the top left or right of the player 
; area. They will either bounce across the player's area at 
; 45-degree angles or bounce in at a 45-degree angle, bounce up 
; and down a couple of times, go to the middle at a 45-degree angle,
; bounce up and down a couple of times, then finally go to the 
; right side (at a 45-degree angle), bounce up and down, then exit
;  the area. They destroy mushrooms they cross over.

.segment "BSS"
spider_x:           .res 1
spider_y:           .res 1
spider_f:           .res 1 ; flags as defined below
spider_anim:        .res 1 ; animation state (tile index)
spider_anim_low:    .res 1

spider_respawn_timer:    .res 2

SPIDER_INIT_X_LEFT = 8
SPIDER_INIT_X_RIGHT = 239
SPIDER_INIT_Y = 100

SPIDER_BOUNDS_TOP = SPIDER_INIT_Y
SPIDER_BOUNDS_BOT = 200

SPIDER_SPEED = 1

.segment "CODE"

.proc spider_init
    lda #0
    sta spider_f
    jsr spider_set_respawn_time

    ; set spider not alive at game level
    clear game_enemy_statuses, #FLAG_ENEMY_SPIDER

    rts
.endproc

; aka spider spawn
.proc spider_reset
    jsr rand8
    and #SPIDER_FLAG_LEFT ; this bit is randomly set
    ora #SPIDER_FLAG_ALIVE|SPIDER_FLAG_HORIZ ; spider alive and moving horizontally
    sta spider_f
    and #SPIDER_FLAG_LEFT
    beq start_right
        ; starting left
        lda #SPIDER_INIT_X_LEFT
        jmp done_init_lr
    start_right:
        lda #SPIDER_INIT_X_RIGHT
    done_init_lr:

    ; other static initialization stuff
    sta spider_x
    lda #SPIDER_INIT_Y
    sta spider_y
    lda #$30
    sta spider_anim

    ; set spider alive bit at game level
    set game_enemy_statuses, #FLAG_ENEMY_SPIDER

    ; reset respawn time
    jsr spider_set_respawn_time
    rts
.endproc

.proc spider_set_respawn_time
    jsr rand8
    and #$03
    sta spider_respawn_timer+1
    jsr rand8
    ora #%10000000
    sta spider_respawn_timer
    rts
.endproc

.proc spider_move
    ; vertical
    lda #SPIDER_FLAG_VERT
    bit spider_f
    bne :+
        ; spider moving down
        lda spider_y
        add #SPIDER_SPEED
        jmp done_move_vert
    :
        ; spider moving up
        lda spider_y
        sub #SPIDER_SPEED
    done_move_vert:
    sta spider_y

    ; horizontal
    lda #SPIDER_FLAG_HORIZ|SPIDER_FLAG_LEFT
    and spider_f
    cmp #SPIDER_FLAG_HORIZ|SPIDER_FLAG_LEFT
    bne :+
        ; spider started left and is moving right
        lda spider_x
        add #SPIDER_SPEED
        sta spider_x
        jmp done_move_horiz
    :
    lda #SPIDER_FLAG_HORIZ
    and spider_f
    beq :+
        ; spider started right and is moving left
        lda spider_x
        sub #SPIDER_SPEED
        sta spider_x
    done_move_horiz:
    rts
.endproc

.proc spider_collide_walls
    lda #SPIDER_FLAG_HORIZ
    bit spider_f
    beq done
        ; spider is moving horizontally
        lda #SPIDER_FLAG_LEFT
        bit spider_f
        beq right
            ; spider started left and is moving right
            lda spider_x
            cmp #SPIDER_INIT_X_RIGHT
            bcc :+
                jsr spider_init
            :
            jmp done
        right:
            ; spider started right and is moving left
            lda spider_x
            cmp #SPIDER_INIT_X_LEFT
            bcs :+
                jsr spider_init
            :
    done:

    lda spider_y
    cmp #SPIDER_BOUNDS_TOP
    bcs :+
        ; top collision. Spider needs to start moving down, so clear the vert bit
        lda spider_f
        and #(255-SPIDER_FLAG_VERT)
        sta spider_f
        jmp collision_occur
    :

    lda spider_y
    cmp #SPIDER_BOUNDS_BOT
    bcc :+
        ; bottom collision. Spider needs to start moving up, so set the vert bit
        lda spider_f
        ora #SPIDER_FLAG_VERT
        sta spider_f
        jmp collision_occur
    :

    rts ; don't continue if no collision occured

    collision_occur:
        ; randomly set spider horizontal flag
        lda spider_f
        and #(255-SPIDER_FLAG_HORIZ)
        sta spider_f ; clear spider bit
        jsr rand8
        and #SPIDER_FLAG_HORIZ
        ora spider_f
        sta spider_f ; set horiz bit only if that bit is set in the random number

    rts
.endproc

.proc spider_collide_random
    jsr rand8
    and #%10111010
    bne NO_CHANGE
        ; randomly assign horizontal bit
        jsr rand8
        and #1
        beq :+
            ; flip horizontal bit
            lda spider_f
            eor #SPIDER_FLAG_HORIZ
            sta spider_f
        :
        ; randomly assign vertical bit
        jsr rand8
        and #1
        beq :+
            lda spider_f
            eor #SPIDER_FLAG_VERT
            sta spider_f
        :
    NO_CHANGE:
    rts
.endproc

.proc spider_collide_board
    ; center hit 'box'
    call_with_args board_convert_sprite_xy, spider_x, spider_y
    jsr board_xy_to_addr
    jsr board_get_value
    cmp #0
    beq :+
        lda #0
        jsr board_xy_to_nametable
        call_with_args board_set_value, #0
    :

    ; left
    dec board_arg_x
    jsr board_xy_to_addr
    jsr board_get_value
    cmp #0
    beq :+
        lda #0
        jsr board_xy_to_nametable
        call_with_args board_set_value, #0
    :

    ; right
    inc board_arg_x
    inc board_arg_x
    jsr board_xy_to_addr
    jsr board_get_value
    cmp #0
    beq :+
        lda #0
        jsr board_xy_to_nametable
        call_with_args board_set_value, #0
    :
    rts
.endproc

.proc spider_draw
    lda #SPIDER_FLAG_ALIVE
    bit spider_f
    bne :+
        ; spider dead
        call_with_args spritegfx_load_oam, #OFFSCREEN, #$20, #0, #0
        call_with_args spritegfx_load_oam, #OFFSCREEN, #$20, #0, #0
        jsr score_particle_draw
        rts
    :
    lda spider_x
    sub #8
    sta spider_x
    call_with_args spritegfx_load_oam, spider_y, spider_anim, #0, spider_x
    lda spider_x
    add #8
    sta spider_x
    inc spider_anim
    call_with_args spritegfx_load_oam, spider_y, spider_anim, #0, spider_x
    dec spider_anim

    rts
.endproc

.proc spider_collide_player
    lda spider_x
    cmp #8
    bcc :+
    sub #8
    sta collision_box1_l
    add #16
    sta collision_box1_r
    lda spider_y
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

.proc spider_collide_arrow
    ; called immediately after collide player, so don't
    ; have to set up collision box again
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    bne :+
        jmp END_COLLISION
    :
    call_with_args collision_box1_contains, arrow_x, arrow_y
    lda collision_ret
    bne :+ 
        jmp END_COLLISION
    :
        ; arrow hit, determine player distance to spider
        lda player_yhi
        sub spider_y
        ; 0-24 px: near score
        cmp #24
        bcs :+
            statusbar_add_score SPIDER_NEAR_SCORE
            lda #$64
            jmp END_SCORE
        :
        ; 24-40 px: mid score
        cmp #40
        bcs :+
            statusbar_add_score SPIDER_MID_SCORE
            lda #$62
            jmp END_SCORE
        :
        ; 40+ px: far score
        statusbar_add_score SPIDER_FAR_SCORE
        lda #$60
        END_SCORE:
        ; arg 3: score
        pha

        ; arg 2: spider y
        lda spider_y
        pha

        ; arg 3: spider x
        lda spider_x
        pha

        call_with_args_manual score_particle_add, 3
        jsr arrow_del
        jsr spider_init
        call_with_args particle_add, spider_x, spider_y

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

.proc spider_step
    lda #SPIDER_FLAG_ALIVE
    bit spider_f
    bne :++
        ; spider not alive
        lda spider_respawn_timer
        sub #1
        sta spider_respawn_timer
        lda spider_respawn_timer+1
        sbc #0
        sta spider_respawn_timer+1

        lda spider_respawn_timer
        bne :+
        lda spider_respawn_timer+1
        bne :+
            jsr spider_reset
        :
        rts
    :

    ; animation state
    lda spider_anim_low
    add #64
    sta spider_anim_low
    lda spider_anim
    bcc :+ ; carry set? increment animation state 2
        adc #1
    :
    cmp #$40
    bne :+
        lda #$30
    :
    sta spider_anim

    jsr spider_collide_player
    jsr spider_collide_arrow
    jsr spider_collide_walls
    jsr spider_collide_random

    lda #SPIDER_FLAG_ALIVE
    bit spider_f
    bne :+
        rts
    :

    jsr spider_move
    jsr spider_collide_board
    rts
.endproc