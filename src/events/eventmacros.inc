.ifndef EVENT_MACROS_INC
EVENT_MACROS_INC = 1

.include "../core/macros.inc"
.include "../core/6502.inc"

.macro make_event evt_name, sub_count

    .ifblank sub_count
        .define NUM_SUBS 3
    .else
        .define NUM_SUBS sub_count
    .endif

    ; basically the whole file
    .segment "BSS"
    subscribers:        .res NUM_SUBS * 2
    subscriber_count:   .res 1

    .segment "CODE"

    .proc .ident(.sprintf("%s_init", .string(evt_name)))
        lda #0
        sta subscriber_count
        rts
    .endproc

    .proc .ident(.sprintf("%s_subscribe", .string(evt_name)))
        ; look for the first zero address
        ldy subscriber_count
        cpy #(NUM_SUBS * 2)
        bne :+
            brk ; Error state: too many subscribers
        :
        lda STACK_TOP+2, x
        sta subscribers, y
        iny
        lda STACK_TOP+1, x
        sta subscribers, y
        iny
        sty subscriber_count
        rts
    .endproc

    .proc .ident(.sprintf("%s_notify", .string(evt_name)))
        push_registers
        ldx #0
        LOOP_START:
            cpx subscriber_count
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
    .global .ident(.sprintf("%s_notify", .string(evt_name)))
    .global .ident(.sprintf("%s_subscribe", .string(evt_name)))
    .global .ident(.sprintf("%s_init", .string(evt_name)))
.endmacro

.endif