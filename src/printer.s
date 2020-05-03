.include "printer.inc"
.include "ppuclear.inc"
.include "core/macros.inc"
.include "core/6502.inc"
.include "nes.inc"

.segment "ZEROPAGE"

; pointer to string
strptr:     .res 2
; length of string to print
strlen:     .res 1

.segment "CODE"

; expects address of string in strptr and lendth in strlen
; arg 1: Y position
.proc print_centered
    ; set cursor position
    ; y given as argument
    lda STACK_TOP+1, x
    pha

    ; x = (32 - len) / 2
    lda #32
    sub strlen
    lsr
    pha
    
    call_with_args_manual ppu_set_xy, 2

    ; start writing
    ldy #0
    :
        lda (strptr), y
        sta PPUDATA
        iny
        cpy strlen
        bls :-

    rts
.endproc

; expects address of string in strptr and length in strlen
; arg 1: x position
; arg 2: y position
.proc print
    ; set cursor position
    lda STACK_TOP+2, x
    pha
    lda STACK_TOP+1, x
    call_with_args_manual ppu_set_xy, 2

    ; write
    ldy #0
    :
        lda (strptr), y
        sta PPUDATA
        iny
        cpy strlen
        bls :-
    
    rts
.endproc

; decimal to string
; expects buffer pointer in strptr and number of digits in strlen
; arg 1: decimal string pointer low byte
; arg 2: decimal string pointer high byte
.proc dtos
    DEC_PTR_LO = 0
    DEC_PTR_HI = 1 ; locals
    FOUND_START = 2
    
    ; set up pointer to decimal in locals
    lda STACK_TOP+1, x
    sta DEC_PTR_LO
    lda STACK_TOP+2, x
    sta DEC_PTR_HI

    ldy #0
    sty FOUND_START
    L_START:
        lda (DEC_PTR_LO), y
        bne :+
            ; found a zero
            lda FOUND_START
            bne WRITE_ZERO ; already seen a nonzero digit: write the zero as normal
            lda #' ' ; otherwize load an empty space
            jmp WRITE_EMPTY ; write the empty space directly
        :
            ; found a not zero
            sta FOUND_START ; note that we found a not zero
            jmp WRITE_DEC ; just write it


        WRITE_ZERO:
            lda #0
        WRITE_DEC:
            add #'0' ; convert to character
        WRITE_EMPTY:
            
        sta (strptr), y
        iny
        cpy strlen
        bne L_START

    rts
.endproc







