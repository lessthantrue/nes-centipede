.include "gamestates.inc"
.include "../game/game.inc"
.include "../gamestaterunner.inc"
.include "../core/macros.inc"
.include "../core/common.inc"

.segment "CODE"

; Auxiliary state so starting the playing state doesn't reset the level.
; Needed for pausing.

.proc load
    jsr game_level_reset
    rts
.endproc

.proc transition
    swap_state playing
.endproc

.export state_level_reset_load := load-1
.export state_level_reset_logic := empty
.export state_level_reset_bg := empty
.export state_level_reset_transition = transition-1