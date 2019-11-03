.include "gamestate.inc"
.include "global.inc"
.include "nes.inc"

.segment "BSS"
score:      .res 2
lives:      .res 1

; 100 points per centipede segment killed
; 1 point per mushroom killed
; 5 points per poison mushroom killed
; 200 points per flea killed
; 600/900 points per spider killed, depending on proximity
; 1000 points per scorpion
SEGMENT_KILL_SCORE = 100
MUSHROOM_KILL_SCORE = 1
POISON_MUSHROOM_KILL_SCORE = 5
FLEA_KILL_SCORE = 100
SPIDER_FAR_KILL_SCORE = 600
SPIDER_NEAR_KILL_SCORE = 900
SCORPION_KILL_SCORE = 1000


