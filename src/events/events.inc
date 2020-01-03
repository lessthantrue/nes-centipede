.ifndef EVENTS_INC
.define EVENTS_INC 1

.include "playerdead.inc"

.macro subscribe event, handler
    call_with_args .ident(.sprintf("%s_subscribe", .string(event))), #<handler, #>handler
.endmacro

.endif