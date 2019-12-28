.ifndef SEGMENT_INC
.define SEGMENT_INC

.struct segment
    xcord       .byte
    ycord       .byte
    dir         .byte
    flags       .byte
.endstruct

SEGMENT_FLAG_INIT           = %01000000
SEGMENT_FLAG_ALIVE          = %00100000
SEGMENT_FLAG_HEAD           = %00010000
SEGMENT_MASK_ANIM_OFFSET    = %00000011 

.globalzp segment_active

.global segment_init, segment_draw, segment_step

.endif