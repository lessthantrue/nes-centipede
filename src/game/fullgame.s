.include "game.inc"
.include "../sound.inc"

.segment "CODE"

; scorpion only if level 3+
SCORPION_LEVEL_ENABLE = 0

.proc game_step
    ; logic
    jsr player_move
    jsr arrow_step
    jsr centipede_step
    jsr spider_step

    ; only step the scorpion if we're past a level count
    lda statusbar_level
    cmp #SCORPION_LEVEL_ENABLE
    bcc :+
        jsr scorp_step
    :

    jsr game_draw

    ; audio
    jsr sound_run_default

    rts
.endproc

.proc game_draw
    jsr player_draw
    jsr arrow_draw
    jsr spider_draw
    jsr centipede_draw
    jsr statusbar_draw_lives
    jsr particle_draw
    jsr scorp_draw
    rts
.endproc

.proc menu_step
    ; logic
    jsr centipede_step

    ; drawing
    jsr centipede_draw

    rts
.endproc

.proc game_bg
    jsr board_update_background
    jsr statusbar_draw_score
    rts
.endproc

.proc game_init
    jsr player_init
    jsr centipede_init
    jsr arrow_init
    jsr statusbar_init
    jsr sound_init
    jsr spider_init
    jsr particles_init
    jsr scorp_init
    rts
.endproc

.proc game_init_bg
    jsr board_init
    jsr board_draw
    rts
.endproc

.proc game_level_reset
    jsr sound_reset
    jsr centipede_reset
    jsr spider_init
    rts
.endproc

.proc game_full_reset
    jsr centipede_reset
    jsr statusbar_init
    jsr player_init
    jsr arrow_init
    jsr spider_init
    rts
.endproc