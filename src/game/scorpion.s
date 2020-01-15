.include "../core/macros.inc"
.include "game.inc"
.include "scorpion.inc"
.include "../spritegfx.inc"
.include "../random.inc"

.segment "BSS"
scorp_x:        .res 1
scorp_y:        .res 1
scorp_delay:    .res 2
scorp_f:        .res 1

SCORP_FLAG_ALIVE = %00000001
SCORP_FLAG_LEFT = %00000010 ; started left
SCORP_ANIM_MASK = %11000000 ; last 4 bits are reserved
SCORP_ANIM_STEP = %00001000 ; for animation though
SCORP_SPEED = 1

SCORP_INIT_X_LEFT = 8
SCORP_INIT_X_RIGHT = 239

.segment "CODE"

.proc scorp_init
    lda #0
    sta scorp_x
    sta scorp_y
    sta scorp_f
    sta scorp_delay
    sta scorp_delay+1
    rts
.endproc

.proc scorp_reset
    ; flags (left randomly, active always)
    jsr rand8
    and #SCORP_FLAG_LEFT
    ora #SCORP_FLAG_ALIVE
    
    ; X
    ldx #SCORP_INIT_X_LEFT
    and #SCORP_FLAG_LEFT
    bne :+
        ; scorpion started right
        ldx #SCORP_INIT_X_RIGHT
    :
    stx scorp_x

    ; select a random y from 3 to 19
    jsr rand8
    and #%00001111
    add #3
    asl 
    asl
    asl ; shift 3 times to align to 8
    sta scorp_y

    rts
.endproc

.proc scorp_move
    lda #SCORP_FLAG_LEFT
    bit scorp_f
    bne :+
        ; scorpion started right, going left
        lda scorp_x
        sub #SCORP_SPEED
        jmp :++
    :
        lda scorp_x
        add #SCORP_SPEED
    :
    sta scorp_x

    lda scorp_f
    add #SCORP_ANIM_STEP
    sta scorp_f
.endproc

.proc scorp_draw
    ; arg 4: sprite x
    push scorp_x

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
        lda scorp_x
        add #8
        jmp :++
    :
        lda scorp_x
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