.include "core/macros.inc"
.include "core/eventprocessor.inc"
.include "board.inc"
.include "centipede.inc"
.include "collision.inc"
.include "arrow.inc"
.include "spritegfx.inc"
.include "segment.inc"
.include "events/events.inc"

.segment "ZEROPAGE"

map_iter :      .res 1
map_fn:         .res 2

centipede_segments  :   .res 1

.segment "BSS"
segment_xs          :   .res CENTIPEDE_LEN
segment_ys          :   .res CENTIPEDE_LEN
segment_dirs        :   .res CENTIPEDE_LEN
segment_flags       :   .res CENTIPEDE_LEN

.segment "CODE"

.proc map_segment
    ldy #0
    :
        cpy centipede_segments
        beq :+

        ; call function
        tya
        pha ; both preserve y through function calls AND set it as effective argument 1
        tsx
        lda #>after
        pha
        lda #<after
        sub #1
        pha
        lda map_fn+1
        pha
        lda map_fn
        sub #1
        pha 
        rts
        after:
        pla
        tay

        iny
        jmp :-
    :
    rts
.endproc

.proc centipede_init
    subscribe segment_kill, segment_kill_handler
    jsr centipede_reset
    rts
.endproc

.proc centipede_reset
    lda #0
    sta centipede_segments
    jsr segment_init
    rts
.endproc

.proc centipede_step
    st_addr segment_step, map_fn
    jsr map_segment
    rts
.endproc

.proc centipede_draw
    st_addr segment_draw, map_fn
    jsr map_segment
    rts
.endproc

.proc centipede_is_dead
    ldy #CENTIPEDE_LEN
    :
        dey
        lda #SEGMENT_FLAG_ALIVE
        and segment_flags, y
        bne NOT_DEAD
        cpy #0
        bne :-
    lda #1
    rts
    NOT_DEAD:
    lda #0
    rts
.endproc

.proc segment_kill_handler
    jsr centipede_is_dead
    cmp #0
    beq :+
        ; centipede is dead
        notify centipede_kill
    :
    rts
.endproc