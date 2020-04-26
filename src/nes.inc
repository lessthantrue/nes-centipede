;
; NES I/O definitions
; Copyright 2010 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

.ifndef NES_INC
NES_INC = 1

APUFLAGS = $4015
APU_FLAG_SQ1 = %00000001
APU_FLAG_SQ2 = %00000010
APU_FLAG_TRI = %00000100
APU_FLAG_NSE = %00001000
APU_FLAG_DMC = %00010000

APU_SQ1_ENV = $4000
APU_SQ1_SWP = $4001
APU_SQ1_LOW = $4002
APU_SQ1_HIG = $4003

APU_SQ2_ENV = $4004
APU_SQ2_SWP = $4005
APU_SQ2_LOW = $4006
APU_SQ2_HIG = $4007

APU_TRI_ENV = $4008
APU_TRI_LOW = $400A
APU_TRI_HIG = $400B

APU_NSE_ENV = $400C
APU_NSE_PRD = $400E
APU_NSE_LEN = $400F

PPUCTRL = $2000
NT_2000 = $00
NT_2400 = $01
NT_2800 = $02
NT_2C00 = $03
VRAM_DOWN = $04
OBJ_0000 = $00
OBJ_1000 = $08
OBJ_8X16 = $20
BG_0000 = $00
BG_1000 = $10
VBLANK_NMI = $80

PPUMASK = $2001
LIGHTGRAY = $01
BG_OFF = $00
BG_CLIP = $08
BG_ON = $0A
OBJ_OFF = $00
OBJ_CLIP = $10
OBJ_ON = $14
TINT_R = $20
TINT_G = $40
TINT_B = $80

PPUSTATUS = $2002
OAMADDR = $2003
OAM = $0200
; Don't worry about $2004; let OAM_DMA do the work for you.
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007

OAM_DMA = $4014
SNDCHN = $4015
P1 = $4016
P2 = $4017

KEY_A      = %10000000
KEY_B      = %01000000
KEY_SELECT = %00100000
KEY_START  = %00010000
KEY_UP     = %00001000
KEY_DOWN   = %00000100
KEY_LEFT   = %00000010
KEY_RIGHT  = %00000001

SAVE_START = $6000

.endif
