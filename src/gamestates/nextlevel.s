.include "gamestates.inc"
.include "../gamestaterunner.inc"
.include "../nes.inc"
.include "../events/events.inc"
.include "../ppuclear.inc"
.include "../game/game.inc"

.segment "BSS"
state_nextlevel_delay   :   .res 1
next_bg_attribute       :   .res 1

.segment "RODATA"
; order: poison mushroom fill, normal mushroom outline, poison mushroom outline

palette_set_0:
    .byt $0F
    .byt $30,$16,$2A,$0F, $27,$2C,$15,$0F, $2C,$28,$16,$0F, $2C,$02,$27,$0F
    ; sprite palettes are the same as bg palettes
    .byt $30,$16,$2A,$0F, $27,$2C,$15,$0F, $2C,$28,$16,$0F, $2C,$02,$27,$0F

palette_set_1:  
    .byt $0F
    .byt $28,$14,$2C,$0F, $02,$27,$2C,$0F, $2A,$14,$28,$0F, $28,$06,$2C,$0F
    .byt $28,$14,$2C,$0F, $02,$27,$2C,$0F, $2A,$14,$28,$0F, $28,$06,$2C,$0F

palette_set_2:
    .byt $0F
    .byt $16,$2C,$14,$0F, $2C,$02,$27,$0F, $30,$16,$2C,$0F, $16,$14,$2A,$0F
    .byt $16,$2C,$14,$0F, $2C,$02,$27,$0F, $30,$16,$2C,$0F, $16,$14,$2A,$0F

.segment "CODE"

.proc state_nextlevel_logic
    dec state_nextlevel_delay
    beq :+
        ; let the player keep going for a bit
        jsr player_move
        jsr arrow_step
        jsr player_draw
        jsr arrow_draw
        jsr statusbar_draw_lives
        rts
    :

    ; increment level, and construct the background attribute byte with it
    ; (2 bit value repeated 4 times)
    inc statusbar_level
    lda statusbar_level
    and #%00000011
    sta next_bg_attribute
    .repeat 3
        asl
        asl
        add next_bg_attribute
    .endrep
    sta next_bg_attribute
    cmp #0
    bne no_palette_change
        ; need to load a new palette set
        lda statusbar_level
        sub #4
        sub #4
        bcs next1
            load_palette palette_set_1
            jmp no_palette_change
        next1:
        sub #4
        bcs next2
            load_palette palette_set_2
            jmp no_palette_change
        next2:
        load_palette palette_set_0
    no_palette_change:
    rts
.endproc

.proc state_nextlevel_bg
    jsr game_bg
    lda state_nextlevel_delay
    beq :+
        rts
    :
    ; transition levels when timer expires
    ; use next background palette
    ldy next_bg_attribute
    jsr ppu_clear_attr

    rts
.endproc

.proc state_nextlevel_transition
    lda state_nextlevel_delay
    beq :+
        rts
    :
    
    ; transition to the next level, starting over
    notify level_up
    jsr game_level_reset
    swap_state playing
    rts
.endproc