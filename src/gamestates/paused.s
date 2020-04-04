.include "gamestates.inc"
.include "../core/macros.inc"
.include "../gamestaterunner.inc"
.include "../pads.inc"
.include "../nes.inc"
.include "../core/common.inc"
.include "../game/game.inc"

.segment "BSS"

pause_buf:  .res 1

.segment "CODE"

PAUSE_MSG_LEN = 8
pause_msg:  .byte " PAUSED "

.proc load
    lda #1
    sta pause_buf
    rts
.endproc

.proc logic
    jsr game_draw

    lda #KEY_START
    bit cur_keys
    bne :+
        lda #0
        sta pause_buf
    :
    rts
.endproc

.proc bg
    ; top border
    lda #$21
    sta PPUADDR
    lda #$B0-(PAUSE_MSG_LEN/2)
    sta PPUADDR
    lda #0
    ldy #0
    :
        cpy #PAUSE_MSG_LEN
        beq :+
        sta PPUDATA
        iny
        jmp :-
    :

    ; message
    lda #$21
    sta PPUADDR
    lda #$D0-(PAUSE_MSG_LEN/2)
    sta PPUADDR
    lda #0
    ldy #0
    :
        cpy #PAUSE_MSG_LEN
        beq :+
        lda pause_msg, y
        sta PPUDATA
        iny
        jmp :-
    :

    ; bottom border
    lda #$21
    sta PPUADDR
    lda #$F0-(PAUSE_MSG_LEN/2)
    sta PPUADDR
    lda #0
    ldy #0
    :
        cpy #PAUSE_MSG_LEN
        beq :+
        sta PPUDATA
        iny
        jmp :-
    :

    rts
.endproc

.proc transition
    lda pause_buf
    bne :+
    lda #KEY_START
    bit cur_keys
    beq :+
        swap_state redraw_board
    :
    rts
.endproc

.export state_paused_logic := logic-1
.export state_paused_bg := bg-1
.export state_paused_load := load
.export state_paused_transition := transition-1