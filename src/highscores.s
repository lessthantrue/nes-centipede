.include "highscores.inc"
.include "core/macros.inc"
.include "core/6502.inc"

.segment "SAVE"

highscores: .res (SCORE_SIZE * SCORES_COUNT)

.segment "RODATA"

; default high scores
def_scores: .byte "NIK", $00, $3E, $80, 0, 0, 0, 1, 6, 0, 0, 0, $FF, $FF
            .byte "AAA", $00, $00, $00, 0, 0, 0, 0, 0, 0, 0, 0, $FF, $FF
            .byte "AAA", $00, $00, $00, 0, 0, 0, 0, 0, 0, 0, 0, $FF, $FF
            .byte "AAA", $00, $00, $00, 0, 0, 0, 0, 0, 0, 0, 0, $FF, $FF
            .byte "AAA", $00, $00, $00, 0, 0, 0, 0, 0, 0, 0, 0, $FF, $FF
            .byte "AAA", $00, $00, $00, 0, 0, 0, 0, 0, 0, 0, 0, $FF, $FF
            .byte "AAA", $00, $00, $00, 0, 0, 0, 0, 0, 0, 0, 0, $FF, $FF
            .byte "AAA", $00, $00, $00, 0, 0, 0, 0, 0, 0, 0, 0, $FF, $FF
DEF_SCORES_LEN = SCORE_SIZE * SCORES_COUNT

.segment "CODE"

; compares a high score with the current score
; arg 1: current score high byte
; arg 2: current score mid byte
; arg 3: current score low byte
; arg 4: high score to compare
; returns: y = 1 if arg >= score
.proc highscore_cmp
    lda STACK_TOP+4, x
    asl
    asl
    asl
    asl ; jank multiply by 16
    tay
    
    ; start comparing
    lda STACK_TOP+1, x
    cmp highscores+3, y
    bne :+
    lda STACK_TOP+2, x
    cmp highscores+4, y
    bne :+
    lda STACK_TOP+3, x
    cmp highscores+5, y
    :

    bge :+
        ldy #0
        jmp :++
    :
        ldy #1
    :
    ; just leave the compare status for the caller to deal with
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

; shifts every score past a point down one, deletes the lowest score
; arg 1: index and above to shift downwards
.proc highscore_make_space
    ; count of scores to shift = total scores - index to start at - 1
    lda #SCORES_COUNT
    sec
    sbc STACK_TOP+1, x
    sub #1
    sta STACK_TOP+1, x
    ldy #(SCORE_SIZE * (SCORES_COUNT - 1))
    :
        dey
        lda highscores+SCORE_SIZE, y
        sta highscores, y
        tya
        and #(255-15)
        bne :-
        ; finished copying one
        dec STACK_TOP+1, x
        bne :-
    :
    rts
.endproc        
