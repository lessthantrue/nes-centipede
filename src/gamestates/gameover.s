.include "gamestates.inc"
.include "../gamestaterunner.inc"
.include "menu.inc"
.include "../nes.inc"
.include "../core/macros.inc"
.include "../core/common.inc"
.include "../game/statusbar.inc"

.segment "BSS"
state_gameover_delay:   .res 1

.segment "CODE"
GAMEOVER_MSG_LEN = 12
gameover_msg: .byte " GAME  OVER "

.proc load
    lda #240
    sta state_gameover_delay
    rts
.endproc

.proc bg
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

.proc transition
    dec state_gameover_delay
    bne :+
        jsr statusbar_init
        swap_state menu
    :
    rts
.endproc

.export state_gameover_load := load
.export state_gameover_transition := transition-1
.export state_gameover_bg := bg-1
.export state_gameover_logic := empty-1