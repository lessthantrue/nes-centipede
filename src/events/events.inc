.ifndef EVENTS_INC
.define EVENTS_INC 1

.include "eventmacros.inc"

make_event_header centipede_kill
make_event_header level_up
make_event_header arrow_shoot
make_event_header player_dead
make_event_header segment_kill

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