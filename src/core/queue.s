.include "queue.inc"
.include "macros.inc"

.segment "ZEROPAGE"

QUEUE_CAPACITY = 255

q_len :     .res 1
q_start :   .res 1
q_end :     .res 1

.segment "BSS"

q_data :    .res QUEUE_CAPACITY

.segment "CODE"

.proc q_init
    lda #0
    sta q_len
    sta q_start
    sta q_end
.endproc

; pushes byte in A to the back of the queue
; also fucks X
.proc q_push
    lda q_len
    cmp #QUEUE_CAPACITY
    bmi NO_ERR
        ERROR_QUEUE_OVERFLOW :
        jmp ERROR_QUEUE_OVERFLOW
    NO_ERR :

    ; no need to wrap around because 1 byte register does that for us
    add q_start
    tax
    sta q_data, x

    ; increment queue length
    inc q_len
.endproc

; pulls byte at the front of the queue to A
.proc q_pull
    lda q_len
    bpl NO_ERR
        ERROR_QUEUE_UNDERFLOW :
        jmp ERROR_QUEUE_UNDERFLOW
    NO_ERR :

    ; do the thing
    ldx q_start
    lda q_data, x

    ; decrement queue length
    dec q_len
    inc q_start
.endproc
