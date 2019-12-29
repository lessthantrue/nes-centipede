.include "gamestate.inc"
.include "global.inc"
.include "nes.inc"
.include "core/6502.inc"
.include "core/bin2dec.inc"

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
    jsr convert_score
    rts
.endproc

.proc gamestate_dec_lives
    dec lives
    rts
.endproc

.proc convert_score
    lda score
    sta binary
    lda score+1
    sta binary+1
    jsr bin2dec_16bit
    rts
.endproc

.proc gamestate_draw
    lda PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$40
    sta PPUADDR
    ldy #08
    :
        lda decimal, y
        add #$30 ; number tiles start at 30
        sta PPUDATA
        dey
        bne :-

    rts
.endproc