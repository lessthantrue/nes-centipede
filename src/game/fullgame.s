.include "game.inc"
.include "../sound.inc"
.include "../events/events.inc"

.segment "ZEROPAGE"

game_enemy_statuses:    .res 1

.segment "CODE"

; scorpion only if level 3+
SCORPION_LEVEL_ENABLE = 3
FLEA_LEVEL_ENABLE = 2

.proc game_step
    ; logic
    jsr player_move
    jsr arrow_step
    jsr centipede_step
    jsr spider_step
    jsr flea_step

    ; only step the scorpion if we're past a level count
    lda statusbar_level
    cmp #SCORPION_LEVEL_ENABLE-1
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
    jsr flea_draw
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
    jsr flea_init

    subscribe player_dead, game_player_dead_handler-1

    rts
.endproc

.proc game_init_bg
    jsr board_init
    jsr board_draw
    rts
.endproc

.proc game_level_reset
    jsr centipede_reset
    jsr spider_init
    jsr scorp_init

    lda #FLAG_ENEMY_CENTIPEDE
    ora #FLAG_PLAYER
    sta game_enemy_statuses

    rts
.endproc

.proc game_full_reset
    jsr statusbar_init
    jsr player_init
    jsr arrow_init
    jsr game_level_reset
    rts
.endproc

.proc game_player_dead_handler
    clear game_enemy_statuses, #FLAG_PLAYER
    rts
.endproc