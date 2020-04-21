.ifndef PPUCLEAR_INC
PPUCLEAR_INC = 1

.include "nes.inc"

.global ppu_clear_nt, ppu_clear_oam, ppu_screen_on, ppu_clear_attr, ppu_set_xy

.macro load_palette palette
    .local copyloop

    lda PPUSTATUS
    ldx #$3F
    stx PPUADDR
    ldx #$00
    stx PPUADDR
    copyloop:
        lda palette, x
        sta PPUDATA
        inx
        cpx #32
        bcc copyloop
.endmacro

.endif