.include "statusbar.inc"
.include "../nes.inc"
.include "../core/6502.inc"
.include "../core/bin2dec.inc"
.include "../spritegfx.inc"
.include "../events/events.inc"
.include "../highscores.inc"
.include "../printer.inc"

; high score save format:
; 3 bytes for initials
; 3 bytes for score
; 8 bytes for score in decimal

; EXTRALIFE_AMT = 100 ; debug
EXTRALIFE_AMT = 12000
LIVES_MAX = 6

.segment "ZEROPAGE"
score:              .res 3 ; 3b encapsulates the highest recorded score on arcade centipede
lives:              .res 1
lives_temp:         .res 1 ; needed for draw lives
statusbar_level:    .res 1 ; technically not status bar, but we keep track of it here
extralife_thresh:   .res 3 ; threshold to reach extra life
highscore:          .res 3 ; highest score

.segment "BSS"
SCORE_LEN = 8
score_str:          .res SCORE_LEN

.segment "CODE"

.proc statusbar_init
    lda #0
    sta score
    sta score+1
    sta score+2
    sta binary
    sta binary+1
    sta binary+2
    sta extralife_thresh+2

    .repeat 8, I
    sta decimal+I
    .endrep

    sta statusbar_level
    jsr bin2dec_24bit
    lda #3
    sta lives
    lda #.lobyte(EXTRALIFE_AMT)
    sta extralife_thresh
    lda #.hibyte(EXTRALIFE_AMT)
    sta extralife_thresh+1
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
    lda score+2
    adc #0
    sta score+2
    sta binary+2

    ; check for extra life 
    lda score+2
    cmp extralife_thresh+2
    beq :+          ; extralife_thresh = score at this byte, check next byte    
        bcc NO_EXTRA    ; extralife_thresh > score at this byte
        jmp EXTRA   ; extralife_thresh !>= score? must be less at this byte.
    :
    lda score+1     ; repeat for smaller bytes
    cmp extralife_thresh+1
    beq :+
        bcc NO_EXTRA
        jmp EXTRA
    :
    lda score
    cmp extralife_thresh
    bcc NO_EXTRA
    EXTRA:
        jsr statusbar_inc_lives
    NO_EXTRA:

    jsr clear_output
    jsr bin2dec_24bit
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
    rts
.endproc

.proc statusbar_inc_lives
    inc lives

    ; increase extra life threshold
    lda extralife_thresh
    add #.lobyte(EXTRALIFE_AMT)
    sta extralife_thresh
    lda extralife_thresh+1
    adc #.hibyte(EXTRALIFE_AMT)
    sta extralife_thresh+1
    lda extralife_thresh+2
    adc #0
    sta extralife_thresh+2

    ; let everyone know
    notify extra_life

    rts
.endproc

.proc statusbar_draw_score
    st_addr score_str, strptr
    lda #SCORE_LEN
    sta strlen
    call_with_args dtos, #<decimal, #>decimal

    lda PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$21
    sta PPUADDR
    ldy #00
    :
        lda score_str, y
        sta PPUDATA
        iny
        cpy #SCORE_LEN
        bne :-
    rts
.endproc

.proc statusbar_draw_highscore
    st_addr score_str, strptr
    lda #SCORE_LEN
    sta strlen
    
    ; find the pointer to the decimal portion of the highest high score
    lda highscores_sorted
    add #.lobyte(highscores+6)
    tay
    lda #0
    adc #.hibyte(highscores+6)

    ; push high, then low
    pha
    tya
    pha
    call_with_args_manual dtos, 2

    lda PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #($40-10)
    sta PPUADDR
    ldy #0
    :
        lda score_str, y
        sta PPUDATA
        iny
        cpy #SCORE_LEN
        bne :-
    rts
.endproc

.proc statusbar_draw_lives
    ldx #0
    ldy #96 ; sprite x
    draw_loop:
        txa
        pha
        tya
        pha ; arg 4: sprite x
        lda #0
        pha ; arg 3: attributes
        lda #$21
        pha ; arg 2: tile index
        inx
        cpx lives
        bls :+
            lda #$E7
            jmp :++
        :
            lda #$F0
        :
        pha ; arg 1: sprite y
        call_with_args_manual spritegfx_load_oam, 4
        pla
        tax
        tya ; restore A
        add #8
        tay
        inx
        cpx #LIVES_MAX
        bne draw_loop
    rts
.endproc
