.ifndef QUEUE_INC
QUEUE_INC = 1

.macro phq val
    lda val
    jsr q_push
.endmacro

.macro plq
    jsr q_pull
.endmacro

.globalzp q_start, q_len
.global q_data, q_init, q_pull, q_push

.endif