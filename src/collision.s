.include "collision.inc"
.include "core/6502.inc"

.segment "ZEROPAGE"

; left, right, top, bottom of two bounding boxes
collision_box1_l:     .res 1
collision_box1_r:     .res 1 ; l < r
collision_box1_t:     .res 1 ; t < b (graphical top)
collision_box1_b:     .res 1

collision_box2_l:     .res 1
collision_box2_r:     .res 1
collision_box2_t:     .res 1
collision_box2_b:     .res 1

collision_ret:        .res 1 ; 1 if there was a collision

.segment "CODE"

; checks if the 2 bounding boxes overlap
.proc collision_box_overlap
    lda #$0
    sta collision_ret
    lda collision_box1_l
    cmp collision_box2_r
    bcs no_collision ; 1.l >= 2.r
    lda collision_box2_l
    cmp collision_box1_r
    bcs no_collision ; 2.l >= 1.r
    lda collision_box1_t
    cmp collision_box2_b
    bcs no_collision ; 1.t >= 2.b
    lda collision_box2_t
    cmp collision_box1_b
    bcs no_collision ; 2.t >= 1.b
        lda #1
        sta collision_ret
    no_collision:
    rts
.endproc

; checks if a point (xy) is within bounding box 1
; arg 1: x coordinate
; arg 2: y coordinate
.proc collision_box1_contains
    lda #$0
    sta collision_ret
    lda STACK_TOP+1, x
    cmp collision_box1_l
    bcc not_inside
    cmp collision_box1_r
    bcs not_inside
    lda STACK_TOP+2, x
    cmp collision_box1_t
    bcc not_inside
    cmp collision_box1_b
    bcs not_inside
        lda #$1
        sta collision_ret
    not_inside:
    rts
.endproc
