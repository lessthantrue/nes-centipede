.ifndef SEGMENT_INC
SEGMENT_INC = 1

.struct segment
    xcord       .byte
    ycord       .byte
    dir         .byte
    flags       .byte
    anim        .byte ; animation state
.endstruct

SEGMENT_FLAG_INIT           = %00000001
SEGMENT_FLAG_ALIVE          = %00000010
SEGMENT_FLAG_POISON         = %00000100
SEGMENT_FLAG_HEAD           = %00010000
SEGMENT_FLAG_UP             = %00100000
SEGMENT_FLAG_COLLIDE        = %01000000
SEGMENT_FLAG_COLLIDE_PREV   = %10000000

SEGMENT_MASK_ANIM_OFFSET    = %11000000 

.globalzp segment_active

.global segment_init, segment_draw, segment_step

.endif