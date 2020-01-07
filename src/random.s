.include "random.inc"

.segment "BSS"
seed:   .res 2 ; doesn't matter what's here, so long as it's not zero

.segment "CODE"

.proc random_init
    lda #$05
    sta seed
    lda #$E8
    sta seed+1
    rts
.endproc

; Returns a random 8-bit number in A (0-255), clobbers X (0).
.proc rand8
	ldx #8     ; iteration count (generates 8 bits)
	lda seed+0
:
	asl        ; shift the register
	rol seed+1
	bcc :+
	eor #$2D   ; apply XOR feedback whenever a 1 bit is shifted out
:
	dex
	bne :--
	sta seed+0
	cmp #0     ; reload flags
	rts
.endproc