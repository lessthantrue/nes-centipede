.ifndef CENTIPEDE_INC
CENTIPEDE_INC = 1

.global centipede_init, centipede_reset, centipede_step, centipede_draw
.global segment_xs, segment_ys, segment_flags, segment_dirs
.globalzp centipede_segments, centipede_speed

CENTIPEDE_LEN = 8
CENTIPEDE_INIT_X = $00
CENTIPEDE_INIT_Y = $00

.endif