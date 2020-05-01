.ifndef HIGHSCORES_INC
HIGHSCORES_INC = 1

.global highscores, highscore_hard_reset, highscores_sort, highscores_sorted

; high score save format:
; 3 bytes for initials
; 3 bytes for score
; 8 bytes for score in decimal
; 1 byte for "sorted" flag
; 1 byte of padding

SCORES_COUNT = 8
SCORE_SIZE = 3 + 3 + 8 + 2

.endif