.include "gamestates.inc"
.include "../nes.inc"
.include "../gamestaterunner.inc"
.include "../spritegfx.inc"
.include "../sound.inc"
.include "../game/game.inc"
.include "../ppuclear.inc"
.include "../events/events.inc"

.segment "BSS"
player_dead_flag: .res 1
centipede_dead_flag: .res 1

.segment "CODE"

.proc state_playing_init
    subscribe player_dead, state_playing_player_dead_handler-1
    rts
.endproc

.proc load
    lda #0
    sta player_dead_flag
    sta centipede_dead_flag
    jsr game_level_reset
    rts
.endproc

.proc logic
    jsr game_step
    rts
.endproc

.proc bg
    jsr game_bg
    rts
.endproc

.proc transition
    lda player_dead_flag
    beq :+
        ; player died
        swap_state dead
    : ; player not dead

    lda #FLAG_PLAYER
    not
    and game_enemy_statuses
    bne :+
        swap_state nextlevel
    :

    rts 
.endproc

.proc state_playing_player_dead_handler
    lda #1
    sta player_dead_flag
    rts
.endproc

.export state_playing_load := load
.export state_playing_logic := logic-1
.export state_playing_bg := bg-1
.export state_playing_transition := transition-1