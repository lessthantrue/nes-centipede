;
; NES PPU common functions
; Copyright 2011 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.    This file is offered as-is, without any warranty.
;
.include "nes.inc"
.include "ppuclear.inc"
.include "core/macros.inc"
.include "core/6502.inc"

;;
; Clears a nametable to a given tile number and attribute value.
; (Turn off rendering in PPUMASK and set the VRAM address increment
; to 1 in PPUCTRL first.)
; @param A tile number
; @param X base address of nametable ($20, $24, $28, or $2C)
; @param Y attribute value ($00, $55, $AA, or $FF)
.proc ppu_clear_nt

    ; Set base PPU address to XX00
    stx PPUADDR
    ldx #$00
    stx PPUADDR
    stx PPUSCROLL
    stx PPUSCROLL

    ; Clear the 960 spaces of the main part of the nametable,
    ; using a 4 times unrolled loop
    ldx #960/4
loop1:
    .repeat 4
        sta PPUDATA
    .endrep
    dex
    bne loop1

    ; Clear the 64 entries of the attribute table
    ldx #64
loop2:
    sty PPUDATA
    dex
    bne loop2
    rts
.endproc

;;
; Moves all sprites starting at address X (e.g, $04, $08, ..., $FC)
; below the visible area.
; X is 0 at the end.
.proc ppu_clear_oam

    ; First round the address down to a multiple of 4 so that it won't
    ; freeze should the address get corrupted.
    txa
    and #%11111100
    tax
    lda #$FF    ; Any Y value from $EF through $FF will work
loop:
    sta OAM,x
    inx
    inx
    inx
    inx
    bne loop
    rts
.endproc

;;
; Sets the scroll position and turns PPU rendering on.
; @param A value for PPUCTRL ($2000) including scroll position
; MSBs; see nes.h
; @param X horizontal scroll position (0-255)
; @param Y vertical scroll position (0-239)
; @param C if true, sprites will be visible
.proc ppu_screen_on
    ldx #0
    stx PPUADDR
    stx PPUADDR
    stx PPUSCROLL
    stx PPUSCROLL
    ora PPUCTRL
    sta PPUCTRL
    ; lda #BG_ON
    ; bcc :+
    ; lda #BG_ON|OBJ_ON
; :
    ; sta PPUMASK
    rts
.endproc

; @param Y attribute value ($00, $55, $AA, or $FF)
.proc ppu_clear_attr
    lda #$23
    sta PPUADDR
    lda #$C0
    sta PPUADDR
    ; Clear the 64 entries of the attribute table
    ldx #64
loop2:
    sty PPUDATA
    dex
    bne loop2
    rts
.endproc

; arg 1: nametable x
; arg 2: nametable y
.proc ppu_set_xy
    lda STACK_TOP+2, x ; nt y
    lsr
    lsr
    lsr ; cut off last 3 bits
    add #$20
    sta PPUADDR ; high byte of address

    lda STACK_TOP+2, x ; nt y 
    asl
    asl
    asl
    asl
    asl ; multiply by 32 (screen width)
    clc
    adc STACK_TOP+1, x ; add nt x
    sta PPUADDR ; low byte of address
    rts
.endproc