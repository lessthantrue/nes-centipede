.include "playing.inc"
.include "../arrow.inc"
.include "../player.inc"
.include "../centipede.inc"
.include "../board.inc"
.include "../statusbar.inc"
.include "../nes.inc"
.include "dead.inc"
.include "../gamestaterunner.inc"

.segment "BSS"
player_dead_flag: .byte $00

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
    lda player_dead_flag
    bne :+
        rts ; player not dead
    :
    ; player died
    st_addr state_dead_logic, gamestaterunner_logicfn
    st_addr state_dead_bg, gamestaterunner_bgfn
    st_addr state_dead_transition, gamestaterunner_transitionfn
    lda #0
    sta player_dead_flag
    rts 
.endproc

.proc state_playing_player_dead_handler
    lda #1
    sta player_dead_flag
    rts
.endproc