.include "collision.inc"

.segment "ZEROPAGE"

; left, right, top, bottom of two bounding boxes
collision_box1_l:     .res 1
collision_box1_r:     .res 1
collision_box1_t:     .res 1 ; t < b (graphical top)
collision_box1_b:     .res 1

collision_box2_l:     .res 1
collision_box2_r:     .res 1
collision_box2_t:     .res 1
collision_box2_b:     .res 1

collision_ret:        .res 1

.segment "CODE"

; checks if the 2 bounding boxes overlap
.proc collision_box_overlap
    lda #$0
    sta collision_ret
    lda collision_box1_l
    cmp collision_box2_r
    bcc lr_overlap
    lda collision_box1_r
    cmp collision_box2_l
    bcs lr_overlap
    jmp no_overlap
    lr_overlap:
    lda collision_box1_t
    cmp collision_box2_b
    bcc tb_overlap
    lda collision_box1_b
    cmp collision_box2_t
    bcs tb_overlap
    jmp no_overlap
    tb_overlap:
        ; definitely overlap
        lda #$1
        sta collision_ret
    no_overlap:
    rts
.endproc

; checks if a point (xy) is within bounding box 1
.proc collision_box1_contains
    lda #$0
    sta collision_ret
    cpx collision_box1_l
    bcc not_inside
    cpx collision_box1_r
    bcs not_inside
    cpy collision_box1_t
    bcc not_inside
    cpy collision_box1_b
    bcs not_inside
        lda #$1
        sta collision_ret
    not_inside:
    rts
.endproc
