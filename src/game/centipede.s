.include "../core/macros.inc"
.include "../core/eventprocessor.inc"
.include "board.inc"
.include "centipede.inc"
.include "player.inc"
.include "../collision.inc"
.include "arrow.inc"
.include "../spritegfx.inc"
.include "segment.inc"
.include "../events/events.inc"

.segment "ZEROPAGE"

map_iter :      .res 1
map_fn:         .res 2

centipede_segments      :   .res 1
centipede_speed         :   .res 1

.segment "BSS"
segment_xs          :   .res CENTIPEDE_LEN
segment_ys          :   .res CENTIPEDE_LEN
segment_dirs        :   .res CENTIPEDE_LEN
segment_flags       :   .res CENTIPEDE_LEN
segment_oams        :   .res CENTIPEDE_LEN

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
        pha
        lda map_fn+1
        pha
        lda map_fn
        pha 
        rts
        after:
        nop
        pla
        tay

        iny
        jmp :-
    :
    rts
.endproc

.proc centipede_init
    subscribe level_up, level_up_handler
    subscribe segment_kill, segment_kill_handler
    lda #1
    sta centipede_speed
    jsr centipede_reset
    rts
.endproc

.proc centipede_reset
    ; zero flags and free OAMs
    ldx #CENTIPEDE_LEN
    :
        dex
        lda segment_flags, x
        and #SEGMENT_FLAG_ALIVE
        beq NOT_ALIVE
            ; is alive, so free OAM
            ldy segment_oams, x
            txa
            pha
            jsr oam_free
            pla
            tax
        NOT_ALIVE:
        lda #0
        sta segment_flags, x
        cpx #0
        bne :-
    ; 0 segments active, restart walk
    stx centipede_segments
    jsr segment_init
    rts
.endproc

.proc centipede_step
    st_addr segment_step, map_fn
    dec_16 map_fn
    jsr player_setup_collision
    jsr map_segment
    rts
.endproc

.proc centipede_draw
    st_addr segment_draw, map_fn
    dec_16 map_fn
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

.proc level_up_handler
    lda centipede_speed
    and #%00000001
    add #1
    sta centipede_speed
.endproc
