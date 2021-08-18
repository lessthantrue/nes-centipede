.include "highscores.inc"
.include "core/macros.inc"
.include "core/6502.inc"

.segment "BSS"

highscores_sorted:   .res SCORES_COUNT ; offsets to scores in sorted order

.segment "SAVE"

highscores: .res (SCORE_SIZE * SCORES_COUNT)

.segment "RODATA"

; default high scores
def_scores: .byte "EJD", $9F, $40, $00, 0, 0, 0, 1, 6, 5, 4, 3, 0, $FF
            .byte "DFT", $48, $3C, $00, 0, 0, 0, 1, 5, 4, 3, 2, 0, $FF
            .byte "CAD", $F0, $37, $00, 0, 0, 0, 1, 4, 3, 2, 0, 0, $FF
            .byte "DCB", $9A, $33, $00, 0, 0, 0, 1, 3, 2, 1, 0, 0, $FF
            .byte "ED ", $D2, $32, $00, 0, 0, 0, 1, 3, 0, 1, 0, 0, $FF
            .byte "DEW", $05, $32, $00, 0, 0, 0, 1, 2, 8, 0, 5, 0, $FF
            .byte "DFW", $A9, $2F, $00, 0, 0, 0, 1, 2, 2, 0, 1, 0, $FF
            .byte "GJR", $46, $2F, $00, 0, 0, 0, 1, 2, 1, 0, 2, 0, $FF
SCORES_LEN = SCORE_SIZE * SCORES_COUNT

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

; calculates and stores the checksum of all high scores
.proc calc_checksum
    ldx #0
    :
        ldy #0
        lda #0
        :
            add {highscores, x}
            inx
            iny
            cpy #14 ; end before flags byte
            bne :-
        inx
        not
        add #1 ; negate a so sum of this row + checksum = 0
        sta highscores, x ; put checksum where it belongs
        inx ; move to the start of the next one
        cpx #SCORES_LEN
        bne :-- ; unless we're done
    rts
.endproc

; if high scores are valid, a == 0
; if high scores are not valid, a != 0
.proc highscores_verify
    ldx #0
    :
        ldy #0
        lda #0
        :
            add {highscores, x}
            inx
            iny
            cpy #14
            bne :-
        inx
        add {highscores, x}
        bne :+
        cpx #SCORES_LEN
        bne :--
    :
    rts
.endproc

; fills highscores_sorted with offsets to scores in descending order
.proc highscores_sort
    jsr scores_sort_reset

    ; selection sort: find the largest element remaining, put it at the start, repeat
    lda #0
    pha ; outer loop counter
    S_SORT:
        lda #SCORES_COUNT-1
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
    jsr calc_checksum ; do this while we're here
    rts
.endproc

.proc highscores_hard_reset
    ldy #0
    :
        lda def_scores, y
        sta highscores, y
        iny
        cpy #SCORES_LEN
        bne :-
    jsr calc_checksum
    rts
.endproc
