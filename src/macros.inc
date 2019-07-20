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
