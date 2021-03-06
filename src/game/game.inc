.ifndef GAME_INC
GAME_INC = 1

.include "spider.inc"
.include "segment.inc"
.include "head.inc"
.include "body.inc"
.include "player.inc"
.include "arrow.inc"
.include "centipede.inc"
.include "board.inc"
.include "statusbar.inc"
.include "particles.inc"
.include "scorpion.inc"
.include "scoreparticle.inc"
.include "flea.inc"

.global game_step, game_init, game_bg, game_level_reset
.global game_full_reset, menu_step, game_init_bg, game_draw, game_redraw_bg
.globalzp game_enemy_statuses

FLAG_ENEMY_CENTIPEDE    = %00000001
FLAG_ENEMY_SCORPION     = %00000010
FLAG_ENEMY_SPIDER       = %00000100
FLAG_ENEMY_FLEA         = %00001000
FLAG_PLAYER             = %00010000

.endif