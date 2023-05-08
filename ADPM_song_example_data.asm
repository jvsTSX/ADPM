DEFSECT    "MUSIC", CODE
SECT    "MUSIC"
db "HEADER"
SongData:

; HEADER -----------
dw timeline0
dw phrasesIndex0
dw instrumentsIndex0
dw macrosIndex0
dw groovetable0
db 00h ; song speed



; INSTRUMENTS ------
instrumentsIndex0:
dw ins00
dw ins01

instrumentsData0:
ins00:
db  01h, 44h, 11011000b, 01h, 02h, 20h, 80h
ins01:
db 0FFh, 78h, 11001000b



; MACROS -----------
macrosIndex0:
dw Gmacro00
dw Gmacro01

macrosData0:
Gmacro00: ; drum
db 10011111b, 20h, 7Fh
db 10011110b, 18h, 7Fh
db 10011110b, 14h, 7Fh
db 10000010b
db 01



Gmacro01: ; slight pitch bend
db 10001010b, 01
db 10001010b, 00
db 01h


; GROOVE -----------
groovetable0:
db 04h
db 03h
db 03h
db 03h
db 0FFh, 00h



; TIMELINE ---------
timeline0:

; now:
db 00h, 01h ; phrase 0, tranpose by 0
db 01h, 01h ; phrase 1, tranpose by 0
db 01h, 03h ; phrase 1, tranpose by 2
db 02h, 01h ; phrase 2, tranpose by 0
db 01h, 01h ; phrase 1, tranpose by 0
db 01h, 03h ; phrase 1, tranpose by 2
db 03h ; (end phrase, only end command so garbage transpose don't matter)


; PHRASES ----------
phrasesIndex0:
dw phra00
dw phra01
dw phra02
dw phra03

phrasesData0:
phra00:

db 01h,  34h, 00h,     50h, 00h

db 00h,  04h, 01h
db 00h,  90h
db 00h,  32h, 00h,     50h, 00h
db 00h, 0B1h
db 00h, 0B2h,         0C2h 
db 00h, 0AFh
db 00h,  04h, 01h,     50h, 00h
db 00h,  90h
db 00h,  2Dh, 00h
db 00h,  10h, 01h
db 00h,  2Ah, 00h,     50h, 00h
db 00h,  04h, 01h
db 00h,  2Dh, 00h
db 00h, 0A8h
db 00h,  04h, 01h,     50h, 00h
db 20h,               0C2h
db 00h,  90h
db 00h,  84h
db 00h,  28h, 00h,     50h, 00h
db 00h,  04h, 01h
db 01h,  90h

db 00h,  28h, 00h,     50h, 00h
db 20h,               0C2h
db 00h,  10h, 01h
db 00h,  25h, 00h
db 20h,                50h, 00h
db 00h,  04h, 01h
db 00h,  28h, 00h
db 00h,  04h, 01h

db 11h

phra01:
db 00h,  30h, 00h,     50h, 00h
db 00h,  0Ch, 01h
db 00h,  32h, 00h
db 00h,  0Ch, 01h
db 00h,  30h, 00h,     50h, 00h
db 00h, 0AFh
db 00h,  0Ch, 01h
db 00h,  2Bh, 00h
db 01h,  00h, 01h,     50h, 00h

db 00h,  26h, 00h
db 20h,               0C2h
db 00h, 00h,  01h,     50h, 00h
db 20h,               0C2h
db 00h,  26h, 00h
db 00h,  0Ch, 01h

db 11h

phra02:
db 01h,  34h, 00h,     50h, 00h

db 00h,  04h, 01h
db 00h,  90h
db 00h,  32h, 00h,     50h, 00h
db 00h, 0B1h
db 00h, 0B2h,         0C2h
db 00h, 0AFh
db 20h,                50h, 00h
db 00h,  04h, 01h
db 00h,  2Dh, 00h
db 00h,  10h, 01h
db 00h,  2Ah, 00h,     50h, 00h
db 00h,  04h, 01h
db 00h,  2Dh, 00h
db 00h, 0B4h
db 01h,  04h, 01h,     50h, 00h
 
db 00h,  90h
db 20h,               0C2h
db 01h,  34h, 00h,     50h, 00h

db 00h,  04h, 01h
db 20h,               0C2h
db 01h,  3Bh, 00h,     50h, 00h
 
db 00h,  10h, 01h
db 00h,  39h, 00h
db 20h,                50h, 00h
db 00h,  04h, 01h
db 00h,  34h, 00h
db 00h,  04h, 01h

db 11h

phra03:
db 10h, 00h