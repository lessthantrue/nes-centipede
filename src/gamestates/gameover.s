.include "gameover.inc"
.include "../nes.inc"

.segment "CODE"
GAMEOVER_MSG_LEN = 12
gameover_msg: .byte $0, "GAME  OVER", $0

.proc state_gameover_logic
    rts
.endproc

.proc state_gameover_bg
    ; top border
    lda #$21
    sta PPUADDR
    lda #$EB-33
    sta PPUADDR

    ldy #0
    lda #0
    :
        cpy #GAMEOVER_MSG_LEN
        beq :+
        sta PPUDATA
        iny
        jmp :-
    :

    ; game over message
    lda #$21
    sta PPUADDR
    lda #$EB-1 ; I did the math
    sta PPUADDR
    
    ldy #0
    :
        cpy #GAMEOVER_MSG_LEN
        beq :+
        lda gameover_msg, y
        sta PPUDATA
        iny
        jmp :-
    :

    ; bottom border
    lda #$22
    sta PPUADDR
    lda #$0A
    sta PPUADDR

    ldy #0
    lda #0
    :
        cpy #GAMEOVER_MSG_LEN
        beq :+
        sta PPUDATA
        iny
        jmp :-
    :
    rts
.endproc

.proc state_gameover_transition
    rts
.endproc