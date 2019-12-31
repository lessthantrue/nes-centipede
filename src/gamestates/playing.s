.include "playing.inc"
.include "../arrow.inc"
.include "../player.inc"
.include "../centipede.inc"
.include "../board.inc"
.include "../statusbar.inc"
.include "../nes.inc"

.segment "CODE"

.proc state_playing_logic
    jsr player_move
    jsr arrow_step
    jsr player_setup_collision
    jsr centipede_step
    jsr centipede_draw
    jsr player_draw
    jsr arrow_draw
    jsr statusbar_draw_lives
    rts
.endproc

.proc state_playing_bg
  jsr board_update_background
  lda PPUSTATUS
  jsr statusbar_draw_score
  rts
.endproc

.proc state_playing_transition
    rts
.endproc