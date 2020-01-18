.include "nes.inc"
.include "core/6502.inc"
.include "spritegfx.inc"
.include "game/game.inc"

.segment "ZEROPAGE"
oams_reserved:  .res 8 ; 64 sprites, 1 bit each

.segment "CODE"

.proc oam_init
    ; zero reservations
    lda #0
    .repeat 8, I
    sta oams_reserved+I
    .endrep
    rts
.endproc

.proc oam_alloc
    ldy #0 ; counter
    START_SEARCH_BYTE: ; linear search for a zero bit
        lda oams_reserved, y
        cmp #$FF
        bne :+
            iny ; this byte is completely allocated
            jmp START_SEARCH_BYTE
        :
    
    pha ; use stack top as a local variable
    tsx
    tya
    .repeat 3 ; shift by 8 because we moved 8 bits for each byte
    asl
    .endrep
    tay
    lda #1
    START_SEARCH_BIT:
        pha
        and STACK_TOP+1, x ; check bit
        beq :+
            ; this bit is taken
            pla
            iny
            asl ; check the next bit
            jmp START_SEARCH_BIT
        :
        pla
        ora STACK_TOP+1, x ; set that bit
        sta STACK_TOP+1, x ; save new byte for later

    tya
    asl
    asl ; shift left twice, 4 bytes per OAM entry
    tay ; preserve in y

    lsr
    lsr
    lsr
    lsr
    lsr ; div by 8 to get the allocating byte
    tax
    pla
    sta oams_reserved, x ; set that byte to new value
    rts ; OAM offset in y
.endproc

; y: OAM offset to free
.proc oam_free
    lda #OFFSCREEN
    sta OAM+oam::ycord, y ; move freed sprite off the screen

    tya
    and #%00011100 ; just the bit indexing bits of the offset
    lsr
    lsr ; div by 4 to get the bit offset
    tax
    lda #1
    cpx #0
    START_SET_BIT:
        beq :+
        asl
        dex
        jmp START_SET_BIT
    :
    not
    pha ; save the bit mask that we just made
    
    tya
    lsr
    lsr ; div by 4 to get the OAM index
    lsr
    lsr
    lsr ; div by 8 more to get the allocating byte
    tay
    pla ; get the bit mask back
    and oams_reserved, y ; clear the bit
    sta oams_reserved, y ; save that change
    rts
.endproc