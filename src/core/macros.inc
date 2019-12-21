; adds const * mult to a
; fucks X
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
; fucks X, A
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

; adds to memory
; fucks A
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
; fucks register a
.macro cla arg, bits
    lda bits
    not
    and arg
    sta arg
.endmacro

.macro  push    r1, r2, r3, r4, r5, r6, r7
    .ifblank        r1
        ; First parameter is empty
        .exitmacro
    .else
        lda     r1
        pha
    .endif
        push    r2, r3, r4, r5, r6, r7
.endmacro

.macro call_with_args routine, a1, a2, a3, a4, a5, a6, a7
    push a1, a2, a3, a4, a5, a6, a7
    tsx
    jsr routine
    tsx
    txa
    add #(.PARAMCOUNT - 1) ; clean up parameters pushed on the stack
    tax
    txs
.endmacro