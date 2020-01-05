.include "gameover.inc"
.include "../gamestaterunner.inc"
.include "menu.inc"
.include "../nes.inc"
.include "../core/macros.inc"

.segment "BSS"
state_gameover_delay:   .res 1

.segment "CODE"
GAMEOVER_MSG_LEN = 12
gameover_msg: .byte " GAME  OVER "

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
    dec state_gameover_delay
    bne :+
        st_addr state_menu_logic, gamestaterunner_logicfn
        st_addr state_menu_bg, gamestaterunner_bgfn
        st_addr state_menu_transition, gamestaterunner_transitionfn
    :
    rts
.endproc