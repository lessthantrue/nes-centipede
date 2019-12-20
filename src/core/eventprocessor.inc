.ifndef EVENT_PROCESSOR_INC
.define EVENT_PROCESSOR_INC

.global evtp_add, evtp_run

.macro evtp_push_handler hand
    phq #>hand
    phq #<hand-1
.endmacro

.macro evtp_push_args a1, a2, a3, a4, a5, a6, a7
    .ifblank a1
        .exitmacro
    .else
        phq a1
    .endif
        evtp_push_args a2, a3, a4, a5, a6, a7
.endmacro

.macro evtp_add handler, a1, a2, a3, a4, a5, a6, a7
    evtp_push_handler handler
    evtp_push_args a1, a2, a3, a4, a5, a6, a7
.endmacro

.endif