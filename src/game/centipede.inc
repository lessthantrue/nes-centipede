.ifndef CENTIPEDE_INC
.define CENTIPEDE_INC

.global centipede_init, centipede_reset, centipede_step, centipede_draw
.global segment_xs, segment_ys, segment_flags, segment_dirs, segment_oams
.globalzp centipede_segments, centipede_speed

CENTIPEDE_LEN = 8
CENTIPEDE_INIT_X = $00
CENTIPEDE_INIT_Y = $00

.endif