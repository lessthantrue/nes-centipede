.include "nes.inc"
.include "global.inc"
.include "macros.inc"
.include "constants.inc"
.include "arrow.inc"
.include "player.inc"

.segment "BSS"
; Game variables
player_xlo:       .res 1  ; horizontal position is xhi + xlo/256 px
player_xhi:       .res 1
player_ylo:       .res 1
player_yhi:       .res 1

; constants used by move_player
; PAL frames are about 20% longer than NTSC frames.  So if you make
; dual NTSC and PAL versions, or you auto-adapt to the TV system,
; you'll want PAL velocity values to be 1.2 times the corresponding
; NTSC values, and PAL accelerations should be 1.44 times NTSC.
SPEED = 255 ; speed limit in 1/256 px/frame

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
    clc
    lda player_xlo
    adc #SPEED
    bcc :+
      inc player_xhi
    :
    sta player_xlo
  notRight:

  ; left
  lda cur_keys
  and #KEY_LEFT
  beq notLeft
    ; Left is pressed. Subtract from position.
    lda player_xlo
    sec
    sbc #SPEED
    bcs :+
      dec player_xhi
    :
    sta player_xlo
  notLeft:

  ; up
  lda cur_keys
  and #KEY_UP
  beq notUp
    ; Up is pressed. Subtract from position.
    lda player_ylo
    sec
    sbc #SPEED
    bcs :+
      dec player_yhi
    :
    sta player_ylo
  notUp:

  ; down
  lda cur_keys
  and #KEY_DOWN
  beq notDown
    ; Down is pressed. Subtract from position.
    lda player_ylo
    clc
    adc #SPEED
    bcc :+
      inc player_yhi
    :
    sta player_ylo
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
  lda player_yhi
  add #SPRITE_VERT_OFFSET
  sta $0200 ;sprite Y
  sta $0204
  lda #$10 ;sprite number 16
  sta $0201 ;sprite tile number
  sta $0205
  lda #%00000000
  sta $0202 ;sprite attributes
  lda #%01000000
  sta $0206
  lda player_xhi
  sta $0203 ;sprite X
  adc #$07
  sta $0207
  rts
.endproc

