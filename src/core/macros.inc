.ifndef MACROS_INC
MACROS_INC = 1

; adds const * mult to a
; uses X
.macro add_multiple const, mult
    ldx mult
    :
    cpx #0
    beq :+
    clc
    adc const
    dex
    jmp :-    
    :
.endmacro

; adds const * mult to a 2 byte number
; uses X, A
.macro add_multiple_short addr, const, mult
    lda addr
    ldx mult
    :
        cpx #0
        beq :++
        add const
        bcc :+
            inc addr+1
        :
        dex
        jmp :--
    :
    sta addr
.endmacro

; saves all registers on the stack
.macro push_registers
    pha ; A
    txa
    pha ; X
    tya
    pha ; Y
.endmacro

; loads all registers from the stack
.macro pull_registers
    pla
    tay ; Y
    pla
    tax ; X
    pla ; A
.endmacro

; saves a memory address to another spot in memory
.macro st_addr addr, place
    lda #.lobyte(addr)
    sta place
    lda #.hibyte(addr)
    sta place+1
.endmacro

; adds to memory with carry
; uses A
.macro adm mem, amt
    lda mem
    adc amt
    sta mem
.endmacro

; add WITHOUT carry 
.macro add oper
    clc
    adc oper
.endmacro

; subtract WITHOUT carry
.macro sub oper
    sec
    sbc oper
.endmacro

; inverts register a
.macro not
    eor #%11111111
.endmacro

; clear bits in a memory location that are set in an argument
; uses A
.macro clear arg, bits
    lda bits
    not
    and arg
    sta arg
.endmacro

.macro set arg, bits
    lda bits
    ora arg
    sta arg
.endmacro

.macro  push    r1, r2, r3, r4, r5, r6, r7
    .ifblank        r1
    .ifblank        r2
    .ifblank        r3
    .ifblank        r4
    .ifblank        r5
    .ifblank        r6
    .ifblank        r7
        ; all parameters are empty
        .exitmacro
    .endif
    .endif
    .endif
    .endif
    .endif
    .endif
    .endif
    .ifblank r1
        ; emit nothing
    .elseif .match({r1}, a)
        pha
    .else
        lda     r1
        pha
    .endif
        push    r2, r3, r4, r5, r6, r7
.endmacro

.macro call_with_args routine, a1, a2, a3, a4, a5, a6, a7
    ; preserve X in case of nested calls
    txa
    pha
    ; args go on the stack in reverse order
    push a7, a6, a5, a4, a3, a2, a1
    tsx
    jsr routine
    tsx
    txa
    add #(.PARAMCOUNT - 1) ; clean up parameters pushed on the stack
    tax
    txs
    ; restore X
    pla
    tax
.endmacro

; note: push args in reverse order when calling manually
.macro call_with_args_manual routine, nargs
    tsx
    jsr routine
    tsx
    txa
    add #nargs
    tax
    txs
.endmacro

.define MAKE_IDENT(format, symb) .ident(.sprintf(format, .string(symb)))

.define bls bcc ; branch if register less than value
.define bge bcs ; branch if register greater or equal to value

; m1 <- m1 + m2
; m1, m2 are little-endian words
.macro adw m1, m2
    lda m1
    add m2
    sta m1
    lda m1+1
    adc m2+1
    sta m1+1
.endmacro

; m1 <- m1 - m2
; m1, m2 are little-endian words
.macro sbw m1, m2
    lda m1
    sub m2
    sta m1
    lda m1+1
    sbc m2+1
    sta m1+1
.endmacro

; twos complement for negative
.macro neg
    not
    add #1
.endmacro

; m <- -m
.macro ngw m
    lda m
    neg
    sta m
    lda m+1
    not
    adc #0 ; this has to be different because reasons
    sta m
.endmacro

.endif