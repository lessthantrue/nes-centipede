.ifndef SPRITEGFX_INC
SPRITEGFX_INC = 1

.struct oam
    ycord   .byte
    tile    .byte
    flags   .byte
    xcord   .byte
.endstruct

.globalzp spritegfx_oam_arg
.global spritegfx_load_oam, spritegfx_reset
SPRITE_VERT_OFFSET = 23
OFFSCREEN = 217

.endif