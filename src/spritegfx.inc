.ifndef SPRITEGFX_INC
.define SPRITEGFX_INC

.struct oam
    ycord   .byte
    tile    .byte
    flags   .byte
    xcord   .byte
.endstruct

.global oam_init, oam_alloc, oam_free
SPRITE_VERT_OFFSET = 23
OFFSCREEN = 217

.endif