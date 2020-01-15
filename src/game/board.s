.include "../nes.inc"
.include "../core/macros.inc"
.include "board.inc"
.include "../core/6502.inc"
.include "../ppuclear.inc"
.include "../random.inc"

.segment "ZEROPAGE"
ntaddr:         .addr $0000
board_arg_x:    .res 1
board_arg_y:    .res 1
boardaddr:      .res 2

update_ntaddr:  .res 2
update_data:    .res 1 ; 3 bits for mushroom damage level, bit 4 is "update required" flag
BOARD_FLAG_REQ_UPDATE = %00010000

.segment "BSS"
; 32 spaces wide by 26 spaces tall = 832 bytes
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

; returns address of nametable index in ntaddr
.proc board_xy_to_nametable
    pha
    jsr reset_ntaddr 
    lda ntaddr ; a = x + (y + 30 - HEIGHT) * width
    add board_arg_x
    bcc :+
        inc ntaddr + 1
    :
    ldx board_arg_y
    mult_y:
        dex
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
; arg 1: x board index
; arg 2: y board index
.proc board_convert_sprite_xy
    pha
    lda STACK_TOP+1, x
    lsr a
    lsr a
    lsr a
    sta board_arg_x
    lda STACK_TOP+2, x
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
    ldx board_arg_y
    mult_y:
        dex
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
; uses register X
.proc board_get_value
    ldx #0
    lda (boardaddr, x) ; indirect mode
    rts
.endproc

; sets board state at boardaddr
; arg 1: board value to set
.proc board_set_value
    tya ; preserve y
    pha

    ldy #0
    lda STACK_TOP+1, x
    sta (boardaddr), y
    jsr board_request_update_background

    pla ; restore y
    tay
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

; updates the background at ntaddr with the value in boardaddr if requested in update_data
.proc board_update_background
    lda #BOARD_FLAG_REQ_UPDATE
    bit update_data
    bne :+
        ; no update required
        rts
    :
    
    lda PPUSTATUS
    lda update_ntaddr+1
    sta PPUADDR
    lda update_ntaddr
    sta PPUADDR ; MSB then LSB in PPUADDR
    lda update_data ; byte at boardaddr in a
    and #$07 ; get mushroom growth level
    add #$70 ; convert to sprite index
    sta PPUDATA ; set background at ntaddr to that
    lda #0
    sta update_ntaddr
    sta update_ntaddr+1
    sta update_data ; clear data, most importantly update flag

    rts
.endproc

.proc board_init
    ; zero board
    jsr reset_boardaddr
    ldy #HEIGHT
    y_loop_2:
        ldx #WIDTH
        x_loop_2:
            tya ; preserve registers
            pha
            ldy #0 ; needed for indirect mode
            lda #0
            sta (boardaddr), y
            pla
            tay ; fix registers
            inc boardaddr
            bne :+ ; increment doesn't set carry, so we need to check for zero instead
                inc boardaddr + 1
            :
            dex
            bne x_loop_2
        dey
        bne y_loop_2
    
    ; place pseudo-random mushrooms
    ldy #40 ; number of mushrooms
    add_loop:
        jsr rand8
        and #%00011111 ; clamp random value to 31
        cmp #HEIGHT-1
        bmi :+
            sec ; if random number was HEIGHT or greater, subtract HEIGHT
            sbc #HEIGHT-1
        :
        sta board_arg_y
        ; repeat for x
        jsr rand8
        and #%00011111 ; clamp random value to 31
        cmp #WIDTH - 2
        bmi :+
            sec ; same clamping method for WIDTH
            sbc #WIDTH - 2
        :
        sta board_arg_x
        inc board_arg_x
        jsr board_xy_to_addr
        tya
        pha
        ldy #0 ; needed for indirect mode
        lda #4
        sta (boardaddr), y
        pla
        tay
        dey
        bne add_loop
    rts
.endproc

.proc board_draw
    jsr reset_ntaddr
    lda ntaddr+1
    sta PPUADDR
    lda ntaddr
    sta PPUADDR

    jsr reset_boardaddr
    ldy #HEIGHT
    y_loop_2:
        ldx #WIDTH
        x_loop_2:
            txa ; preserve registers
            pha
            jsr board_get_value ; byte at x, y in a
            and #$07 ; get mushroom growth level
            adc #$70 ; convert to number / sprite
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