.include "flea.inc"
.include "board.inc"
.include "game.inc"
.include "../random.inc"

.segment "BSS"

flea_x:     .res 1
flea_y:     .res 1

; %0000000H
; H is HP
flea_f:    .res 1
flea_timer:.res 2

FLEA_SPEED_SLOW = 2
FLEA_SPEED_HIGH = 4

.segment "CODE"

.proc flea_init
    lda #0
    sta flea_x
    sta flea_f
    sta flea_y

    clear game_enemy_statuses, #FLAG_ENEMY_FLEA

    rts
.endproc

; same thing as everything else
.proc flea_set_respawn_time
    jsr rand8
    and #$01 ; 0 to 5 seconds
    sta flea_timer+1
    jsr rand8
    sta flea_timer
    rts
.endproc

.proc flea_reset
    jsr rand8
    and #%11111000 ; aligned to 8
    sta flea_x
    lda #0
    sta flea_y
    lda #1
    sta flea_f

    set game_enemy_statuses, #FLAG_ENEMY_FLEA

    jsr flea_set_respawn_time
    rts
.endproc

.proc flea_move
    lda #1
    bit flea_f
    beq :+
        ; flea not hit yet
        lda flea_y
        add #FLEA_SPEED_SLOW
        sta flea_y
        jmp :++
    :
        lda flea_y
        add #FLEA_SPEED_HIGH
        sta flea_y
    :

    rts
.endproc

.proc flea_draw
    rts
.endproc