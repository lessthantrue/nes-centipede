.include "playerdead.inc"
.include "../core/6502.inc"
.include "../core/macros.inc"

.segment "BSS"
NUM_SUBS = 6
subscribers:    .addr $0000, $0000, $0000, $0000, $0000, $0000
subscriber_count:   .byte $0

.segment "CODE"

.proc player_dead_init
    ldy #(NUM_SUBS * 2)
    lda #0
    :
        dey
        sta subscribers, y
        bne :-
    sta subscriber_count
    rts
.endproc

; argument 1: high byte of subscriber address
; argument 2: low byte of subscriber address
.proc player_dead_subscribe
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

; calls all subscribers, notifying a player death
.proc player_dead_notify
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
    rts
.endproc

