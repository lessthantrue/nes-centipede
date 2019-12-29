.ifndef GAMESTATE_INC
.define GAMESTATE_INC

.include "core/macros.inc"

.global gamestate_init, gamestate_addscore, gamestate_dec_lives, gamestate_draw

SEGMENT_SCORE = 100
MUSHROOM_SCORE = 1
POISON_MUSHROOM_SCORE = 5
FLEA_SCORE = 100
SPIDER_FAR_SCORE = 600
SPIDER_NEAR_SCORE = 900
SCORPION_SCORE = 1000

.macro gamestate_add_score score_value
    call_with_args gamestate_addscore, #<score_value, #>score_value
.endmacro

.endif