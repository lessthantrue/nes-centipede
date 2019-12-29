.include "gamestate.inc"
.include "global.inc"
.include "nes.inc"
.include "core/6502.inc"

.segment "ZEROPAGE"
score:      .word $0000
lives:      .byte $00

.segment "CODE"

.proc gamestate_init
    lda #0
    sta score
    sta score+1
    lda #3
    sta lives
    rts
.endproc

; adds an amount to the game score
; arg 1: low byte of score value to add
; arg 2: high byte of score value to add
.proc gamestate_addscore
    lda score
    clc
    adc STACK_TOP+1, x
    sta score
    lda score+1
    adc STACK_TOP+2, x
    sta score+1
    rts
.endproc

.proc gamestate_dec_lives
    dec lives
    rts
.endproc
