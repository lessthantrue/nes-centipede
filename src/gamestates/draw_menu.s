.include "gamestates.inc"
.include "../nes.inc"
.include "../ppuclear.inc"
.include "../printer.inc"
.include "../highscores.inc"
.include "../core/macros.inc"
.include "../core/common.inc"

.segment "BSS"

PHASE_DRAW = 2
PHASE_PPU_ON = 1
PHASE_END = 0
phase:  .res 1

; string to write
score:  .res 8
space:  .res 1
name:   .res 3
SCORE_LEN = 3 + 3 + 8

.segment "RODATA"
hs_msg: pstring "HIGH SCORES"

.segment "CODE"

.proc load
    lda #PHASE_DRAW
    sta phase
    rts
.endproc

.proc bg
    lda phase
    cmp #PHASE_END
    bne :+
        jmp BG_END
    :
    cmp #PHASE_PPU_ON
    bne :+
        lda #BG_ON|OBJ_ON
        sta PPUMASK
        lda #PHASE_END
        sta phase
        jmp BG_END
    :

    ; PHASE_DRAW
    lda PPUSTATUS
    lda #0
    sta PPUMASK

    st_addr (hs_msg+1), strptr
    lda hs_msg
    sta strlen
    call_with_args print_centered, #3

    lda #0
    pha ; outer loop counter
    S_PRINT:
        pla
        pha 
        tax
        ldy highscores_sorted, x

        ; write name
        .repeat 3, I
        lda highscores+I, y
        sta name+I
        .endrep

        ; write scores
        st_addr score, strptr
        lda #8
        sta strlen
        tya ; get pointer to start of this high score
        add #.lobyte(highscores+6)
        tax
        lda #0
        adc #.hibyte(highscores+6)

        pha
        txa
        pha
        call_with_args_manual dtos, 2

        ; rewrite the space part
        lda #' '
        sta space

        ; print to screen
        pla
        pha
        add #4
        pha ; y cord
        lda #(16-(SCORE_LEN/2)-1)
        pha ; x cord

        st_addr score, strptr
        lda #SCORE_LEN
        sta strlen
        call_with_args_manual print, 2

        pla
        add #1
        pha
        cmp #SCORES_COUNT
        beq :+
            jmp S_PRINT
        :
    
    pla
    lda #PHASE_PPU_ON
    sta phase

    BG_END:
    rts
.endproc

.proc transition
    lda phase
    bne :+
        swap_state menu
    :
    rts
.endproc

.export state_draw_menu_load := load
.export state_draw_menu_logic := empty-1
.export state_draw_menu_bg := bg-1
.export state_draw_menu_transition := transition-1
