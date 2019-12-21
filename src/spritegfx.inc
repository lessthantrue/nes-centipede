.ifndef SPRITEGFX_INC
.define SPRITEGFX_INC

.struct oam
    ycord   .byte
    tile    .byte
    flags   .byte
    xcord   .byte
.endstruct

.globalzp spritegfx_oam_arg
.global spritegfx_load_oam, spritegfx_reset
SPRITE_VERT_OFFSET = 23

.endif