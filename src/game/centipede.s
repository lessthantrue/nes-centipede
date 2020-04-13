.include "../core/macros.inc"
.include "board.inc"
.include "centipede.inc"
.include "player.inc"
.include "game.inc"
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
segment_anims       :   .res CENTIPEDE_LEN

centipede_segments_alive:   .res 1

.segment "CODE"

.proc map_segment
    ldy #CENTIPEDE_LEN-1
    :
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
        sub #1
        pha 
        rts
        after:
        nop
        pla
        tay

        cpy #0
        beq :+
        dey
        jmp :-
    :
    rts
.endproc

.proc centipede_init
    subscribe level_up, level_up_handler-1
    subscribe segment_kill, segment_kill_handler-1
    lda #1
    sta centipede_speed
    jsr centipede_reset
    rts
.endproc

.proc centipede_reset
    lda #0
    sta centipede_segments
    lda #CENTIPEDE_LEN
    sta centipede_segments_alive
    jsr segment_init
    rts
.endproc

.proc centipede_step
    st_addr segment_step, map_fn
    jsr player_setup_collision
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
    dec centipede_segments_alive
    bne :+
        ; centipede is dead
        notify centipede_kill
        clear game_enemy_statuses, #FLAG_ENEMY_CENTIPEDE
    :
    lda centipede_segments_alive
    cmp #1
    bne :+
        lda #2
        sta centipede_speed
    :
    rts
.endproc

.proc level_up_handler
    lda statusbar_level
    and #%00000001
    add #1
    sta centipede_speed
.endproc
