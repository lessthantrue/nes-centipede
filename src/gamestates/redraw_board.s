.include "gamestates.inc"
.include "../gamestaterunner.inc"
.include "../core/macros.inc"
.include "../core/common.inc"
.include "../nes.inc"
.include "../ppuclear.inc"
.include "../game/game.inc"

; this state exists because some background drawing
; and other PPU work needs to be done
; before moving from main menu to playing

.segment "BSS"

PHASE_DRAW = 3
PHASE_PPU_ON = 2
PHASE_END = 0
phase: .res 1

.segment "CODE"

.proc load
    lda #PHASE_DRAW
    sta phase
    rts
.endproc

.proc bg
    lda phase
    cmp #PHASE_END
    beq e
    cmp #PHASE_PPU_ON
    bne :+
        ; turn the PPU back on
        lda #BG_ON|OBJ_ON
        sta PPUMASK
        lda #PHASE_END
        sta phase
        jmp e
    :

    ; turn off background drawing for this
    lda PPUSTATUS
    lda #0
    sta PPUMASK

    load_palette palette_set_1
    jsr board_draw
    lda #PHASE_PPU_ON
    sta phase

    e:
    rts
.endproc

.proc transition
    lda phase
    bne :+
        swap_state playing
    :
    rts
.endproc

.export state_redraw_board_load := load
.export state_redraw_board_logic := empty-1
.export state_redraw_board_bg := bg-1
.export state_redraw_board_transition := transition-1