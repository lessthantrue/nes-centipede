.include "gamestates.inc"
.include "../game/game.inc"
.include "../spritegfx.inc"
.include "playing.inc"
.include "../gamestaterunner.inc"
.include "gameover.inc"
.include "../core/macros.inc"

.segment "BSS"
dead_timer:     .res 1

.segment "CODE"

.proc load
    lda #$C7
    sta dead_timer
    rts
.endproc

.proc logic
    dec dead_timer ; advance timer
    
    ; game still needs to be drawn
    jsr game_draw

    ; don't draw if the timer is past a point, for a delay
    lda #($CF-72)
    cmp dead_timer
    bcc :+
        call_with_args spritegfx_load_oam, #OFFSCREEN, #$0, #0, player_xhi
        call_with_args spritegfx_load_oam, #OFFSCREEN, #$0, #0, player_xhi
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
    ; shifting right twice and cutting out the last bit gives the left sprite
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

.proc bg
    ; nothing to change in background
    rts
.endproc

.proc transition
    lda dead_timer
    bne :+
        swap_state reset_mushrooms ; timer not expired, stay in state
    :
    rts
.endproc

.export state_dead_logic := logic-1
.export state_dead_bg := bg-1
.export state_dead_transition := transition-1
.export state_dead_load := load