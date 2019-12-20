.ifndef CENTIPEDE_INC
.define CENTIPEDE_INC

.global centipede_init, centipede_step, centipede_draw
.global segment_xs, segment_ys, segment_flags, segment_dirs
.globalzp centipede_segments

CENTIPEDE_LEN = 8
CENTIPEDE_INIT_X = $10
CENTIPEDE_INIT_Y = $10
SPEED = 1

.endif