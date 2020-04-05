
.include "arrow.inc"
.include "player.inc"
.include "board.inc"
.include "../spritegfx.inc"
.include "statusbar.inc"
.include "../events/events.inc"

.segment "BSS"
; Game variables
arrow_x:    .res 1
arrow_y:    .res 1
arrow_f:    .res 1

SPEED = 5 ; velocity in px/frame (everything will work as long as this is less than 8)

.segment "CODE"

.proc arrow_init
    lda #0
    sta arrow_f
    rts
.endproc

.proc arrow_launch
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    bne :+
        notify arrow_shoot
        lda player_yhi
        sta arrow_y
        lda player_xhi
        adc #2
        sta arrow_x
        lda arrow_f
        ora #ARROW_FLAG_ACTIVE
        sta arrow_f
    :
    ; arrow not active
    rts
.endproc

.proc arrow_step
    jsr arrow_collide
    jsr arrow_move
    rts
.endproc

.proc arrow_del
    lda #ARROW_FLAG_ACTIVE
    not
    and arrow_f
    sta arrow_f
    rts
.endproc

.proc arrow_move
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    beq :+
        ; arrow active
        lda arrow_y
        clc
        sbc #SPEED
        sta arrow_y
        bcs :+
            jsr arrow_del
    :
    rts
.endproc

.proc arrow_collide
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    beq no_collision
        call_with_args board_convert_sprite_xy, arrow_x, arrow_y
        jsr board_xy_to_addr
        jsr board_xy_to_nametable
        jsr board_get_value
        cmp #0
        beq no_collision ; no mushroom -> no collision
        ; collision -> "destroy" arrow, "damage" mushroom
        sub #1
        pha ; manual argument 1: new mushroom growth level
        and #$0F ; ignore poisoned bit for this next part
        bne mushroom_not_destroyed ; increment score if the mushroom was completely destroyed
            jsr board_get_value
            and #MUSHROOM_POISON_FLAG
            beq :+
                statusbar_add_score POISON_MUSHROOM_SCORE
                jmp :++
            :
                statusbar_add_score MUSHROOM_SCORE
            :
            call_with_args board_set_value, #0
            pla ; get rid of that extra variable we had
            jmp done_collision
        mushroom_not_destroyed:
            pla
            call_with_args board_set_value, a
        done_collision:

        jsr arrow_del
    no_collision:
    rts
.endproc

.proc arrow_draw
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    bne :+
        ; arrow inactive
        call_with_args spritegfx_load_oam, #OFFSCREEN, #$20, #0, #0
        jmp :++
    :
        ; arrow active
        call_with_args spritegfx_load_oam, arrow_y, #$20, #0, arrow_x
    :
    rts
.endproc
