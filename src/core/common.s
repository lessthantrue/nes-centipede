.include "common.inc"

.segment "CODE"

; use this whenever an address to a proc that does nothing is needed
.proc empty
    rts
.endproc