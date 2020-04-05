.include "../nes.inc"
.include "../pads.inc"
.include "arrow.inc"
.include "player.inc"
.include "../events/events.inc"
.include "../spritegfx.inc"
.include "../collision.inc"
.include "statusbar.inc"
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
    rts
.endproc

; Moves the player character in response to controller 1.
.proc player_move

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

    ; right
    lda cur_keys
    and #KEY_RIGHT
    beq notRight
        ; Right is pressed. Add to position.
        lda player_xlo
        add player_speed_lo
        sta player_xlo
        lda player_xhi
        adc player_speed_hi
        cmp #(256-16)
        bcc :+ ; right wall collision
            lda #(256-16)
        :
        sta player_xhi
    notRight:

    ; left
    lda cur_keys
    and #KEY_LEFT
    beq notLeft
        ; Left is pressed. Subtract from position.
        lda player_xlo
        sub player_speed_lo
        sta player_xlo
        lda player_xhi
        sbc player_speed_hi
        cmp #8
        bcs :+ ; left wall collision
            lda #8
        :
        sta player_xhi
    notLeft:

    ; up
    lda cur_keys
    and #KEY_UP
    beq notUp
        ; Up is pressed. Subtract from position.
        lda player_ylo
        sub player_speed_lo
        sta player_ylo
        lda player_yhi
        sbc player_speed_hi
        cmp #TOP_WALL
        bcs :+ ; top wall collision
            lda #TOP_WALL
        :
        sta player_yhi
    notUp:

    ; down
    lda cur_keys
    and #KEY_DOWN
    beq notDown
        ; Down is pressed. Add to position.
        lda player_ylo
        add player_speed_lo
        sta player_ylo
        lda player_yhi
        adc player_speed_hi
        cmp #(240-40) ; I don't know why this is the right value
        bcc :+
            lda #(240-40)
        :
        sta player_yhi
    notDown:

    ; a
    lda cur_keys
    and #KEY_A
    beq notA
        jsr arrow_launch
    notA:

    ; select: debug next level
    lda cur_keys
    and #KEY_SELECT
    beq notSelect
        notify centipede_kill
    notSelect:

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
