.include "gamestaterunner.inc"
.include "core/macros.inc"
.include "gamestates/playing.inc"

.segment "ZEROPAGE"

gamestaterunner_logicfn         :   .addr $0000
gamestaterunner_bgfn            :   .addr $0000
gamestaterunner_transitionfn    :   .addr $0000

.segment "CODE"

.proc gamestaterunner_logic
    ; run logic function
    ; returns to function that called this
    lda gamestaterunner_logicfn+1
    pha
    lda gamestaterunner_logicfn
    sub #1
    pha 
    rts
.endproc

.proc gamestaterunner_bg
    ; run background / nametable function
    ; returns to function that called this
    lda gamestaterunner_bgfn+1
    pha
    lda gamestaterunner_bgfn
    sub #1
    pha 
    rts
.endproc

.proc gamestaterunner_transition
    ; run state transition function
    ; returns to function that called this
    lda gamestaterunner_transitionfn+1
    pha
    lda gamestaterunner_transitionfn
    sub #1
    pha 
    rts
.endproc