DEFSECT   ".ADPMexample",  CODE
SECT ".ADPMexample"

GLOBAL __SongData
GLOBAL __SFXdata

__SongData:
; HEADER -----------
dw timeline0
dw phrasesIndex0
dw instrumentsIndex0
dw macrosIndex0
db 40h

; TIMELINE ---------
timeline0:

; now:
db 00h, 00h ; phrase 0, tranpose by 0
db 01h, 00h ; phrase 1, tranpose by 0
db 01h, 02h ; phrase 1, tranpose by 2
db 02h, 00h ; phrase 2, tranpose by 0
db 01h, 00h ; phrase 1, tranpose by 0
db 01h, 02h ; phrase 1, tranpose by 2
db 03h ; (end phrase, only end command so garbage transpose don't matter)


; PHRASES ----------
phrasesIndex0:
dw phra00
dw phra01
dw phra02
dw phra03

phrasesData0:
phra00:

db 01h,  34h, 00h,     90h, 00h

db 00h,  04h, 01h
db 00h,  90h
db 00h,  32h, 00h,     90h, 00h
db 00h, 0B1h
db 00h, 0B2h,          32h 
db 00h, 0AFh
db 00h,  04h, 01h,     90h, 00h
db 00h,  90h
db 00h,  2Dh, 00h
db 00h,  10h, 01h
db 00h,  2Ah, 00h,     90h, 00h
db 00h,  04h, 01h
db 00h,  2Dh, 00h
db 00h, 0A8h
db 00h,  04h, 01h,     90h, 00h
db 50h,                32h
db 00h,  90h
db 00h,  84h
db 00h,  28h, 00h,     90h, 00h
db 00h,  04h, 01h
db 01h,  90h

db 00h,  28h, 00h,     90h, 00h
db 50h,                32h
db 00h,  10h, 01h
db 00h,  25h, 00h
db 50h,                 90h, 00h
db 00h,  04h, 01h
db 00h,  28h, 00h
db 00h,  04h, 01h

db 10h

phra01:
db 00h,  30h, 00h,     90h, 00h
db 00h,  0Ch, 01h
db 00h,  32h, 00h
db 00h,  0Ch, 01h
db 00h,  30h, 00h,     90h, 00h
db 00h, 0AFh
db 00h,  0Ch, 01h
db 00h,  2Bh, 00h
db 01h,  00h, 01h,     90h, 00h

db 00h,  26h, 00h
db 50h,                32h
db 00h, 00h,  01h,     90h, 00h
db 50h,                32h
db 00h,  26h, 00h
db 00h,  0Ch, 01h

db 10h

phra02:
db 01h,  34h, 00h,     90h, 00h

db 00h,  04h, 01h
db 00h,  90h
db 00h,  32h, 00h,     90h, 00h
db 00h, 0B1h
db 00h, 0B2h,          32h
db 00h, 0AFh
db 50h,                90h, 00h
db 00h,  04h, 01h
db 00h,  2Dh, 00h
db 00h,  10h, 01h
db 00h,  2Ah, 00h,     90h, 00h
db 00h,  04h, 01h
db 00h,  2Dh, 00h
db 00h, 0B4h
db 01h,  04h, 01h,     90h, 00h
 
db 00h,  90h
db 50h,                32h
db 01h,  34h, 00h,     90h, 00h

db 00h,  04h, 01h
db 50h,                32h
db 01h,  3Bh, 00h,     90h, 00h
 
db 00h,  10h, 01h
db 00h,  39h, 00h
db 50h,                90h, 00h
db 00h,  04h, 01h
db 00h,  34h, 00h
db 00h,  04h, 01h

db 10h

phra03:
db 20h, 00h


; INSTRUMENTS ------
instrumentsIndex0:
dw ins00
dw ins01

instrumentsData0:
ins00:
db 00h, 44h, 01h, 00010011b, 01h, 01h, 20h, 80h
ins01:
db 00h, 78h, 0FFh, 00000011b

; MACROS -----------
macrosIndex0:
dw Gmacro00
dw Gmacro01
dw Gmacro02
dw Gmacro03

macrosData0:
Gmacro00: ; drum
db 01h, 20h,  7Bh, 80h,   20h
db 01h, 18h,              20h
db 01h, 14h,              20h
db 00h, 00h,  70h, 00h,   30h, 0FFh

Gmacro01: ; slight pitch bend
db 00h, 001h,   20h
db 00h, 0FFh,   30h, 0FFh

Gmacro02:
db 00h, 002h, 20h
db 00h, 002h, 20h
db 00h, 0FEh, 20h
db 00h, 0FEh, 20h
db 10h, 040h, 23h
db 10h, 020h, 23h
db 11h, 080h, 23h
db 11h, 040h, 23h
db 50h, 20h
db 51h, 20h
db 50h, 20h
db 51h, 20h
db 50h, 20h
db 53h, 20h
db 51h, 20h
db 53h, 20h
db 53h, 20h
db 51h, 20h
db 53h, 20h
db 40h, 00h

Gmacro03:
db 20h
db 00h, 002h ,20h
db 00h, 0FEh ,20h
db 30h, 0FAh



; SFX EXAMPLE



__SFXdata:
; SFX index table
dw SFX0
dw SFX1
dw SFX2
dw SFX3

SFX0: ; all of them
db 10110011b, 0A0h, 30h
db 10111011b, 80h, 8Fh
db 10111011b, 88h, 8Fh
db 10111010b, 70h, 8Fh
db 10111010b, 78h, 8Fh
db 10110011b, 80h, 30h
db 10110011b, 88h, 34h
db 10110010b, 70h, 38h
db 10110010b, 78h, 40h
db 00h

SFX1: ; only duty
db 10110011b, 80h, 38h
db 10100011b, 70h
db 10100011b, 60h
db 10100011b, 50h
db 10100011b, 40h
db 10100011b, 30h
db 00h

SFX2: ; only freq (absol)
db 10110011b, 80h, 30h
db 10010011b, 024h
db 10010011b, 020h
db 10010011b, 028h
db 10010011b, 02Eh
db 10010011b, 02Eh
db 00h

SFX3: ; only freq (relative)
db 10110011b, 80h, 30h
db 10011011b, 07Fh
db 10011011b, 07Fh
db 10011011b, 07Fh
db 10011011b, 07Fh
db 10011011b, 07Fh
db 10011011b, 07Fh
db 10011011b, 07Fh
db 10011011b, 07Fh
db 10011011b, 07Fh
db 10011011b, 07Fh
db 00h