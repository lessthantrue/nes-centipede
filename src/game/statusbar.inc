.ifndef STATUSBAR_INC
STATUSBAR_INC = 1

.include "../core/macros.inc"

.global statusbar_init, statusbar_addscore, statusbar_dec_lives
.global statusbar_draw_score, statusbar_draw_lives, statusbar_draw_highscore
.globalzp statusbar_level, score

SEGMENT_SCORE = 10
HEAD_SCORE = 100
MUSHROOM_SCORE = 1
POISON_MUSHROOM_SCORE = 5
FLEA_SCORE = 100
SPIDER_FAR_SCORE = 300
SPIDER_MID_SCORE = 600
SPIDER_NEAR_SCORE = 900
SCORPION_SCORE = 1000

.macro statusbar_add_score score_value
    call_with_args statusbar_addscore, #<score_value, #>score_value
.endmacro

.endif