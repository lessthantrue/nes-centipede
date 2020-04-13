.include "game.inc"

.segment "CODE"

; just move to where the next segment was in the previous time step
.proc body_step_tile
    ; get segment at y-1 (closer to head) x and y in x and a registers
    dey
    lda segment_dirs, y

    ; put them in the current segment (at y)
    iny
    sta segment_dirs, y
    rts
.endproc

.proc body_step
    lda segment_dirs, y
    and #DIR_DOWN
    beq :++
        ; turn back to finish diagonal movement if y value is 4 more than a multiple of 8
        lda segment_ys, y
        and #$07
        cmp #4
        bne :+
            ; change directions
            lda segment_dirs, y
            eor #%00000001 ; swap last bit
            sta segment_dirs, y
        :

        ; finish moving down
        lda segment_ys, y
        add centipede_speed_temp
        sta segment_ys, y
    :
    lda segment_dirs, y
    and #DIR_RIGHT
    php ; because lda changes zero flag
    lda segment_xs, y
    plp
    bne :+
    ; move left
        sub centipede_speed_temp
        sub centipede_speed_temp
    :
        ; move right
        add centipede_speed_temp
    sta segment_xs, y
    rts
.endproc