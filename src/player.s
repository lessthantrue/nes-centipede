.include "nes.inc"
.include "global.inc"
.include "core/macros.inc"
.include "arrow.inc"
.include "player.inc"
.include "spritegfx.inc"

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
    bcc :+
      inc player_xhi
    :
    sta player_xlo
    lda player_xhi
    add #SPEED_HI
    sta player_xhi
  notRight:

  ; left
  lda cur_keys
  and #KEY_LEFT
  beq notLeft
    ; Left is pressed. Subtract from position.
    lda player_xlo
    sub #SPEED_LO
    bcs :+
      dec player_xhi
    :
    sta player_xlo
    lda player_xhi
    sub #SPEED_HI
    sta player_xhi
  notLeft:

  ; up
  lda cur_keys
  and #KEY_UP
  beq notUp
    ; Up is pressed. Subtract from position.
    lda player_ylo
    sub #SPEED_LO
    bcs :+
      dec player_yhi
    :
    sta player_ylo
    lda player_yhi
    sub #SPEED_HI
    sta player_yhi
  notUp:

  ; down
  lda cur_keys
  and #KEY_DOWN
  beq notDown
    ; Down is pressed. Subtract from position.
    lda player_ylo
    add #SPEED_LO
    bcc :+
      inc player_yhi
    :
    sta player_ylo
    lda player_yhi
    add #SPEED_HI
    sta player_yhi
  notDown:

  ; a
  lda cur_keys
  and #KEY_A
  beq notA
    jsr arrow_launch
  notA:

  ; Test for collision with left wall
  lda player_xhi
  cmp #1
  bcs notHitLeft
    lda #1
    sta player_xhi
    jmp doneWallCollision
  notHitLeft:
  ; Test for collision with right wall
  cmp #(256-18)
  bcc notHitRight
    lda #(256-18)
    sta player_xhi
  notHitRight:
  ; Additional checks for collision, if needed, would go here.
doneWallCollision:

  ; Test for collision with bottom wall
  lda player_yhi
  cmp #(240-32-9)
  bcc notHitBottom
    lda #(240-32-9)
    sta player_yhi
    jmp doneTopCollision
  notHitBottom:
  ; Test for collision with top wall
  cmp #TOP_WALL
  bcs notHitTop
    lda #TOP_WALL
    sta player_yhi
  notHitTop:
doneTopCollision:
  rts
.endproc

;;
; Draws the player's character to the display list as six sprites.
; In the template, we don't need to handle half-offscreen actors,
; but a scrolling game will need to "clip" sprites (skip drawing the
; parts that are offscreen).
.proc player_draw
  call_with_args spritegfx_load_oam, player_yhi, #$31, #0, player_xhi
  rts
.endproc

