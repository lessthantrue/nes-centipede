.include "../nes.inc"
.include "../core/macros.inc"
.include "board.inc"
.include "../core/6502.inc"
.include "../ppuclear.inc"
.include "../random.inc"

.segment "ZEROPAGE"
ntaddr:         .res 2
board_arg_x:    .res 1
board_arg_y:    .res 1
boardaddr:      .res 2

MAX_UPDATES_PER_FRAME = 8 ; last update space is zero terminator
updates_required:      .res 1
update_ntaddr_lo:      .res MAX_UPDATES_PER_FRAME
update_ntaddr_hi:      .res MAX_UPDATES_PER_FRAME
 ; 3 bits for mushroom damage level, 4th bit for poison
update_data:    .res MAX_UPDATES_PER_FRAME

.segment "BSS"
; 32 spaces wide by 26 spaces tall = 832 bytes
WIDTH = 32
HEIGHT = 26
PLAYER_REGION_TOP = 21 ; top of where player can move

; offset from nametable axes
BOARD_OFFSET_X = 0
BOARD_OFFSET_Y = 3

board:                      .res (WIDTH * HEIGHT)
board_count_player_area:    .res 1
PLAYER_REGION_ADDR_START = board + (PLAYER_REGION_TOP * WIDTH)

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

; redraws a number of tiles in a row starting at an xy location
; arg 1: PPU x
; arg 2: PPU y
; arg 3: number of tiles to redraw
.proc board_redraw_count
    lda STACK_TOP+1, x
    sub #BOARD_OFFSET_X
    sta board_arg_x
    lda STACK_TOP+2, x
    sub #BOARD_OFFSET_Y
    sta board_arg_y
    
    ; set board and nametable address
    txa
    pha
    jsr board_xy_to_addr
    jsr board_xy_to_nametable
    pla
    tax

    ; set PPU address
    lda ntaddr+1
    sta PPUADDR
    lda ntaddr
    sta PPUADDR

    ; start drawing
    ldy #0
    :   
        lda (boardaddr), y
        add #$60
        sta PPUDATA
        iny
        tya
        cmp STACK_TOP+3, x
        bne :-
    
    rts
.endproc

; checks if boardaddr is in the area that the player can move in
; A = 1 if boardaddr in player area, 0 otherwise
.proc boardaddr_in_player_area
    lda boardaddr+1
    cmp #.hibyte(PLAYER_REGION_ADDR_START)
    bls NOT_IN
    beq CMP_NEXT
    jmp IN

    CMP_NEXT:
    lda boardaddr
    cmp #.lobyte(PLAYER_REGION_ADDR_START)
    bls NOT_IN

    IN:
    lda #1
    jmp DONE

    NOT_IN:
    lda #0
    
    DONE:
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

    jsr boardaddr_in_player_area
    cmp #0
    beq NO_PLAYER_AREA_CHANGE
        ldy #0
        lda (boardaddr), y
        cmp STACK_TOP+1, x
        beq NO_PLAYER_AREA_CHANGE ; no difference
            ; there was a change
            cmp #0
            beq :+
            lda STACK_TOP+1, x
            cmp #0
            bne NO_PLAYER_AREA_CHANGE
                ; new value = 0, decrement
                lda #0
                cmp board_count_player_area
                beq NO_PLAYER_AREA_CHANGE ; count is off sometimes, so fix here
                dec board_count_player_area
                jmp NO_PLAYER_AREA_CHANGE
            :
                ; old value = 0, increment
                inc board_count_player_area
    NO_PLAYER_AREA_CHANGE:

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
    ldy updates_required
    sta update_data, y

    ; preserve nametable address
    lda ntaddr
    sta update_ntaddr_lo, y
    lda ntaddr+1
    sta update_ntaddr_hi, y

    inc updates_required
    rts
.endproc

; updates the background at ntaddr with the value in boardaddr if requested in update_data
.proc board_update_background
    lda PPUSTATUS
    ldy updates_required
    beq e
    s:
        dey
           
        lda update_ntaddr_hi, y
        sta PPUADDR
        lda update_ntaddr_lo, y
        sta PPUADDR ; MSB then LSB in PPUADDR
        lda update_data, y ; byte at boardaddr in a
        add #$60 ; convert to sprite index
        sta PPUDATA ; set background at ntaddr to that

        cpy #0
        bne s
    e:
    lda #0
    sta updates_required

    rts
.endproc

.proc board_init
    lda #0
    sta updates_required ; no updates required yet

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
    lda #0
    sta board_count_player_area ; reset number of shrooms in player area
    ldy #70 ; number of mushrooms
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
        and #%00011111 
        ; clamp random value to 31
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
        jsr boardaddr_in_player_area
        cmp #1
        bne :+
            ; mushroom in player area
            inc board_count_player_area
        :
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