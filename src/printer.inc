.ifndef PRINTER_INC
PRINTER_INC = 1

.globalzp strptr, strlen
.global print_centered

.macro pstring str
    .byte .strlen(str), str
.endmac

.endif