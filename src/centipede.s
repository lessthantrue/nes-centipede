.include "macros.inc"
.include "constants.inc"
.include "board.inc"
.include "centipede.inc"
.include "collision.inc"
.include "arrow.inc"

.struct centipede
    xcord       .byte
    ycord       .byte
    dir         .byte
    lastDir     .byte
    flags       .byte ; head, has_initialized_prev, alive, 
.endstruct

SEGMENT_FLAG_HEAD  = %10000000
SEGMENT_FLAG_INIT  = %01000000
SEGMENT_FLAG_ALIVE = %00100000

.macro segment_exit_not_alive
    lda #SEGMENT_FLAG_ALIVE
    bit map_elem+centipede::flags
    beq :+
        rts
    :
.endmacro

.segment "ZEROPAGE"

map_iter :      .res 1
map_elem :      .tag centipede
map_fn:         .res 2

STRUCTSIZE = centipede::flags+1

CENTIPEDE_LEN = 8
CENTIPEDE_INIT_X = $00
CENTIPEDE_INIT_Y = $00

centipede_segments  :   .res 1
segment_xs          :   .res CENTIPEDE_LEN
segment_ys          :   .res CENTIPEDE_LEN
segment_dirs        :   .res CENTIPEDE_LEN
segment_lastDirs    :   .res CENTIPEDE_LEN
segment_flags       :   .res CENTIPEDE_LEN

SEGMENT_WIDTH = 8

DIR_RIGHT =     %00000001
DIR_LEFT =      %00000010
DIR_DOWN =      %00000100

SPEED = 1

.segment "CODE"

.proc call_indirect
    jmp (map_fn) ; wierd hack
.endproc

.proc map_segment
    pha
    lda centipede_segments
    sta map_iter ; reset counter
    pla
    ldy #0 ; index
    :
        dec map_iter
        bmi :+

        ; copy current segment to temp variable
        lda segment_xs, y
        sta map_elem+centipede::xcord
        lda segment_ys, y
        sta map_elem+centipede::ycord
        lda segment_dirs, y
        sta map_elem+centipede::dir
        lda segment_lastDirs, y
        sta map_elem+centipede::lastDir
        lda segment_flags, y
        sta map_elem+centipede::flags

        ; call function
        tya
        pha ; preserve y register
        jsr call_indirect
        pla
        tay ; restore register

        ; save temp back to current segment
        lda map_elem+centipede::xcord
        sta segment_xs, y
        lda map_elem+centipede::ycord
        sta segment_ys, y
        lda map_elem+centipede::dir
        sta segment_dirs, y
        lda map_elem+centipede::lastDir
        sta segment_lastDirs, y
        lda map_elem+centipede::flags
        sta segment_flags, y

        ; move on 
        iny
        jmp :-
    :
    rts
.endproc

.proc centipede_init
    lda #0
    sta centipede_segments
    jsr centipede_init_segment
    rts
.endproc

.proc centipede_init_segment
    ldx centipede_segments
    cpx #CENTIPEDE_LEN
    bne init_segment
    rts
    init_segment:

    ; load a bunch of constants
    ldx centipede_segments
    lda #CENTIPEDE_INIT_X
    sta segment_xs, x
    lda #CENTIPEDE_INIT_Y
    sta segment_ys, x
    lda #DIR_RIGHT
    sta segment_dirs, x
    sta segment_lastDirs, x

    ; setting flags is a bit more involved
    lda #SEGMENT_FLAG_ALIVE
    ldy centipede_segments
    bne :+ ; not head
        ora #SEGMENT_FLAG_HEAD
    :
    cpy #CENTIPEDE_LEN
    bne :+ ; not tail
        ora #SEGMENT_FLAG_INIT
    :
    sta segment_flags, x
    inc centipede_segments
    rts
.endproc

.proc collide_segment
    lda map_elem+centipede::xcord
    and #$07
    bne done_collision
    lda map_elem+centipede::ycord
    and #$07
    bne done_collision
        ; first, check if we need to init another centipede segment
        lda #%01000000
        bit map_elem+centipede::flags
        bne :+ ; bit is set
        lda map_elem+centipede::xcord
        cmp #CENTIPEDE_INIT_X + 8
        bne :+ ; correct X position
        lda map_elem+centipede::ycord
        cmp #CENTIPEDE_INIT_Y
        bne :+ ; correct Y position
        ; clear init bit
        lda map_elem+centipede::flags
        ora #%01000000
        sta map_elem+centipede::flags
        jsr centipede_init_segment
        :
        ; on a grid position, do collision checks
        lda map_elem+centipede::dir
        cmp #DIR_DOWN
        bne not_down ; need special logic when moving down that doesn't involve collisions
            lda #%00000111
            bit map_elem+centipede::ycord
            bne done_collision ; only check on pixel multiples of 8
            ; set direction to inverted last direction
            lda map_elem+centipede::lastDir
            not
            and #%00000011
            sta map_elem+centipede::dir
            ; lastDir is only used in the down collision case, so we don't need to update it here
        not_down:
        ldx map_elem+centipede::xcord
        cmp #DIR_RIGHT
        beq right_collision
            ; check for left collision
            cpx #8
            bne mushroom_collision ; no wall collision here
            jmp lr_collision
        right_collision:
            ; check for right collision
            cpx #240
            bne mushroom_collision ; no wall collision here
            jmp lr_collision
        mushroom_collision:
            ldx map_elem+centipede::xcord
            ldy map_elem+centipede::ycord
            jsr board_convert_sprite_xy
            lda map_elem+centipede::dir
            cmp #DIR_RIGHT
            beq :+
                dex
                dex ; check one space to the left
            :
            inx ; check one space to the right
            jsr board_xy_to_addr
            jsr board_get_value
            cmp #0
            beq done_collision ; no mushroom -> no collision
        lr_collision:
            ; save last direction, set new direction to down
            lda map_elem+centipede::dir
            sta map_elem+centipede::lastDir
            lda #DIR_DOWN
            sta map_elem+centipede::dir
    done_collision:
    rts
.endproc

.proc move_segment
    lda map_elem+centipede::dir
    cmp #DIR_DOWN
    beq move_down
        cmp #DIR_LEFT
        php
        lda map_elem+centipede::xcord
        plp
        beq :+
        ; move right
            clc
            adc #SPEED
            adc #SPEED
        :
            ; move left
            sec
            sbc #SPEED
        sta map_elem+centipede::xcord
        jmp done_moving
    move_down:
        lda map_elem+centipede::ycord
        add #SPEED
        sta map_elem+centipede::ycord
    done_moving:
    rts
.endproc

.proc collide_arrow_segment
    lda #ARROW_FLAG_ACTIVE
    bit arrow_f
    beq no_collision ; no arrow -> no collision
    lda #SEGMENT_FLAG_ALIVE
    bit map_elem+centipede::flags
    bne :+
        jmp no_collision
    :
    lda map_elem+centipede::xcord
    sta collision_box1_l
    add #SEGMENT_WIDTH
    sta collision_box1_r
    lda map_elem+centipede::ycord
    sta collision_box1_t
    add #SEGMENT_WIDTH
    sta collision_box1_b
    jsr arrow_load_collision
    jsr collision_box1_contains
    lda collision_ret
    beq no_collision
        ; kill segment
        lda #SEGMENT_FLAG_ALIVE
        not
        and map_elem+centipede::flags
        sta map_elem+centipede::flags
        jsr arrow_del
        ; place mushroom where segment was
        ldx map_elem+centipede::xcord
        ldy map_elem+centipede::ycord
        jsr board_convert_sprite_xy
        jsr board_xy_to_addr
        jsr board_xy_to_nametable
        lda #$04
        jsr board_set_value
        jsr board_update_background
    no_collision:
    rts
.endproc

.proc centipede_step
    st_addr collide_arrow_segment, map_fn
    jsr map_segment
    st_addr collide_segment, map_fn
    jsr map_segment
    st_addr move_segment, map_fn
    jsr map_segment
    rts
.endproc

.proc draw_segment_sprite
    tya
    pha
    lda #SEGMENT_FLAG_ALIVE
    bit map_elem+centipede::flags
    bne :+
        ; no draw
        lda #$F0
        sta $020C, x
        sta $020D, x
        sta $020E, x
        sta $020F, x
        jmp done_draw
    :
        lda map_elem+centipede::ycord
        add #SPRITE_VERT_OFFSET ; re-align such that centipede zero equals top of board
        sta $020C, x ; y placement
        ; anchor sprite is $10 
        ; add 16 for downwards
        lda map_elem+centipede::dir
        cmp #DIR_DOWN
        beq :+
            lda #$10
            jmp :++
        :
            lda #$20
        :
        tay
        ; add 1 if head
        lda #SEGMENT_FLAG_HEAD
        bit map_elem+centipede::flags
        beq :+
            ; flag is set
            iny
        :
        tya
        sta $020D, x
        lda map_elem+centipede::dir
        and #%00000010
        asl a
        asl a
        asl a
        asl a
        asl a ; shift dir bits left 6 times, lines up perfectly with sprite mirroring
        sta $020E, x
        lda map_elem+centipede::xcord
        sta $020F, x ; x placement
    done_draw:
    inx
    inx
    inx
    inx ; add 4 to x
    pla
    tay
    rts
.endproc

.proc centipede_draw
    ldx #0
    st_addr draw_segment_sprite, map_fn
    jsr map_segment
    rts
.endproc