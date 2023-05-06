DEFSECT    ".setup_main", CODE
SECT    ".setup_main"

EXTERN _ADPM_RUN
EXTERN _ADPM_SETUP
EXTERN _ADPM_SFXbank
EXTERN _ADPM_SFXdir
EXTERN _ADPMrunSFX
EXTERN _ADPM_SFXoverlay


; SETUP
GLOBAL _main
_main:
; interrupts
	ld a, #0
	ld [br:020h], #11111111b	 ; priority
	ld [br:021h], #11111111b
	ld [br:022h], #11111111b
	ld [br:023h], #10000000b 	; enable
	ld [br:024h], a
	ld [br:025h], a
	ld [br:026h], a
	ld [br:027h], #11111111b 	; flags
	ld [br:028h], #11111111b
	ld [br:029h], #11111111b
	ld [br:02Ah], #11111111b

	ld [br:01Ch], #10001000b	; timer 3
	ld [br:01Dh], #00000000b
	ld [br:048h], #10000110b
	ld [br:019h], #00100000b	; oscillator
	ld [br:070h], #0			; sound 
	ld [br:071h], #00000011b

	ld [br:080h], #00001010b	; PRC
	ld ba, #TileBase
	ld [br:82h], a
	ld [br:83h], b
	ld [br:84h], #0
	ld sc, #00000000b


; setup showcase screen
	xor a, a
	ld b, #60h
	ld ix, #1360h
loadmaploop:
	ld [ix], a
	inc a
	inc ix
  djr nz, loadmaploop

; setup ADPM
	push ip
	ld a, #@dpag(SongData) ; bank
	ld ix, #SongData ; song local
	carl _ADPM_SETUP
	pop ip

	ld a, #@dpag(SFXdata) ; bank
	ld [_ADPM_SFXbank], a
	ld hl, #SFXdata
	ld [_ADPM_SFXdir], hl

Main:
	halt
	
	ld b, [br:52h] ; keypad
	ld a, [1FE0h]
	cp a, b
	ld l, b
	ld a, b
  jrs z, skipinputget
	
	cp a, #11110111b ; up
  jrs nz, upnotpressed
	ld h, #00h
	ld [_ADPM_SFXoverlay], h
upnotpressed:

	cp a, #11101111b ; down
  jrs nz, downnotpressed
	ld h, #01h
	ld [_ADPM_SFXoverlay], h
downnotpressed:

	cp a, #11011111b ; left
  jrs nz, leftnotpressed
	ld h, #02h
	ld [_ADPM_SFXoverlay], h
leftnotpressed:

	cp a, #10111111b ; right
  jrs nz, rightnotpressed
	ld h, #03h
	ld [_ADPM_SFXoverlay], h
rightnotpressed:

	cp a, #01111111b ; sleep
  jrs nz, sleepnotpressed
	ld [br:71h], #0
	int [42h]
sleepnotpressed:
	ld [1FE0h], l
skipinputget:
;	ld ep, #0
;	ld xp, #0
	
	push ip
  carl _ADPMrunSFX
	pop ip
	push ip
  carl _ADPM_RUN
	pop ip
  jrl Main





; Copytable
    DEFSECT    ".ctable", CODE, SHORT
	SECT    ".ctable"
global __copytable
__copytable:
ret


; Interrupts
    DEFSECT    ".isr", CODE, SHORT
    SECT    ".isr"

_prc_frame_copy_irq:
ld [br:27h], #11111111b
ld [br:20h], #11000000b
rete

_prc_render_irq:
_timer_2h_underflow_irq:
_timer_2l_underflow_irq:
_timer_1h_underflow_irq:
_timer_1l_underflow_irq:
_timer_3h_underflow_irq:
_timer_3_cmp_irq:
_timer_32hz_irq:
_timer_8hz_irq:
_timer_2hz_irq:
_timer_1hz_irq:
_ir_rx_irq:
_shake_irq:
_key_power_irq:
_key_right_irq:
_key_left_irq:
_key_down_irq:
_key_up_irq:
_key_c_irq:
_key_b_irq:
_key_a_irq:
_unknown_irq:
_cartridge_irq:
rete

        GLOBAL  _prc_frame_copy_irq
        GLOBAL  _prc_render_irq
        GLOBAL  _timer_2h_underflow_irq
        GLOBAL  _timer_2l_underflow_irq
        GLOBAL  _timer_1h_underflow_irq
        GLOBAL  _timer_1l_underflow_irq
        GLOBAL  _timer_3h_underflow_irq
        GLOBAL  _timer_3_cmp_irq
        GLOBAL  _timer_32hz_irq
        GLOBAL  _timer_8hz_irq
        GLOBAL  _timer_2hz_irq
        GLOBAL  _timer_1hz_irq
        GLOBAL  _ir_rx_irq
        GLOBAL  _shake_irq
        GLOBAL  _key_power_irq
        GLOBAL  _key_right_irq
        GLOBAL  _key_left_irq
        GLOBAL  _key_down_irq
        GLOBAL  _key_up_irq
        GLOBAL  _key_c_irq
        GLOBAL  _key_b_irq
        GLOBAL  _key_a_irq
        GLOBAL  _unknown_irq
        GLOBAL  _cartridge_irq
		
        GLOBAL  _prc_frame_copy_irq
        GLOBAL  _prc_render_irq

















; todo last things
; cycle count this fucker
; write documentation

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






DEFSECT ".sounddata", ROMDATA
SECT ".sounddata"
SFXdata:
; SFX index table
dw SFX0
dw SFX1
dw SFX2
dw SFX3

SFX0: ; all of them
db 10110011b, 0A0h, 31h
db 10111011b, 80h, 8Fh
db 10111011b, 88h, 8Fh
db 10111010b, 70h, 8Fh
db 10111010b, 78h, 8Fh
db 10110011b, 80h, 31h
db 10110011b, 88h, 35h
db 10110010b, 70h, 39h
db 10110010b, 78h, 41h
db 00h

SFX1: ; only duty
db 10110011b, 80h, 39h
db 10100011b, 70h
db 10100011b, 60h
db 10100011b, 50h
db 10100011b, 40h
db 10100011b, 30h
db 00h

SFX2: ; only freq (absol)
db 10110011b, 80h, 31h
db 10010011b, 025h
db 10010011b, 021h
db 10010011b, 029h
db 10010011b, 02Fh
db 10010011b, 02Fh
db 00h

SFX3: ; only freq (relative)
db 10110011b, 80h, 31h
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









DEFSECT ".ADPMscreen", ROMDATA
SECT ".ADPMscreen"
ALIGN 8
TileBase:
db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0B0h, 0B0h, 000h, 000h, 000h, 000h, 000h, 080h, 080h, 000h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h, 090h, 0B8h, 0B0h, 0B0h, 0BFh, 09Fh, 080h, 08Fh, 09Eh, 0B8h, 09Eh, 08Fh, 083h, 090h, 0B7h, 0B7h, 0B5h, 0BDh, 099h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h, 060h, 018h, 006h, 001h, 000h, 000h, 0C0h, 0C0h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 0F8h, 008h, 008h, 008h, 008h, 008h, 018h, 060h, 080h, 000h, 001h, 006h, 018h, 07Fh, 080h, 000h, 000h, 000h, 000h, 0F8h, 008h, 008h, 008h, 008h, 008h, 008h, 0F8h, 000h, 000h, 001h, 006h, 018h, 0E0h, 000h, 000h, 000h, 001h, 006h, 018h, 060h, 080h, 080h, 060h, 018h, 006h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h, 060h, 018h, 006h, 001h, 000h, 000h, 000h, 030h, 02Ch, 023h, 020h, 03Fh, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 0FEh, 000h, 000h, 000h, 000h, 001h, 0FEh, 000h, 000h, 000h, 0F1h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 010h, 0F0h, 010h, 010h, 010h, 01Fh, 000h, 0FEh, 018h, 060h, 080h, 000h, 000h, 001h, 001h, 000h, 000h, 080h, 060h, 018h, 0FEh, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h, 060h, 018h, 006h, 001h, 000h, 000h, 080h, 060h, 018h, 004h, 004h, 004h, 004h, 004h, 004h, 0FCh, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 07Fh, 040h, 040h, 040h, 040h, 040h, 060h, 018h, 006h, 001h, 000h, 080h, 060h, 0F8h, 006h, 001h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 001h, 006h, 018h, 060h, 060h, 018h, 006h, 001h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 000h, 000h, 000h, 000h, 000h, 070h, 0F6h, 0C5h, 0F4h, 074h, 004h, 0E4h, 0F4h, 056h, 071h, 060h, 000h, 0F0h, 0F0h, 060h, 030h, 010h, 000h, 007h, 004h, 024h, 0F4h, 0F4h, 004h, 007h, 004h, 024h, 0F4h, 0F4h, 004h, 004h, 004h, 004h, 004h, 004h, 004h, 004h, 004h, 004h, 004h, 006h, 001h, 000h, 007h, 004h, 004h, 004h, 004h, 004h, 007h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 007h, 004h, 004h, 094h, 0D4h, 054h, 077h, 020h, 000h, 0E0h, 0F0h, 010h, 0F0h, 0E0h, 000h, 090h, 0D0h, 050h, 070h, 027h, 004h, 014h, 054h, 054h, 0F4h, 0A7h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 000h, 000h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 000h, 001h, 000h, 000h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 001h, 001h, 001h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 000h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 081h, 0F5h, 0F5h, 0F3h, 0FFh, 083h, 0F7h, 0FBh, 0FFh, 0C7h, 0ABh, 0A7h, 0FFh, 0B7h, 0ABh, 0DBh, 0FFh, 0B7h, 0ABh, 0DBh, 0FFh, 0FFh, 0FFh, 0FFh, 081h, 0BDh, 0BDh, 0C3h, 0FFh, 0EFh, 0FFh, 083h, 0EBh, 0E7h, 0FFh, 0CBh, 0ABh, 087h, 0FFh, 0CFh, 0B7h, 081h, 0FFh, 0FFh, 0FFh, 0FFh, 0F7h, 083h, 0F5h, 0FFh, 0C7h, 0BBh, 0C7h, 0FFh, 083h, 0F7h, 0FBh, 0FFh, 0FFh, 0FFh, 0FFh, 0B3h, 0B5h, 0B5h, 0CDh, 0FFh, 081h, 0F5h, 0F5h, 0FDh, 0FFh, 09Dh, 0EBh, 0F7h, 0EBh, 09Dh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh