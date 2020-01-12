.ifndef SPIDER_INC
SPIDER_INC = 1

.global spider_step, spider_init, spider_draw
.global spider_f

SPIDER_FLAG_LEFT    = %00000001 ; set if the spider started on the left side and is going right
SPIDER_FLAG_ALIVE   = %00000010
SPIDER_FLAG_HORIZ   = %00000100 ; set if the spider is moving diagonally
SPIDER_FLAG_VERT    = %00001000 ; set if the spider is moving up

.endif