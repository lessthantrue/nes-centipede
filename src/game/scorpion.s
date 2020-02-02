.include "../core/macros.inc"
.include "game.inc"
.include "scorpion.inc"
.include "../spritegfx.inc"
.include "../random.inc"
.include "../collision.inc"

.segment "BSS"
scorp_xlo:      .res 1
scorp_xhi:      .res 1
scorp_y:        .res 1
scorp_f:        .res 1

scorp_respawn_timer:    .res 2

SCORP_FLAG_ALIVE = %00000001
SCORP_FLAG_LEFT = %00000010 ; started left
SCORP_ANIM_MASK = %11000000 ; last 4 bits are reserved
SCORP_ANIM_STEP = %00001000 ; for animation though
SCORP_SPEED_SLOW = 196 ; add to low

SCORP_INIT_X_LEFT = 8
SCORP_INIT_X_RIGHT = 239

.segment "CODE"

.proc scorp_init
    lda #0
    sta scorp_xlo
    sta scorp_xhi
    sta scorp_f
    jsr scorp_set_respawn_time
    lda #OFFSCREEN
    sta scorp_y
    rts
.endproc

; same thing as spider
.proc scorp_set_respawn_time
    jsr rand8
    and #$01
    add #3 ; 8 to 12 seconds
    sta scorp_respawn_timer+1
    lda #00
    sta scorp_respawn_timer
    rts
.endproc

.proc scorp_reset
    ; flags (left randomly, active always)
    jsr rand8
    and #SCORP_FLAG_LEFT
    ora #SCORP_FLAG_ALIVE
    sta scorp_f
    
    ; X
    ldx #SCORP_INIT_X_LEFT
    and #SCORP_FLAG_LEFT
    bne :+
        ; scorpion started right
        ldx #SCORP_INIT_X_RIGHT
    :
    stx scorp_xhi

    ; select a random y from 3 to 19
    jsr rand8
    and #%00001111
    add #3
    asl 
    asl
    asl ; shift 3 times to align to 8
    sta scorp_y

    jsr scorp_set_respawn_time
    rts
.endproc

.proc scorp_move
    lda #SCORP_FLAG_LEFT
    bit scorp_f
    bne GOING_RIGHT
        ; scorpion started right, going left
        lda scorp_xlo
        sub #SCORP_SPEED_SLOW
        sta scorp_xlo
        lda scorp_xhi
        sbc #0
        cmp #SCORP_INIT_X_LEFT
        bcs :+
            jsr scorp_init
        jmp DONE_MOVE
    GOING_RIGHT:
        lda scorp_xlo
        add #SCORP_SPEED_SLOW
        sta scorp_xlo
        lda scorp_xhi
        adc #0
        cmp #SCORP_INIT_X_RIGHT
        bcc :+
            jsr scorp_init
        :
    DONE_MOVE:
    sta scorp_xhi


    lda scorp_f
    add #SCORP_ANIM_STEP
    sta scorp_f
    rts
.endproc

.proc scorp_draw
    ; arg 4: sprite x
    push scorp_xhi

    ; arg 3: sprite flags
    lda scorp_f
    and #SCORP_FLAG_LEFT
    .repeat 5 ; horizontal flip is bit 7
        asl
    .endrep
    pha

    ; arg 2: tile index
    lda scorp_f
    and #SCORP_ANIM_MASK
    .repeat 5
        lsr
    .endrep
    add #$70
    pha

    ; arg 1: sprite y
    push scorp_y

    call_with_args_manual spritegfx_load_oam, 4

    lda #SCORP_FLAG_LEFT
    bit scorp_f
    bne :+
        ; started right, going left
        lda scorp_xhi
        add #8
        jmp :++
    :
        lda scorp_xhi
        sub #8
    :
    pha

    lda scorp_f
    and #SCORP_FLAG_LEFT
    .repeat 5 ; horizontal flip is bit 7
        asl
    .endrep
    pha

    lda scorp_f
    and #SCORP_ANIM_MASK
    .repeat 5
        lsr
    .endrep
    add #$71
    pha

    push scorp_y

    call_with_args_manual spritegfx_load_oam, 4

    rts
.endproc

.proc scorp_collide_arrow
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    bne :+
        jmp END_COLLISION
    :
    lda scorp_xhi
    cmp #8
    bcc END_COLLISION
    lda #SCORP_FLAG_LEFT
    
    lda scorp_xhi
    sub #8
    sta collision_box1_l
    add #16
    sta collision_box1_r

    lda scorp_y
    sta collision_box1_t
    add #8
    sta collision_box1_b
    
    call_with_args collision_box1_contains, arrow_x, arrow_y
    lda collision_ret
    beq END_COLLISION
        ; arrow hit
        statusbar_add_score SCORPION_SCORE
        call_with_args particle_add, scorp_xhi, scorp_y
        jsr arrow_del
        jsr scorp_init
    END_COLLISION:
    rts
.endproc

.proc scorp_collide_board
    lda scorp_xhi
    and #$07
    ; only do this every 8 pixels (1 grid space)
    beq :+
        rts
    :

    call_with_args board_convert_sprite_xy, scorp_xhi, scorp_y
    jsr board_xy_to_addr
    jsr board_get_value
    cmp #0
    beq :+
        ; found a mushroom
        ora #MUSHROOM_POISON_FLAG
        jsr board_xy_to_nametable
        call_with_args board_set_value, a
    :
    rts
.endproc

.proc scorp_step
    lda #SCORP_FLAG_ALIVE
    bit scorp_f
    bne :++
        ; scorpion not alive
        lda scorp_respawn_timer
        sub #1
        sta scorp_respawn_timer
        lda scorp_respawn_timer+1
        sbc #0
        sta scorp_respawn_timer+1
        bne :+
            jsr scorp_reset
        :
        rts
    :

    jsr scorp_move
    jsr scorp_collide_board
    jsr scorp_collide_arrow
    rts
.endproc