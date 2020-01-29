.include "gamestates.inc"
.include "../gamestaterunner.inc"
.include "../core/macros.inc"
.include "../nes.inc"
.include "../ppuclear.inc"
.include "../game/game.inc"

; this state exists because some background drawing
; and other PPU work needs to be done
; before moving from main menu to playing

.segment "CODE"

.proc load
    rts
.endproc

.proc logic
    jsr statusbar_init
    jsr game_full_reset
    ldx #0
    jsr ppu_clear_oam
    rts
.endproc

.proc bg
    ; turn off background drawing for this
    load_palette palette_set_1
    lda #0
    sta PPUMASK
    jsr board_draw
    rts
.endproc

.proc transition
    swap_state playing
    rts
.endproc

.export state_play_init_load := load
.export state_play_init_logic := logic-1
.export state_play_init_bg := bg-1
.export state_play_init_transition := transition-1