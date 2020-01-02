.include "sound.inc"
.include "nes.inc"
.include "centipede.inc"
.include "core/ntscperiods.s"

.segment "ZEROPAGE"

MARCH_SOUND_DELAY = 20 ; frames
centipede_march_timer:  .res 1

.segment "CODE"

.proc sound_init
    lda #MARCH_SOUND_DELAY
    sta centipede_march_timer
    lda #%10000001 ; volume/envelope setting and duty cycle flags
    sta APU_SQ1_ENV
    lda #$00
    sta APU_SQ1_SWP ; sweep, not needed (constant pitch)
    lda periodTableLo+14
    sta APU_SQ1_LOW ; note low bits
    rts
.endproc

.proc sound_run
    dec centipede_march_timer
    bne :+
        lda #MARCH_SOUND_DELAY ; play this 3 times a second
        sta centipede_march_timer
        lda #%10000000 ; length bits: eigth note at 75bpm (first 5 bits)
        ora periodTableHi+14 ; note high bits
        sta APU_SQ1_HIG
    :
    rts
.endproc