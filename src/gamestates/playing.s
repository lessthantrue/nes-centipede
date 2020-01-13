.include "gamestates.inc"
.include "../nes.inc"
.include "../gamestaterunner.inc"
.include "../spritegfx.inc"
.include "../sound.inc"
.include "../game/game.inc"
.include "../ppuclear.inc"

.segment "BSS"
player_dead_flag: .res 1
centipede_dead_flag: .res 1

.segment "CODE"

.proc state_playing_load
    lda #0
    sta player_dead_flag
    sta centipede_dead_flag
    jsr game_level_reset
    jsr ppu_clear_oam
    rts
.endproc

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
    : ; player not dead

    lda centipede_dead_flag
    beq :+
        ; centipede died
        swap_state nextlevel
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
