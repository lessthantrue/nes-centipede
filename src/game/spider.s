.include "spider.inc"
.include "../spritegfx.inc"
.include "../core/macros.inc"
.include "../random.inc"

; Spider : These appear from the top left or right of the player 
; area. They will either bounce across the player's area at 
; 45-degree angles or bounce in at a 45-degree angle, bounce up 
; and down a couple of times, go to the middle at a 45-degree angle,
; bounce up and down a couple of times, then finally go to the 
; right side (at a 45-degree angle), bounce up and down, then exit
;  the area. They destroy mushrooms they cross over.

.segment "BSS"
spider_x:   .res 1
spider_y:   .res 1
spider_f:   .res 1 ; flags as defined below

SPIDER_INIT_X_LEFT = 0
SPIDER_INIT_X_RIGHT = 255
SPIDER_INIT_Y = 200

SPIDER_FLAG_LEFT    = %00000001 ; set if the spider started on the left side and is going right
SPIDER_FLAG_ALIVE   = %00000010
SPIDER_FLAG_HORIZ   = %00000100 ; set if the spider is moving diagonally
SPIDER_FLAG_VERT    = %00001000 ; set if the spider is moving up

SPIDER_BOUNDS_TOP = 190
SPIDER_BOUNDS_BOT = 230

SPIDER_SPEED = 2

.segment "CODE"

.proc spider_init
    jsr rand8
    and #SPIDER_FLAG_LEFT ; this bit is randomly set
    ora #SPIDER_FLAG_ALIVE|SPIDER_FLAG_HORIZ
    sta spider_f
    and #SPIDER_FLAG_LEFT
    beq start_right
        ; starting left
        lda #SPIDER_INIT_X_LEFT
        jmp done_init_lr
    start_right:
        lda #SPIDER_INIT_X_RIGHT
    done_init_lr:
    sta spider_x
    lda #SPIDER_INIT_Y
    sta spider_y
    rts
.endproc

.proc spider_move
    ; vertical
    lda #SPIDER_FLAG_VERT
    bit spider_f
    beq :+
        ; spider moving down
        lda spider_y
        add #SPIDER_SPEED
        jmp done_move_vert
    :
        ; spider moving up
        lda spider_y
        sub #SPIDER_SPEED
    done_move_vert:
    sta spider_y

    ; horizontal
    lda #SPIDER_FLAG_HORIZ|SPIDER_FLAG_LEFT
    and spider_f
    cmp #SPIDER_FLAG_HORIZ|SPIDER_FLAG_LEFT
    bne :+
        ; spider started left and is moving right
        lda spider_x
        add #SPIDER_SPEED
        sta spider_x
        jmp done_move_horiz
    :
    lda #SPIDER_FLAG_HORIZ
    and spider_f
    beq :+
        ; spider started right and is moving left
        lda spider_x
        sub #SPIDER_SPEED
        sta spider_x
    done_move_horiz:
    rts
.endproc

.proc spider_collide_walls
    lda spider_y
    cmp #SPIDER_BOUNDS_TOP
    bcs :+
        ; top collision. Spider needs to start moving down, so clear the vert bit
        lda spider_f
        and #(256-SPIDER_FLAG_VERT)
        sta spider_f
    :

    lda spider_y
    cmp #SPIDER_BOUNDS_BOT
    bcc :+
        ; bottom collision. Spider needs to start moving up, so set the vert bit
        lda spider_f
        ora #SPIDER_FLAG_VERT
        sta spider_f
    :

    rts
.endproc

.proc spider_draw
    lda #SPIDER_FLAG_ALIVE
    bit spider_f
    bne :+
        call_with_args spritegfx_load_oam, #OFFSCREEN, #$20, #0, #0
        call_with_args spritegfx_load_oam, #OFFSCREEN, #$20, #0, #0
        rts
    :
    lda spider_x
    call_with_args spritegfx_load_oam, spider_y, #$20, #0, a
    sub #8
    call_with_args spritegfx_load_oam, spider_y, #$20, #0, a
    rts
.endproc

.proc spider_step
    lda #SPIDER_FLAG_ALIVE
    bit spider_f
    bne :+
        ; spider not alive
        rts
    :

    jsr spider_move
    jsr spider_collide_walls
    rts
.endproc