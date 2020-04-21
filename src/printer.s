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

; expects address of pascal string in strptr
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
