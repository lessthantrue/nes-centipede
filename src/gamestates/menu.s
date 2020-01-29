.include "gamestates.inc"
.include "../pads.inc"
.include "../nes.inc"
.include "../gamestaterunner.inc"
.include "../core/macros.inc"
.include "../ppuclear.inc"
.include "../game/game.inc"

.segment "CODE"

MENU_BEGIN_MSG_LEN = 13
menu_begin_msg: .byte " PRESS START "

MENU_EXTRALIFE_MSG_LEN = 19
menu_extralife_msg: .byte " BONUS EVERY 12000 "

.proc load
    rts
.endproc

.proc logic
    jsr menu_step
    rts
.endproc

.proc bg
    ; top border
    lda #$21
    sta PPUADDR
    lda #$EB-$21
    sta PPUADDR
    ldy #0
    lda #0
    :
        cpy #MENU_BEGIN_MSG_LEN
        beq :+
        sta PPUDATA
        iny
        jmp :-
    :

    ; start message
    lda #$21
    sta PPUADDR
    lda #$EB-$01
    sta PPUADDR
    ldy #0
    :
        cpy #MENU_BEGIN_MSG_LEN
        beq :+
        lda menu_begin_msg, y
        sta PPUDATA
        iny
        jmp :-
    :

    ; extra life message
    lda #$22
    sta PPUADDR
    lda #$07
    sta PPUADDR
    ldy #0
    :
        cpy #MENU_EXTRALIFE_MSG_LEN
        beq :+
        lda menu_extralife_msg, y
        sta PPUDATA
        iny
        jmp :-
    :

    ; bottom border
    lda #$22
    sta PPUADDR
    lda #$27
    sta PPUADDR
    lda #0
    ldy #0
    :
        cpy #MENU_EXTRALIFE_MSG_LEN
        beq :+
        sta PPUDATA
        iny
        jmp :-
    :

    ldy #$00
    jsr ppu_clear_attr

    rts
.endproc

.proc transition
    lda #KEY_START
    bit cur_keys
    beq :+
        swap_state play_init
    :
    rts
.endproc

.export state_menu_logic := logic-1
.export state_menu_bg := bg-1
.export state_menu_load := load
.export state_menu_transition := transition-1