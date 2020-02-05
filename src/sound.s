.include "sound.inc"
.include "nes.inc"
.include "core/ntscperiods.s"
.include "events/events.inc"
.include "game/game.inc"

.segment "ZEROPAGE"

MARCH_SOUND_DELAY = 20 ; frames
centipede_march_timer:      .res 1
centipede_active:           .res 1

spider_jingle_counter:      .res 1
scorpion_jingle_counter:    .res 1

.segment "CODE"

; centipede walking and flea on triangle
; shooting and scorpion on sq1
; spider on sq2
; player death / enemy kill on noise

; spider
LOW = 38
MID = 41
HI = 47
spider_jingle:  .byte LOW, MID, HI, 0, HI, MID, LOW, MID, HI

; scorpion
SCORP_LOW = 25
SCORP_MID = SCORP_LOW + 3
SCORP_HI = SCORP_MID + 6
scorp_jingle:   .byte SCORP_LOW, SCORP_MID, SCORP_HI, SCORP_MID
SPIDER_JINGLE_LEN = 10

.proc sound_reset
    lda #1
    sta centipede_active
    rts
.endproc

; run this while the game is playing
.proc sound_run_default
    lda centipede_active
    beq :+
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
        lda #%00111000        
        ora periodTableHi, x
        sta APU_SQ2_HIG
        lda #%10011111
        sta APU_SQ2_ENV
        iny
        cpy #SPIDER_JINGLE_LEN
        bne :+
            ldy #0
        :
        sty spider_jingle_counter
    :
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

.proc centipede_kill_handler
    lda #0
    sta centipede_active
    rts
.endproc

.proc sound_init
    lda #$0F
    sta APUFLAGS
    lda #0
    sta $4011
    lda #1
    sta centipede_active
    lda #MARCH_SOUND_DELAY
    sta centipede_march_timer
    lda #0
    sta APU_SQ2_SWP
    sta spider_jingle_counter
    subscribe segment_kill, segment_kill_handler-1
    subscribe arrow_shoot, arrow_shoot_handler-1
    subscribe player_dead, player_dead_handler-1
    subscribe centipede_kill, centipede_kill_handler-1
    rts
.endproc
