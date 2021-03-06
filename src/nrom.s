.include "main.inc"
.include "init.inc"

.import nmi_handler, reset_handler, irq_handler

.segment "INESHDR"
    .byt "NES",$1A  ; magic signature
    .byt 2          ; PRG ROM size in 16384 byte units
    .byt 1          ; CHR ROM size in 8192 byte units
    .byt $02        ; mirroring type and mapper number lower nibble - configured to enable battery-powered save data ($6000-$7FFF)
    .byt $00        ; mapper number upper nibble

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
