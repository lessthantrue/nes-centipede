.include "particles.inc"
.include "../spritegfx.inc"
.include "game.inc"
.include "../core/6502.inc"

; only death particles

.segment "BSS"
MAX_NUM_PARTICLES = 4
particle_xs:    .res MAX_NUM_PARTICLES
particle_ys:    .res MAX_NUM_PARTICLES
particle_times: .res MAX_NUM_PARTICLES

.segment "CODE"

.proc particles_init
    ldy #0
    lda #0
    :
        sta particle_xs, y
        sta particle_ys, y
        sta particle_times, y
        iny
        cpy #MAX_NUM_PARTICLES
        bne :-
    rts
.endproc

; arg 1: x
; arg 2: y
.proc particle_add
    ; find the first open particle
    ldy #0
    loop_start:
        lda particle_times, y
        beq loop_end
        iny
        cpy MAX_NUM_PARTICLES
        bne :+
            ; give up if we couldn't find one
            rts
        :
        jmp loop_start
    loop_end:

    ; copy data
    lda STACK_TOP+1, x
    sta particle_xs
    lda STACK_TOP+2, x
    sta particle_ys
    lda #12
    sta particle_times
    rts
.endproc

; step and draw, because step is simple and it's not worth
; doing the loop boilerplate again
.proc particle_draw
    push_registers
    ldy #0
    loop_start:
        lda particle_times, y
        bne :+
            call_with_args spritegfx_load_oam, #OFFSCREEN, #0, #0, #0
            jmp loop_cond
        :
        sub #1
        sta particle_times, y ; step time forwards
        ; arg 4: sprite x
        lda particle_xs, y
        pha
        ; arg 3: sprite flags
        lda #0
        pha
        ; arg 2: sprite tile index
        lda particle_times, y
        lsr ; shift for a transition every 2 frames
        and #%00000111
        add #$50
        pha
        ; arg 1: sprite y
        lda particle_ys, y
        pha
        call_with_args_manual spritegfx_load_oam, 4
    loop_cond:
        iny
        cpy #MAX_NUM_PARTICLES
        beq loop_end
        jmp loop_start
    loop_end:
    pull_registers
    rts
.endproc