.include "main.inc"
.include "ppuclear.inc"
.include "nes.inc"
.include "pads.inc"
.include "spritegfx.inc"
.include "gamestaterunner.inc"
.include "gamestates/gamestates.inc"
.include "events/events.inc"
.include "sound.inc"
.include "random.inc"
.include "game/game.inc"
.include "highscores.inc"

.segment "ZEROPAGE"
nmis:                    .res 1

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
    load_palette palette_set_1
    jsr random_init

    ; While in forced blank we have full access to VRAM.
    ; Load the nametable (background map).
    jsr game_init_bg

    ; event initialization
    init player_dead
    init segment_kill
    init arrow_shoot
    init centipede_kill
    init level_up
    init extra_life

    ; this one game state that needs one-time initialization
    jsr state_playing_init

    ; set up most game logic
    jsr highscore_hard_reset
    jsr highscores_sort
    jsr game_init

    ; set initial state
    swap_state menu

    ; turn on vblank NMIs
    lda #VBLANK_NMI|OBJ_1000|BG_0000
    sta PPUCTRL
    lda #BG_ON|OBJ_ON
    sta PPUMASK

forever:
    ldx #0
    jsr ppu_clear_oam

    ; Game logic
    jsr gamestaterunner_transition
    jsr spritegfx_reset
    jsr read_pads
    jsr gamestaterunner_logic

    ; Good; we have the full screen ready.    Wait for a vertical blank
    ; and set the scroll registers to display it.
    lda nmis
vw3:
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

; Include the CHR ROM data
.segment "CHR"
    .incbin "gfx/bggfx.chr"
    .incbin "gfx/spritegfx.chr"
