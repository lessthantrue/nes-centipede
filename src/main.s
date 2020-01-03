.include "main.inc"
.include "ppuclear.inc"
.include "nes.inc"
.include "pads.inc"
.include "core/eventprocessor.inc"
.include "spritegfx.inc"
.include "gamestaterunner.inc"
.include "arrow.inc"
.include "player.inc"
.include "centipede.inc"
.include "board.inc"
.include "statusbar.inc"
.include "gamestates/playing.inc"
.include "events/events.inc"
.include "sound.inc"

.segment "ZEROPAGE"
nmis:          .res 1

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
  jsr statusbar_init
  jsr player_dead_init
  jsr sound_init

  st_addr state_playing_logic, gamestaterunner_logicfn
  st_addr state_playing_bg, gamestaterunner_bgfn
  st_addr state_playing_transition, gamestaterunner_transitionfn

  subscribe player_dead, state_playing_player_dead_handler

forever:

  ; Game logic
  jsr gamestaterunner_transition
  jsr spritegfx_reset
  jsr read_pads
  jsr sound_run
  jsr gamestaterunner_logic

  ; Good; we have the full screen ready.  Wait for a vertical blank
  ; and set the scroll registers to display it.
  lda nmis
vw3:
  pha
  jsr evtp_run
  pla
  cmp nmis
  beq vw3

  jsr gamestaterunner_bg

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
  ; order: normal mushroom fill, poison mushroom outline, normal mushroom outline
  .byt $30,$06,$1A,$0F, $27,$2C,$15,$0F, $2C,$28,$16,$0F, $2C,$02,$27,$0F

  ; sprite palette (3B each, each 4th byte unused)
  ; order: eye color, player body color, centipede color
  .byt $16,$20,$1A,$0F, $2C,$27,$15,$0F, $28,$2C,$16,$0F, $02,$2C,$27,$0F

; Include the CHR ROM data
.segment "CHR"
  .incbin "gfx/bggfx.chr"
  .incbin "gfx/spritegfx.chr"
