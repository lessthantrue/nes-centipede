.include "gamestates.inc"
.include "../pads.inc"
.include "../nes.inc"
.include "../core/macros.inc"
.include "../core/common.inc"
.include "../ppuclear.inc"
.include "game/game.inc"

.segment "BSS"

name:           .res 3

.segment "CODE"

highscore_msg1: .byte " GREAT SCORE "
highscore_msg2: .byte " ENTER YOUR INITIALS "

MSG1_LEN = 13
MSG2_LEN = 21

.proc bg
    ; top border
    call_with_args ppu_set_xy, #(16-MSG1_LEN/2), #12
    