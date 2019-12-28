.include "core/macros.inc"
.include "core/eventprocessor.inc"
.include "board.inc"
.include "centipede.inc"
.include "collision.inc"
.include "arrow.inc"
.include "spritegfx.inc"
.include "segment.inc"

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
        ; copy current segment to temp variable
        lda segment_xs, y
        sta segment_active+segment::xcord
        lda segment_ys, y
        sta segment_active+segment::ycord
        lda segment_dirs, y
        sta segment_active+segment::dir
        lda segment_flags, y
        sta segment_active+segment::flags

        ; call function
        tya
        pha
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

        ; save temp back to current segment
        lda segment_active+segment::xcord
        sta segment_xs, y
        lda segment_active+segment::ycord
        sta segment_ys, y
        lda segment_active+segment::dir
        sta segment_dirs, y
        lda segment_active+segment::flags
        sta segment_flags, y

        iny
        jmp :-
    :
    rts
.endproc

.proc centipede_init
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
    ldx #0
    st_addr segment_draw, map_fn
    jsr map_segment
    rts
.endproc
