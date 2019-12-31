.include "nes.inc"
.include "global.inc"
.include "arrow.inc"
.include "player.inc"
.include "spritegfx.inc"
.include "collision.inc"
.include "statusbar.inc"

.segment "BSS"
; Game variables
player_xlo:       .res 1  ; horizontal position is xhi + xlo/256 px
player_xhi:       .res 1
player_ylo:       .res 1
player_yhi:       .res 1

; speed in total is 1.5 px/frame
SPEED_LO = 128 ; speed in 1/256 px/frame
SPEED_HI = 1   ; speed in px/frame

TOP_WALL = 168 ; top player limit in px, header-adjusted (lower bound)

.segment "CODE"

.proc player_init
  lda #0
  sta player_xlo
  sta player_ylo
  lda #128
  sta player_xhi
  lda #192
  sta player_yhi
  rts
.endproc

; Moves the player character in response to controller 1.
.proc player_move

  ; right
  lda cur_keys
  and #KEY_RIGHT
  beq notRight
    ; Right is pressed. Add to position.
    lda player_xlo
    add #SPEED_LO
    sta player_xlo
    lda player_xhi
    adc #SPEED_HI
    cmp #(256-8)
    bcc :+
      lda #(256-8)
    :
    sta player_xhi
  notRight:

  ; left
  lda cur_keys
  and #KEY_LEFT
  beq notLeft
    ; Left is pressed. Subtract from position.
    lda player_xlo
    sub #SPEED_LO
    sta player_xlo
    lda player_xhi
    sbc #SPEED_HI
    bcs :+ ; left wall collision
      lda #0
    :
    sta player_xhi
  notLeft:

  ; up
  lda cur_keys
  and #KEY_UP
  beq notUp
    ; Up is pressed. Subtract from position.
    lda player_ylo
    sub #SPEED_LO
    sta player_ylo
    lda player_yhi
    sbc #SPEED_HI
    cmp #TOP_WALL
    bcs :+
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
    add #SPEED_LO
    sta player_ylo
    lda player_yhi
    adc #SPEED_HI
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

  ; b
  lda cur_keys
  and #KEY_B
  beq notB
    jsr statusbar_dec_lives
  notB:

  rts
.endproc

.proc player_draw
  call_with_args spritegfx_load_oam, player_yhi, #$31, #0, player_xhi
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
