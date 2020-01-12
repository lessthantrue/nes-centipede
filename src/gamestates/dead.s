.include "gamestates.inc"
.include "../game/game.inc"
.include "../spritegfx.inc"
.include "playing.inc"
.include "../gamestaterunner.inc"
.include "gameover.inc"
.include "../core/macros.inc"

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
        swap_state gameover
        rts
    :
    jsr game_level_reset
    swap_state playing
    rts
.endproc