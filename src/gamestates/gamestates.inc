.ifndef GAMESTATES_INC
GAMESTATES_INC = 1

.include "dead.inc"
.include "gameover.inc"
.include "menu.inc"
.include "nextlevel.inc"
.include "play_init.inc"
.include "playing.inc"

.include "../gamestaterunner.inc"

.macro swap_state next_state
    st_addr (MAKE_IDENT "state_%s_logic", next_state), gamestaterunner_logicfn
    st_addr (MAKE_IDENT "state_%s_bg", next_state), gamestaterunner_bgfn
    st_addr (MAKE_IDENT "state_%s_transition", next_state), gamestaterunner_transitionfn
.endmacro

.endif