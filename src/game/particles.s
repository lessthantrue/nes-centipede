.include "particles.inc"
.include "../spritegfx.inc"
.include "../nes.inc"
.include "game.inc"
.include "../core/6502.inc"

; only death particles

.segment "BSS"
MAX_NUM_PARTICLES = 4
particle_xs:    .res MAX_NUM_PARTICLES
particle_ys:    .res MAX_NUM_PARTICLES
particle_times: .res MAX_NUM_PARTICLES
particle_oams:  .res MAX_NUM_PARTICLES

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
    txa
    pha ; save parameter pointer
    ldx #0
    loop_start:
        lda particle_times, y
        beq loop_end
        inx
        cpx MAX_NUM_PARTICLES
        bne :+
            ; give up if we couldn't find one
            rts
        :
        jmp loop_start
    loop_end:

    ; copy data
    txa
    pha
    jsr oam_alloc
    pla
    tax
    tya
    sta particle_oams, x
    lda #12
    sta particle_times, y
    pla
    tax ; restore stack pointer
    lda STACK_TOP+1, x
    sta OAM+oam::xcord, y
    lda STACK_TOP+2, x
    add #SPRITE_VERT_OFFSET
    sta OAM+oam::ycord, y
    rts
.endproc

; step and draw, because step is simple and it's not worth
; doing the loop boilerplate again
.proc particle_draw
    push_registers
    ldx #0
    loop_start:
        lda particle_times, x
        beq loop_cond ; particle dead? don't bother
        sub #1
        sta particle_times, x
        bne :+
            ; remove particle
            txa
            pha
            ldy particle_oams, x
            jsr oam_free
            pla
            tax
            jmp loop_cond
        :
        lda particle_times, x
        lsr ; shift for a transition every 2 frames
        and #%00000111
        add #$50
        ldy particle_oams, x
        sta OAM+oam::tile, y        
    loop_cond:
        inx
        cpx #MAX_NUM_PARTICLES
        beq loop_end
        jmp loop_start
    loop_end:
    pull_registers
    rts
.endproc