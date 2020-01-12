.include "gamestates.inc"
.include "../nes.inc"
.include "../gamestaterunner.inc"
.include "../spritegfx.inc"
.include "../sound.inc"
.include "../game/game.inc"

.segment "BSS"
player_dead_flag: .res 1
centipede_dead_flag: .res 1

.segment "CODE"

.proc state_playing_logic
    jsr game_step
    rts
.endproc

.proc state_playing_bg
    jsr game_bg
    rts
.endproc

.proc state_playing_transition
    lda player_dead_flag
    beq :+
        ; player died
        swap_state dead
        lda #0
        sta player_dead_flag
        rts
    : ; player not dead

    lda centipede_dead_flag
    beq :+
        ; centipede died
        swap_state nextlevel
        lda #100
        sta state_nextlevel_delay
        lda #0
        sta centipede_dead_flag
    :
    rts 
.endproc

.proc state_playing_player_dead_handler
    lda #1
    sta player_dead_flag
    rts
.endproc

.proc state_playing_centipede_dead_handler
    lda #1
    sta centipede_dead_flag
    rts
.endproc
