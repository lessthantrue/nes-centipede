.include "nes.inc"
.include "core/macros.inc"
.include "core/6502.inc"
.include "spritegfx.inc"

.segment "ZEROPAGE"

spritegfx_oam_arg :   .tag oam
oam_used:   .res 1  ; starts at 0

.segment "CODE"

; resets internal sprite graphics variables.
; call at the start of each frame.
.proc spritegfx_reset
  ; The first entry in OAM (indices 0-3) is "sprite 0".  In games
  ; with a scrolling playfield and a still status bar, it's used to
  ; help split the screen.  Not using this yet, but maybe someday.
  ldx #4
  stx oam_used
  rts
.endproc

; loads the argument object data into OAM memory
; arg 1: sprite y
; arg 2: sprite tile index
; arg 3: sprite flags
; arg 4: sprite x
.proc spritegfx_load_oam
    push_registers
    ldy oam_used
    lda STACK_TOP+1, x
    add #SPRITE_VERT_OFFSET
    sta OAM, y
    iny
    lda STACK_TOP+2, x
    sta OAM, y
    iny
    lda STACK_TOP+3, x
    sta OAM, y
    iny
    lda STACK_TOP+4, x
    sta OAM, y
    iny
    sty oam_used
    pull_registers
    rts
.endproc
