.include "gamestates.inc"
.include "../nes.inc"
.include "../gamestaterunner.inc"
.include "../core/common.inc"
.include "../spritegfx.inc"
.include "../sound.inc"
.include "../game/game.inc"
.include "../ppuclear.inc"
.include "../events/events.inc"
.include "../pads.inc"

.segment "BSS"

pause_buf: .res 1

.segment "CODE"

.proc state_playing_init
    ; subscribe player_dead, state_playing_player_dead_handler-1
    rts
.endproc

.proc load
    lda #1
    sta pause_buf
    rts
.endproc

.proc logic
    jsr game_step

    lda #KEY_START
    bit cur_keys
    bne :+
        lda #0
        sta pause_buf
    :
    rts
.endproc

.proc transition
    lda #FLAG_PLAYER
    bit game_enemy_statuses
    bne :+
        ; player died
        swap_state dead
    : ; player not dead

    lda pause_buf
    bne :+
    lda #KEY_START
    bit cur_keys
    beq :+
        swap_state paused
    :

    lda #FLAG_PLAYER
    not
    and game_enemy_statuses
    bne :+
        swap_state nextlevel
    :

    rts 
.endproc

.export state_playing_load := load
.export state_playing_logic := logic-1
.export state_playing_bg := game_bg-1
.export state_playing_transition := transition-1