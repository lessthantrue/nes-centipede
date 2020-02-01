.ifndef GAME_INC
GAME_INC = 1

.include "spider.inc"
.include "segment.inc"
.include "player.inc"
.include "arrow.inc"
.include "centipede.inc"
.include "board.inc"
.include "statusbar.inc"
.include "particles.inc"
.include "scorpion.inc"
.include "scoreparticle.inc"

.global game_step, game_init, game_bg, game_level_reset
.global game_full_reset, menu_step, game_init_bg, game_draw

.endif