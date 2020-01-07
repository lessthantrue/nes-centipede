.include "dead.inc"
.include "../centipede.inc"
.include "../player.inc"
.include "../spritegfx.inc"
.include "playing.inc"
.include "../gamestaterunner.inc"
.include "../arrow.inc"
.include "../statusbar.inc"
.include "../spider.inc"
.include "gameover.inc"

.segment "BSS"
dead_timer:     .byte $CF

.segment "CODE"

.proc state_dead_logic
    dec dead_timer ; advance timer
    
    ; centipede needs to stay drawn
    jsr centipede_draw

    ; don't draw if the timer is past a point, for a delay
    lda #$C0
    cmp dead_timer
    bcc :+
        call_with_args spritegfx_load_oam, player_yhi, #$0, #0, player_xhi
        call_with_args spritegfx_load_oam, player_yhi, #$0, #0, player_xhi
        rts
    :

    ; arg 4: sprite x
    lda player_xhi
    sub #4
    pha

    ; arg 3: sprite flags
    lda #0
    pha

    ; arg 2: sprite tile index
    ; shifting left twice and cutting out the last bit gives the left sprite
    ; of the current death animation
    lda dead_timer
    lsr
    lsr
    and #%00001110 
    add #$40
    pha

    ; arg 1: sprite Y
    lda player_yhi
    pha
    call_with_args_manual spritegfx_load_oam, 4

    ; do it again, but with the right sprite, shifted right a bit
    lda player_xhi
    add #4
    pha
    
    lda #0
    pha

    lda dead_timer
    lsr
    lsr
    and #%00001110
    add #$41
    pha

    lda player_yhi
    pha
    call_with_args_manual spritegfx_load_oam, 4

    rts
.endproc

.proc state_dead_bg
    ; nothing to change in background
    rts
.endproc

.proc state_dead_transition
    lda dead_timer
    beq :+
        rts ; timer not expired, stay in state
    :
    ; transition to the same level, starting over
    jsr statusbar_dec_lives
    bne :+
        ; out of lives, go to gameover screen
        lda #240
        sta state_gameover_delay
        st_addr state_gameover_logic, gamestaterunner_logicfn
        st_addr state_gameover_bg, gamestaterunner_bgfn
        st_addr state_gameover_transition, gamestaterunner_transitionfn
        rts
    :
    jsr player_init
    jsr centipede_reset
    jsr arrow_init
    jsr spider_init

    st_addr state_playing_logic, gamestaterunner_logicfn
    st_addr state_playing_bg, gamestaterunner_bgfn
    st_addr state_playing_transition, gamestaterunner_transitionfn

    rts
.endproc