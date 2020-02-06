.ifndef EVENT_MACROS_INC
EVENT_MACROS_INC = 1

.include "../core/macros.inc"
.include "../core/6502.inc"

.macro make_event evt_name, max_subs

    .local subscribers
    .local sub_count

    ; basically the whole file
    .segment "BSS"
    .ifblank max_subs
    subscribers: .res (3 * 2)
    .else
    subscribers: .res (max_subs * 2)
    .endif
    sub_count:      .res 2

    .segment "CODE"

    .proc MAKE_IDENT "%s_init", evt_name
        lda #0
        sta sub_count
        rts
    .endproc

    .proc MAKE_IDENT "%s_subscribe", evt_name
        ; look for the first zero address
        ldy sub_count
        .ifblank max_subs
        cpy #(3 * 2)
        .else
        cpy #(max_subs * 2)
        .endif
        bne :+
            brk ; Error state: too many subscribers
        :
        lda STACK_TOP+2, x
        sta subscribers, y
        iny
        lda STACK_TOP+1, x
        sta subscribers, y
        iny
        sty sub_count
        rts
    .endproc

    .proc MAKE_IDENT "%s_notify", evt_name
        push_registers
        lda #>AFTER_CALLS ; return to end of function after handler calls
        pha
        lda #<AFTER_CALLS
        pha
        ldx #0
        LOOP_START:
            cpx sub_count
            bne :+
                jmp LOOP_END
            :
            lda subscribers, x
            pha
            inx
            lda subscribers, x
            pha
            inx
            jmp LOOP_START
        LOOP_END:
        rts
        AFTER_CALLS:
        nop
        pull_registers
        rts
    .endproc
.endmacro

.macro make_event_header evt_name
    .global MAKE_IDENT "%s_init", evt_name
    .global MAKE_IDENT "%s_subscribe", evt_name
    .global MAKE_IDENT "%s_notify", evt_name
.endmacro

.endif