.include "scoreparticle.inc"
.include "game.inc"
.include "../core/macros.inc"
.include "../spritegfx.inc"
.include "../core/6502.inc"

.segment "BSS"
lifetime:   .res 1
tile_index: .res 1
x_pos:      .res 1
y_pos:      .res 1

.segment "CODE"

; arg 1: particle x
; arg 2: particle y
; arg 3: particle tile index
.proc score_particle_init
    lda #60
    sta lifetime
    lda STACK_TOP+1, x
    sta x_pos
    lda STACK_TOP+2, x
    add #8
    sta y_pos
    lda STACK_TOP+3, x
    sta tile_index
    rts
.endproc

.proc score_particle_draw
    dec y_pos
    lda lifetime
    bne :+
        ; call_with_args spritegfx_load_oam, #OFFSCREEN, #0, #0, #0
        ; call_with_args spritegfx_load_oam, #OFFSCREEN, #0, #0, #0
        rts
    :
    dec lifetime
    ; call_with_args spritegfx_load_oam, y_pos, tile_index, #0, x_pos
    inc tile_index
    lda x_pos
    add #8
    ; call_with_args spritegfx_load_oam, y_pos, tile_index, #0, a
    dec tile_index
    rts
.endproc