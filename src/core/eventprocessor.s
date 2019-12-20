.include "queue.inc"
.include "macros.inc"
.include "eventprocessor.inc"

.segment "CODE"

.proc evtp_init
    jsr q_init
    rts
.endproc

.proc evtp_next
    lda q_len
    beq Q_EMPTY ; if queue is empty, skip

    ; set up stack to return program execution to calling function
    plq
    pha
    plq
    sub #1
    pha

    ; indirectly call function 
    ; (function called is expected to clean up all arguments in queue)
    Q_EMPTY:
    rts
.endproc

; right now this just makes sure the return addresses stay in order, however 
; this may be modified to do more advanced stuff later
.proc evtp_run
    jsr evtp_next
    rts
.endproc
