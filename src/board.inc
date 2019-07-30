.ifndef BOARD_INC
.define BOARD_INC

.global board_init, board_xy_to_addr, board_draw, board_get_value, board_set_value
.global board_xy_to_nametable, board_update_background, board_convert_sprite_xy
.globalzp board_arg_x, board_arg_y

.endif