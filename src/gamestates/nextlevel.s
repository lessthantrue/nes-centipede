.include "nextlevel.inc"
.include "../gamestaterunner.inc"
.include "../nes.inc"
.include "playing.inc"
.include "../arrow.inc"
.include "../player.inc"
.include "../centipede.inc"
.include "../statusbar.inc"
.include "../board.inc"

.segment "BSS"
state_nextlevel_delay   :   .res 1
next_bg_attribute       :   .res 1

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
    inc level
    lda level
    and #%00000011
    sta next_bg_attribute
    .repeat 3
        asl
        asl
        add next_bg_attribute
    .endrep
    sta next_bg_attribute
    rts
.endproc

.proc state_nextlevel_bg
    jsr board_update_background
    jsr statusbar_draw_score
    lda state_nextlevel_delay
    beq :+
        rts
    :
    ; transition levels when timer expires
    ; use next background palette
    ldy next_bg_attribute
    ldx #64

    lda #$23
    sta PPUADDR
    lda #$C0
    sta PPUADDR

    ; set attribute table entries
    :
        sty PPUDATA
        dex
        bne :-

    rts
.endproc

.proc state_nextlevel_transition
    lda state_nextlevel_delay
    beq :+
        rts
    :
    
    ; transition to the next level, starting over
    jsr centipede_init
    st_addr state_playing_logic, gamestaterunner_logicfn
    st_addr state_playing_bg, gamestaterunner_bgfn
    st_addr state_playing_transition, gamestaterunner_transitionfn
    rts
.endproc