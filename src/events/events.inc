.ifndef EVENTS_INC
.define EVENTS_INC 1

.include "playerdead.inc"
.include "segmentkill.inc"
.include "arrowshoot.inc"

.macro subscribe event, handler
    call_with_args .ident(.sprintf("%s_subscribe", .string(event))), #<handler, #>handler
.endmacro

.macro notify event
    jsr .ident(.sprintf("%s_notify", .string(event)))
.endmacro

.macro init event
    jsr .ident(.sprintf("%s_init", .string(event)))
.endmacro

.endif