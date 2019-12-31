.include "statusbar.inc"
.include "global.inc"
.include "nes.inc"
.include "core/6502.inc"
.include "core/bin2dec.inc"
.include "spritegfx.inc"

.segment "ZEROPAGE"
score:      .word $0000
lives:      .byte $00
lives_temp: .byte $00 ; needed for draw lives

.segment "CODE"

.proc statusbar_init
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
    pha
    lda lives
    beq :+
        dec lives
    :
    pla
    rts
.endproc

.proc statusbar_draw_score
    lda PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$40
    sta PPUADDR
    ldy #00
    :
        lda decimal, y
        ora #'0' ; number tiles start at 30
        sta PPUDATA
        iny
        cpy #8
        bne :-
    lda #$30
    sta PPUDATA
    sta PPUDATA ; trailing zeros that never change
    rts
.endproc

.proc statusbar_draw_lives
    ldx #8
    stx lives_temp
    ; TODO: clear out old OAMs for removed lives, or something
    lda #(112+40)
    draw_loop:
        sub #8
        tay ; preserve A, we'll need it later
        pha ; arg 4: sprite x
        lda #0
        pha ; arg 3: attributes
        lda #$31
        pha ; arg 2: tile index
        ldx lives_temp
        cpx lives
        bcc :+
            lda #$E7
            jmp :++
        :
            lda #$F7
        :
        pha ; arg 1: sprite y
        call_with_args_manual spritegfx_load_oam, 4
        tya
        dec lives_temp
        bne draw_loop
    rts
.endproc
