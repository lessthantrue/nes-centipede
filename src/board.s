.include "nes.inc"
.include "global.inc"
.include "macros.inc"
.include "board.inc"

.segment "ZEROPAGE"
ntaddr:         .res 2
board_arg_x:    .res 1
board_arg_y:    .res 1
boardaddr:      .res 2

update_ntaddr:  .res 2
update_data:    .res 1 ; 3 bits for mushroom damage level, bit 4 is "update required" flag
BOARD_FLAG_REQ_UPDATE = %00010000

.segment "BSS"
seed:       .res 2 ; doesn't matter what's here, so long as it's not zero
; 32 spaces wide (32 - margins) by 28 spaces tall = 896 bytes (yikes)
WIDTH = 32
HEIGHT = 26
board:      .res (WIDTH * HEIGHT)

.segment "CODE"

.proc reset_boardaddr
    pha
    st_addr board, boardaddr
    pla
    rts
.endproc

.proc reset_ntaddr
    pha
    lda #$20
    sta ntaddr + 1
    lda #((30 - HEIGHT - 1) * WIDTH)
    sta ntaddr
    pla
    rts
.endproc

; expects x, y registers to hold x, y location
; returns address of nametable index in ntaddr
.proc board_xy_to_nametable
    pha
    jsr reset_ntaddr 
    lda ntaddr ; a = x + (y + 30 - HEIGHT) * width
    add board_arg_x
    bcc :+
        inc ntaddr + 1
    :
    ldy board_arg_y
    mult_y:
        dey
        bmi :++
        add #WIDTH
        bcc :+
            inc ntaddr + 1
        :
        jmp mult_y
    :
    sta ntaddr
    pla
    rts
.endproc

; converts sprite coordinates (used by arrow, centipede, player) to background coordinates
; expects x, y registers to hold sprite x, y location
.proc board_convert_sprite_xy
    pha
    txa
    lsr a
    lsr a
    lsr a
    sta board_arg_x
    tya
    lsr a
    lsr a
    lsr a
    sta board_arg_y
    pla
    rts
.endproc

; expects x, y arguments in board_arg_x, board_arg_y
; returns address of index in boardaddr
.proc board_xy_to_addr
    push_registers
    jsr reset_boardaddr
    lda boardaddr
    add board_arg_x
    bcc :+
        inc boardaddr + 1
    :
    ldy board_arg_y
    mult_y:
        dey
        bmi :++
        add #WIDTH
        bcc :+
            inc boardaddr + 1
        :
        jmp mult_y
    :
    sta boardaddr
    pull_registers
    rts
.endproc      

; sets a to the board state at boardaddr
; fucks over X register btw
.proc board_get_value
    ldx #0
    lda (boardaddr, x) ; indirect mode
    rts
.endproc

; sets board state at boardaddr to a
; fucks over X register
.proc board_set_value
    ldx #0 ; needed for pre-indexed indirect mode
    sta (boardaddr, x)
    rts
.endproc

.proc board_request_update_background
    ; set update bit
    ora #BOARD_FLAG_REQ_UPDATE
    sta update_data

    ; preserve nametable address
    lda ntaddr
    sta update_ntaddr
    lda ntaddr+1
    sta update_ntaddr+1
    rts
.endproc

; updates the background at ntaddr with the value in boardaddr
.proc board_update_background
    lda #BOARD_FLAG_REQ_UPDATE
    bit update_data
    bne :+
        ; no update required
        rts
    :

    lda update_ntaddr+1
    sta PPUADDR
    lda update_ntaddr
    sta PPUADDR ; PPU is opposite endian of the CPU
    lda update_data ; byte at boardaddr in a
    and #$07 ; get mushroom growth level
    add #$60 ; convert to sprite index
    ; sta PPUDATA ; set background at ntaddr to that
    lda #0
    sta ntaddr
    sta ntaddr+1
    sta update_data ; clear data, most importantly update flag
    rts
.endproc

; Returns a random 8-bit number in A (0-255), clobbers X (0).
.proc prng
	ldx #8     ; iteration count (generates 8 bits)
	lda seed+0
:
	asl        ; shift the register
	rol seed+1
	bcc :+
	eor #$2D   ; apply XOR feedback whenever a 1 bit is shifted out
:
	dex
	bne :--
	sta seed+0
	cmp #0     ; reload flags
	rts
.endproc

.proc board_init
    ; set random seed
    lda #%11001011
    sta seed
    lda #%10011000
    sta seed+1

    ; zero board
    jsr reset_boardaddr
    ldy #HEIGHT
    y_loop_2:
        ldx #WIDTH
        x_loop_2:
            txa ; preserve registers
            pha
            lda #$00
            jsr board_set_value
            pla
            tax ; fix registers
            inc boardaddr
            bne :+ ; increment doesn't set carry, so we need to check for zero instead
                inc boardaddr + 1
            :
            dex
            bne x_loop_2
        dey
        bne y_loop_2
    
    ; place pseudo-random mushrooms
    ldy #30 ; number of mushrooms
    add_loop:
        jsr prng
        and #%00011111 ; clamp random value to 31
        cmp #HEIGHT - 5
        bmi :+
            sec ; if random number was HEIGHT or greater, subtract HEIGHT
            sbc #HEIGHT - 5
        :
        sta board_arg_y
        ; repeat for x
        jsr prng
        and #%00011111 ; clamp random value to 31
        cmp #WIDTH
        bmi :+
            sec ; same clamping method for WIDTH
            sbc #WIDTH
        :
        sta board_arg_x
        jsr board_xy_to_addr
        lda #04
        jsr board_set_value
        dey
        bne add_loop
    rts
.endproc

.proc board_draw
    ; Start by clearing the first nametable
    ldx #$20
    lda #00
    ldy #$AA
    jsr ppu_clear_nt

    jsr reset_ntaddr
    lda ntaddr+1
    sta PPUADDR
    lda ntaddr
    sta PPUADDR
    lda #%10000000
    sta PPUCTRL

    jsr reset_boardaddr
    ldy #HEIGHT
    y_loop_2:
        ldx #WIDTH
        x_loop_2:
            txa ; preserve registers
            pha
            jsr board_get_value ; byte at x, y in a
            and #$07 ; get mushroom growth level
            adc #$60 ; convert to number / sprite
            sta PPUDATA ; set background at (x, y) to that
            pla
            tax ; fix registers
            clc
            inc boardaddr
            bne :+
                inc boardaddr + 1
            :
            dex
            bne x_loop_2
        dey
        bne y_loop_2

    rts
.endproc