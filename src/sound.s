.include "sound.inc"
.include "nes.inc"
.include "core/ntscperiods.s"
.include "events/events.inc"
.include "game/game.inc"

.segment "ZEROPAGE"

MARCH_SOUND_DELAY = 20 ; frames
centipede_march_timer:   .res 1

spider_jingle_counter:   .res 1
scorp_jingle_counter:    .res 1
flea_counter:            .res 1
extra_counter:        .res 1

.segment "CODE"

; centipede walking and flea on triangle
; shooting and scorpion on sq1
; spider and extra life on sq2
; player death and enemy kill on noise

; spider
LOW = 12 * 3 + NOTE_B
MID = 12 * 3 + NOTE_E
HI = 12 * 4 + NOTE_A
spider_jingle:  .byte LOW, 0, MID, 0, HI, 0, 0, 0, HI, 0, MID, 0, LOW, 0, MID, 0, HI, 0, 0, 0
SPIDER_JINGLE_LEN = 20


; scorpion
SCORP_LOW = 17
SCORP_MID = SCORP_LOW + 3
SCORP_HI = SCORP_MID + 6
scorp_jingle:   .byte SCORP_LOW, SCORP_MID, SCORP_LOW, SCORP_HI
SCORP_JINGLE_LEN = 4

; flea
FLEA_START = 20
FLEA_STEP = 1
FLEA_LEN = 100

; extra life
EXTRA_DIFF_LOW = 2
EXTRA_DIFF_HI = 6

EXTRA_LOWEST = 22
EXTRA_LOWER = 26
EXTRA_LOW = 29
EXTRA_HIGH = 34
EXTRA_HIGHER = 38
EXTRA_HIGHEST = 41

; note lengths
SHORT_LEN = $0C
MID_LEN = $1E

extra_jingle: .byte EXTRA_LOWER, EXTRA_LOWEST, EXTRA_LOWER, EXTRA_LOW, EXTRA_LOWER, EXTRA_LOW
                 .byte EXTRA_HIGH, EXTRA_HIGHER, EXTRA_HIGHEST, EXTRA_HIGHER, EXTRA_HIGHEST
extra_lens:   .byte SHORT_LEN, SHORT_LEN, SHORT_LEN, MID_LEN, SHORT_LEN, MID_LEN, SHORT_LEN, SHORT_LEN, MID_LEN, SHORT_LEN, MID_LEN
EXTRA_LEN = 11

; run this while the game is playing
.proc sound_run_default
    lda #FLAG_ENEMY_CENTIPEDE
    bit game_enemy_statuses
    beq :+
    lda #FLAG_ENEMY_FLEA
    bit game_enemy_statuses
    bne :+ ; don't play when flea is active
    dec centipede_march_timer
    bne :+
        lda #MARCH_SOUND_DELAY ; play this 3 times a second
        sta centipede_march_timer
        ; set channel
        lda #$7F
        sta APU_TRI_ENV
        lda periodTableLo+36
        asl
        sta APU_TRI_LOW ; note low bits
        lda #%00111000 ; length bits
        lsr
        ora periodTableHi+36 ; note high bits
        asl
        sta APU_TRI_HIG
    :

    ; spider
    lda #EXTRA_LEN
    cmp extra_counter
    bpl :++ ; new life counter still going (counter <= len)
    lda #SPIDER_FLAG_ALIVE
    bit spider_f
    beq :++ ; is spider alive
    lda #APU_FLAG_SQ2
    bit APUFLAGS
    bne :++ ; sound is still being played
        ldy spider_jingle_counter
        ldx spider_jingle, y ; can probably do this with one register
        lda periodTableLo, x ; but I don't want to deal with indirect
        sta APU_SQ2_LOW
        lda #($05<<3) ; length
        ora periodTableHi, x
        sta APU_SQ2_HIG
        lda #%10001111
        sta APU_SQ2_ENV
        iny
        cpy #SPIDER_JINGLE_LEN
        bne :+
            ldy #0
        :
        sty spider_jingle_counter
    :

    ; scorpion
    lda game_enemy_statuses
    and #FLAG_ENEMY_SCORPION
    beq :++
    lda #APU_FLAG_SQ1
    bit APUFLAGS
    bne :++ ; sound is still being played
        ldy scorp_jingle_counter
        ldx scorp_jingle, y ; can probably do this with one register
        lda periodTableLo, x ; but I don't want to deal with indirect
        sta APU_SQ1_LOW
        lda #($0B<<3) ; length        
        ora periodTableHi, x
        sta APU_SQ1_HIG
        lda #%10011111
        sta APU_SQ1_ENV
        lda #0
        sta APU_SQ1_SWP ; shooting changes this
        iny
        cpy #SCORP_JINGLE_LEN
        bne :+
            ldy #0
        :
        sty scorp_jingle_counter
    :

    ; extra life
    lda #EXTRA_LEN
    cmp extra_counter
    bge :+
        jmp end_extra_life
    :
    lda #APU_FLAG_SQ2
    bit APUFLAGS
    bne end_extra_life
        ldy extra_counter
        ldx extra_jingle, y
        lda periodTableLo, x
        sta APU_SQ2_LOW
        ; get length from a table
        lda extra_lens, y
        asl a
        asl a
        asl a
        ora periodTableHi, x
        sta APU_SQ2_HIG
        lda #%10011111
        sta APU_SQ2_ENV
        lda #0
        sta APU_SQ2_SWP
        inc extra_counter
    end_extra_life:

    ; flea
    lda game_enemy_statuses
    and #FLAG_ENEMY_FLEA
    bne :+
        ; flea is dead
        lda #FLEA_LEN
        sta flea_counter
        jmp end_flea
    :
        ; flea is alive
        lda flea_counter
        beq :+
            dec flea_counter ; limit at zero
        :
        lsr
        lsr ; crude divide
        add #FLEA_START ; frequency offset
        tay
        lda periodTableLo, y
        sta APU_TRI_LOW
        lda periodTableHi, y
        ora #($07<<3) ; timer
        sta APU_TRI_HIG
        sta APU_TRI_ENV

    end_flea:

    rts
.endproc

.proc segment_kill_handler
    lda #%00000100
    sta APU_NSE_ENV
    lda #$0D
    sta APU_NSE_PRD
    lda #%10010000
    sta APU_NSE_LEN
    rts
.endproc

.proc arrow_shoot_handler
    lda #%00011111
    sta APU_SQ1_ENV
    lda #$82
    sta APU_SQ1_SWP
    lda periodTableLo+65
    sta APU_SQ1_LOW
    lda #%11100000
    ora periodTableHi+65
    sta APU_SQ1_HIG
    rts
.endproc

.proc player_dead_handler
    lda #%00001111
    sta APU_NSE_ENV
    lda #$0E
    sta APU_NSE_PRD
    lda #%11000000
    sta APU_NSE_LEN
    rts
.endproc

.proc extra_life_handler
    lda #0
    sta extra_counter
    rts
.endproc

.proc sound_init
    lda #$0F
    sta APUFLAGS
    lda #0
    sta $4011
    lda #MARCH_SOUND_DELAY
    sta centipede_march_timer
    lda #0
    sta APU_SQ2_SWP
    sta spider_jingle_counter
    sta scorp_jingle_counter
    lda #EXTRA_LEN+1
    sta extra_counter
    subscribe segment_kill, segment_kill_handler-1
    subscribe arrow_shoot, arrow_shoot_handler-1
    subscribe player_dead, player_dead_handler-1
    subscribe extra_life, extra_life_handler-1
    rts
.endproc
