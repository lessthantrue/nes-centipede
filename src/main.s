;
; Simple sprite demo for NES
; Copyright 2011-2014 Nicholas Milford
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

.include "nes.inc"
.include "global.inc"
.include "arrow.inc"
.include "board.inc"
.include "centipede.inc"
.include "player.inc"
.include "core/eventprocessor.inc"
.include "spritegfx.inc"
.include "gamestate.inc"

.segment "ZEROPAGE"
nmis:          .res 1
cur_keys:      .res 2
new_keys:      .res 2

.segment "CODE"

; This NMI handler is good enough for a simple "has NMI occurred?"
; vblank-detect loop.  But sometimes there are things that you always
; want to happen every frame, even if the game logic takes far longer
; than usual.  These might include music or a scroll split.  In these
; cases, you'll need to put more logic into the NMI handler.
.proc nmi_handler
  push_registers

  inc nmis

  pull_registers
  rti
.endproc

; A null IRQ handler that just does RTI is useful to add breakpoints
; that survive a recompile.  Set your debugging emulator to trap on
; reads of $FFFE, and then you can BRK $00 whenever you need to add
; a breakpoint.
;
; But sometimes you'll want a non-null IRQ handler.
; On NROM, the IRQ handler is mostly used for the DMC IRQ, which was
; designed for gapless playback of sampled sounds but can also be
; (ab)used as a crude timer for a scroll split (e.g. status bar).
.proc irq_handler
  rti
.endproc

.proc main

  ; Now the PPU has stabilized, and we're still in vblank.  Copy the
  ; palette right now because if you load a palette during forced
  ; blank (not vblank), it'll be visible as a rainbow streak.
  jsr load_main_palette

  ; While in forced blank we have full access to VRAM.
  ; Load the nametable (background map).
  jsr board_init
  jsr board_draw
  
  ; Set up game variables, as if it were the start of a new level.
  jsr player_init
  jsr centipede_init
  jsr arrow_init
  jsr gamestate_init

forever:

  ; Game logic
  jsr read_pads
  jsr player_move
  jsr arrow_step
  jsr player_setup_collision
  jsr centipede_step
  jsr spritegfx_reset
  jsr centipede_draw
  jsr player_draw
  jsr arrow_draw
  jsr gamestate_draw_lives

  ; Good; we have the full screen ready.  Wait for a vertical blank
  ; and set the scroll registers to display it.
  lda nmis
vw3:
  pha
  jsr evtp_run
  pla
  cmp nmis
  beq vw3

  jsr board_update_background
  lda PPUSTATUS
  jsr gamestate_draw_score

  ; Copy the display list from main RAM to the PPU
  lda #0
  sta OAMADDR
  lda #>OAM
  sta OAM_DMA
  
  ; Turn the screen on
  ldx #0
  ldy #0
  lda #VBLANK_NMI|BG_0000|OBJ_1000
  sec
  jsr ppu_screen_on
  jmp forever

; And that's all there is to it.
.endproc

.proc load_main_palette
  ; seek to the start of palette memory ($3F00-$3F1F)
  lda PPUSTATUS
  ldx #$3F
  stx PPUADDR
  ldx #$00
  stx PPUADDR
  stx PPUSCROLL
  stx PPUSCROLL
copypalloop:
  lda initial_palette,x
  sta PPUDATA
  inx
  cpx #32
  bcc copypalloop
  rts
.endproc

.segment "RODATA"
COLOR_BG = $0F
initial_palette:
  ; background color
  .byt $0F
  ; background palette (3B each, each 4th byte unused, should be set to bg color)
  .byt $30,$06,$09,$0F,$06,$0D,$0D,$0F,$30,$06,$1A,$0F,$02,$12,$21,$0F
  ; sprite palette (3B each, each 4th byte unused)
  .byt $16,$20,$1A,$0F,$0F,$06,$16,$0F,$0D,$30,$06,$0F,$0F,$02,$12

; Include the CHR ROM data
.segment "CHR"
  .incbin "gfx/bggfx.chr"
  .incbin "gfx/spritegfx.chr"
