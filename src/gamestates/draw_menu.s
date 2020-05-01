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
name:   .res 3
space:  .res 1
score:  .res 8
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
        .repeat 3, I
        lda highscores+I, y
        sta name+I
        .endrep

        .repeat 8, I
        lda highscores+I+6, y
        add #'0'
        sta score+I
        .endrep

        ; rewrite the space part
        lda #' '
        sta space

        ; print to screen
        pla
        pha
        add #4
        pha

        st_addr name, strptr
        lda #SCORE_LEN
        sta strlen
        call_with_args_manual print_centered, 1

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
