.include "sound.inc"
.include "nes.inc"
.include "centipede.inc"
.include "core/ntscperiods.s"
.include "events/events.inc"

.segment "ZEROPAGE"

MARCH_SOUND_DELAY = 20 ; frames
centipede_march_timer:  .res 1
centipede_active:        .res 1

.segment "CODE"

; centipede walking on triangle
; shooting on sq1
; everything else on sq2
; later: player death / enemy kill on noise?

.proc sound_init
    lda #$0F
    sta APUFLAGS
    lda #0
    sta $4011
    lda #1
    sta centipede_active
    lda #MARCH_SOUND_DELAY
    sta centipede_march_timer
    subscribe segment_kill, segment_kill_handler
    subscribe arrow_shoot, arrow_shoot_handler
    rts
.endproc

; run this while the game is playing
.proc sound_run_default
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
        lda #%10000000 ; length bits: eigth note at 75bpm (first 5 bits)
        lsr
        ora periodTableHi+36 ; note high bits
        asl
        sta APU_TRI_HIG
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