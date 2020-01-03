.include "sound.inc"
.include "nes.inc"
.include "centipede.inc"
.include "core/ntscperiods.s"
.include "events/events.inc"

.segment "ZEROPAGE"

MARCH_SOUND_DELAY = 20 ; frames
centipede_march_timer:  .res 1

.segment "CODE"

.proc sound_init
    lda #$0F
    sta APUFLAGS
    lda #MARCH_SOUND_DELAY
    sta centipede_march_timer
    subscribe segment_kill, segment_kill_handler
    subscribe arrow_shoot, arrow_shoot_handler
    rts
.endproc

.proc sound_run
    dec centipede_march_timer
    bne :+
        lda #MARCH_SOUND_DELAY ; play this 3 times a second
        sta centipede_march_timer

        ; set channel
        lda #%10010100 ; volume/envelope setting and duty cycle flags
        sta APU_NSE_ENV
        lda #$00
        sta APU_SQ1_SWP ; sweep, not needed (constant pitch)
        lda periodTableLo+17
        sta APU_SQ1_LOW ; note low bits
        lda #%10000000 ; length bits: eigth note at 75bpm (first 5 bits)
        ora periodTableHi+17 ; note high bits
        sta APU_SQ1_HIG
    :
    rts
.endproc

.proc segment_kill_handler
    lda #%10010111
    sta APU_SQ2_ENV
    lda $00
    sta APU_SQ2_SWP
    lda periodTableLo+25
    sta APU_SQ2_LOW
    lda #%10000000
    ora periodTableHi+25
    sta APU_SQ2_HIG
    rts
.endproc

.proc arrow_shoot_handler
    lda #%00011111
    sta APU_SQ2_ENV
    lda #$82
    sta APU_SQ2_SWP
    lda periodTableLo+65
    sta APU_SQ2_LOW
    lda #%11100000
    ora periodTableHi+65
    sta APU_SQ2_HIG
    rts
.endproc