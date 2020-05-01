.include "highscores.inc"
.include "core/macros.inc"
.include "core/6502.inc"

.segment "BSS"

highscores_sorted:   .res SCORES_COUNT ; offsets to scores in sorted order

.segment "SAVE"

highscores: .res (SCORE_SIZE * SCORES_COUNT)

.segment "RODATA"

; default high scores
def_scores: .byte "NIK", $00, $01, $00, 0, 0, 0, 0, 0, 2, 5, 6, 0, $FF
            .byte "AAA", $09, $00, $00, 0, 0, 0, 0, 0, 0, 0, 9, 0, $FF
            .byte "AAA", $08, $00, $00, 0, 0, 0, 0, 0, 0, 0, 8, 0, $FF
            .byte "AAA", $06, $00, $00, 0, 0, 0, 0, 0, 0, 0, 6, 0, $FF
            .byte "AAA", $03, $00, $00, 0, 0, 0, 0, 0, 0, 0, 3, 0, $FF
            .byte "AAA", $04, $00, $00, 0, 0, 0, 0, 0, 0, 0, 5, 0, $FF
            .byte "AAA", $05, $00, $00, 0, 0, 0, 0, 0, 0, 0, 4, 0, $FF
            .byte "AAA", $07, $00, $00, 0, 0, 0, 0, 0, 0, 0, 7, 0, $FF
DEF_SCORES_LEN = SCORE_SIZE * SCORES_COUNT

.segment "CODE"

; resets all the sorted flags in the scores list
.proc scores_sort_reset
    ldy #((SCORES_COUNT-1) * SCORE_SIZE)
    :
        lda #0
        sta highscores+14, y
        tya
        sub #SCORE_SIZE
        tay
        bpl :-
    rts
.endproc

; fills highscores_sorted with offsets to scores in descending order
.proc highscores_sort
    jsr scores_sort_reset


    ; selection sort: find the largest element remaining, put it at the start
    lda #0
    pha ; outer loop counter
    S_SORT:
        lda #SCORES_COUNT
        pha ; loop counter

        ldy #0 ; greatest score offset
        ldx #SCORE_SIZE ; current score offset
        S_FIND:
            ; skip if sorted score[x]
            lda highscores+14, x
            bne E_FIND

            ; always take if sorted score[y]
            lda highscores+14, y
            bne X_GR

            ; test score[y] < score[x]
            lda highscores+5, y
            cmp highscores+5, x
            bls X_GR
            bne E_FIND
            lda highscores+4, y
            cmp highscores+4, x
            bls X_GR
            bne E_FIND
            lda highscores+3, y
            cmp highscores+3, x
            bls X_GR

            ; score[x] < score[y], jump to end of loop
            jmp E_FIND

            X_GR:
            ; score[x] >= score[y], y <- x
            txa
            tay

            E_FIND:
            ; increase x
            txa
            add #SCORE_SIZE
            tax
            ; increment loop counter
            pla
            sub #1
            pha
            bne S_FIND ; while stack[top] != 0
        pla ; clean up loop counter on stack top from inner loop
        ; largest unsorted element index in y

        lda #1
        sta highscores+14, y ; set sorted bit for that element

        pla
        tax ; next available score index in X
        tya
        sta highscores_sorted, x ; put Y there
        txa
        add #1 ; increment loop counter / sorted scores array offset
        pha
        cmp #SCORES_COUNT
        bne S_SORT ; while stack[top] != SCORE_COUNT
    pla ; clean up last loop counter
    rts
.endproc

.proc highscore_hard_reset
    ldy #0
    :
        lda def_scores, y
        sta highscores, y
        iny
        cpy #DEF_SCORES_LEN
        bne :-
    rts
.endproc
