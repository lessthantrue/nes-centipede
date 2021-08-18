.include "../nes.inc"
.include "../pads.inc"
.include "player.inc"
.include "../events/events.inc"
.include "../spritegfx.inc"
.include "board.inc"
.include "../collision.inc"
.include "game.inc"
.include "../events/events.inc"

.segment "BSS"
; Game variables
player_xlo:             .res 1    ; horizontal position is xhi + xlo/256 px
player_xhi:             .res 1
player_ylo:             .res 1
player_yhi:             .res 1

player_speed_lo:        .res 1
player_speed_hi:        .res 1

player_vel_xlo:         .res 1
player_vel_xhi:         .res 1
player_vel_ylo:         .res 1
player_vel_yhi:         .res 1

; speed in total is 1.5 px/frame
SPEED_LO = 128 ; speed in 1/256 px/frame
SPEED_HI = 1     ; speed in px/frame

SPEED_LO_FAST = 0
SPEED_HI_FAST = 3

TOP_WALL = 168 ; top player limit in px, header-adjusted (lower bound)

.segment "CODE"

.proc player_init
    lda #0
    sta player_xlo
    sta player_ylo
    sta player_speed_lo
    sta player_speed_hi
    lda #128
    sta player_xhi
    lda #192
    sta player_yhi
    set game_enemy_statuses, #FLAG_PLAYER

    ; if there is a mushroom where the player is, remove it
    call_with_args board_convert_sprite_xy, player_xhi, player_yhi
    jsr board_xy_to_addr
    call_with_args board_set_value, #0

    rts
.endproc

.proc player_step
    jsr player_control
    jsr player_move
    jsr player_collide_board
    jsr player_collide_wall
    rts
.endproc

; read controller 1 and set some state variables
.proc player_control    
    ; get current speed and save it
    lda cur_keys
    and #KEY_B
    beq not_fast
        lda #SPEED_HI_FAST
        sta player_speed_hi
        lda #SPEED_LO_FAST
        sta player_speed_lo
        jmp end_speed
    not_fast:
        lda #SPEED_LO
        sta player_speed_lo
        lda #SPEED_HI
        sta player_speed_hi
    end_speed:

    lda #0
    sta player_vel_xlo
    sta player_vel_xhi
    sta player_vel_ylo
    sta player_vel_yhi

    lda cur_keys
    and #KEY_RIGHT
    beq not_right
        lda player_speed_hi
        sta player_vel_xhi
        lda player_speed_lo
        sta player_vel_xlo
    not_right:

    lda cur_keys
    and #KEY_LEFT
    beq not_left
        lda player_speed_lo ; twos complement for negative
        not
        add #1
        sta player_vel_xlo
        lda player_speed_hi
        not 
        adc #0              
        sta player_vel_xhi
    not_left:

    lda cur_keys
    and #KEY_UP
    beq not_up
        lda player_speed_lo
        not
        add #1
        sta player_vel_ylo
        lda player_speed_hi
        not
        adc #0
        sta player_vel_yhi
    not_up:

    lda cur_keys
    and #KEY_DOWN
    beq not_down
        lda player_speed_hi
        sta player_vel_yhi
        lda player_speed_lo
        sta player_vel_ylo
    not_down:

    lda cur_keys
    and #KEY_A
    beq notA
        jsr arrow_launch
    notA:

    rts
.endproc

.proc player_move
    adw player_xlo, player_vel_xlo
    adw player_ylo, player_vel_ylo
    rts
.endproc

.proc player_draw
    lda #FLAG_PLAYER
    bit game_enemy_statuses
    beq :+
        ; player alive
        call_with_args spritegfx_load_oam, player_yhi, #$21, #0, player_xhi
        jmp :++
    :
        ; player dead
        call_with_args spritegfx_load_oam, #OFFSCREEN, #0, #0, #0
    :
    rts
.endproc

; A = 1 if center of player is in a tile with a mushroom
.proc player_in_mushroom
    lda player_yhi
    add #3
    pha

    lda player_xhi
    add #3
    pha

    call_with_args_manual board_convert_sprite_xy, 2

    jsr board_xy_to_addr
    jsr board_get_value
    cmp #0
    beq not_inside
        lda #1
        rts
    not_inside:
    lda #0
    rts
.endproc

.proc player_collide_wall
    lda player_xhi
    cmp #(256-16)
    bge right 
    cmp #16
    bls left
    jmp end_lr
    right:
        ; right wall collision
        lda #(256-16)
        sta player_xhi
        jmp end_lr
    left:
        ; left wall collision
        lda #16
        sta player_xhi
    end_lr:

    lda player_yhi
    cmp #TOP_WALL
    bls top
    cmp #(240-40)
    bge bot
    jmp end_ud
    top:
        lda #TOP_WALL
        sta player_yhi
        jmp end_ud
    bot:
        lda #(240-40)
        sta player_yhi
    end_ud:
    
    rts
.endproc

; if the player moved to a mushroom, invert movement that was made
; this frame in each direction until out of the mushroom tile
.proc player_collide_board
    jsr player_in_mushroom
    cmp #0
    beq done_collision
        ; try undoing X
        sbw player_xlo, player_vel_xlo

        jsr player_in_mushroom
        cmp #0
        beq done_collision ; check if out of mushroom

        ; undoing X didn't change anything, so put it back
        adw player_xlo, player_vel_xlo

        ; try undoing Y
        sbw player_ylo, player_vel_ylo

        jsr player_in_mushroom
        cmp #0
        beq done_collision ; check if out of mushroom AGAIN

        ; only possible solution now is to undo both X and Y movement
        sbw player_xlo, player_vel_xlo
        ; Y already undone from earlier

    done_collision:
    rts
.endproc

.proc player_setup_collision
    lda player_xhi
    sta collision_box2_l
    add #8 
    sta collision_box2_r
    lda player_yhi
    sta collision_box2_t
    add #8
    sta collision_box2_b
    rts
.endproc
