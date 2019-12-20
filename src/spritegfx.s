.include "nes.inc"
.include "core/macros.inc"
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

; loads the object at spritegfx_oam_arg into the next available oam sprite location
.proc spritegfx_load_oam
    push_registers

    ldx oam_used
    ldy #0
    :
        lda spritegfx_oam_arg, y
        sta OAM, x
        inx
        iny
        cpy #oam::xcord+1
        bne :-
    
    stx oam_used
    pull_registers
    rts
.endproc
