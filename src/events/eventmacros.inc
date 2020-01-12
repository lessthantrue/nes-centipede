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
        ldx #0
        LOOP_START:
            cpx sub_count
            beq LOOP_END
            txa
            pha ; preserve x
            lda #>AFTER_CALL ; return to loop start after function call
            pha
            lda #(<AFTER_CALL-1)
            pha
            lda subscribers, x
            pha
            inx
            lda subscribers, x
            sub #1
            pha
            rts ; get to work
            AFTER_CALL:
            pla
            tax ; restore x
            inx
            inx ; move to next address
            jmp LOOP_START
        LOOP_END:
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