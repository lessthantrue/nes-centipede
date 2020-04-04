.include "common.inc"

.segment "CODE"

; use this whenever an address to a proc that does nothing is needed
.proc empty
    rts
    rts ; in case 'empty' is used where 'empty-1' should be used 
.endproc