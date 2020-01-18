.include "statusbar.inc"
.include "../nes.inc"
.include "../core/6502.inc"
.include "../core/bin2dec.inc"
.include "../spritegfx.inc"

.segment "ZEROPAGE"
MAX_LIVES = 6
START_LIVES = 3
score:              .res 2
lives:              .res 1
lives_temp:         .res 1 ; needed for draw lives
statusbar_level:    .res 1 ; technically not on the status bar, but we keep track of it here
oam_offsets:        .res MAX_LIVES-1

.segment "CODE"

.proc statusbar_init
    lda #0
    sta score
    sta score+1
    sta statusbar_level
    lda #START_LIVES
    sta lives
    .repeat 3, I
        jsr oam_alloc
        sty oam_offsets+I
    .endrep
    rts
.endproc

; adds an amount to the game score
; arg 1: low byte of score value to add
; arg 2: high byte of score value to add
.proc statusbar_addscore
    lda score
    clc
    adc STACK_TOP+1, x
    sta score
    sta binary
    lda score+1
    adc STACK_TOP+2, x
    sta score+1
    sta binary+1
    jsr clear_output
    jsr bin2dec_16bit
    rts
.endproc

.proc clear_output
    lda #0
    ldy #0
    :
        sta decimal, y
        iny
        cpy #8
        bne :-
    rts
.endproc

.proc statusbar_dec_lives
    lda lives
    beq :+
        dec lives
    :
    ldy lives
    lda oam_offsets, y
    tay
    jsr oam_free
    rts
.endproc

.proc statusbar_draw_score
    lda PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$41
    sta PPUADDR
    ldy #00
    :
        lda decimal, y
        ora #'0' ; number tiles start at 30
        sta PPUDATA
        iny
        cpy #8
        bne :-
    rts
.endproc

.proc statusbar_draw_lives
    rts
    ldx #0
    lda #140
    :
        ldy oam_offsets, x
        sub #8
        sta OAM+oam::xcord, y
        pha
        lda #128
        sta OAM+oam::ycord, y
        lda #0
        sta OAM+oam::flags, y
        lda #$21
        sta OAM+oam::tile, y
        pla
        inx
        cpx lives
        beq :-
    rts
.endproc
