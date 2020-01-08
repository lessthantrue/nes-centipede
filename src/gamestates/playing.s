.include "playing.inc"
.include "../nes.inc"
.include "dead.inc"
.include "nextlevel.inc"
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
        st_addr state_dead_logic, gamestaterunner_logicfn
        st_addr state_dead_bg, gamestaterunner_bgfn
        st_addr state_dead_transition, gamestaterunner_transitionfn
        lda #0
        sta player_dead_flag
        rts
    : ; player not dead

    lda centipede_dead_flag
    beq :+
        ; centipede died
        st_addr state_nextlevel_logic, gamestaterunner_logicfn
        st_addr state_nextlevel_bg, gamestaterunner_bgfn
        st_addr state_nextlevel_transition, gamestaterunner_transitionfn
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
