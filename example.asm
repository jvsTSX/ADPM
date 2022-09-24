DEFSECT    ".setup_main", CODE
SECT    ".setup_main"
; SETUP
global _main
_main:
; interrupts
xor a, a

ld [br:020h], #11111111b ; priority
ld [br:021h], #11111111b
ld [br:022h], #11111111b

ld [br:023h], #10000000b ; enable
ld [br:024h], a
ld [br:025h], a
ld [br:026h], a

ld [br:027h], #11111111b ; flags
ld [br:028h], #11111111b
ld [br:029h], #11111111b
ld [br:02Ah], #11111111b

; timer 3
ld [br:01Ch], #10001000b
ld [br:01Dh], #00000000b
ld [br:048h], #10000110b

; oscillator
ld [br:019h], #00100000b

; sound 
ld [br:070h], #00h
ld [br:071h], #00000011b

; PRC
ld [br:080h], #00001010b
ld ba, #TileBase
ld [br:82h], a
ld [br:83h], b
ld [br:84h], #0h

; PRC map
	xor a, a
	ld b, #60h
	ld ix, #1360h
loadmaploop:
	ld [ix], a
	inc a
	inc ix
  djr nz, loadmaploop

; status flags
ld sc, #00000000b

; sound lib
ld hl, #SongData
carl _ADPMsongSetupCode
ld hl, #SFXdata
carl _ADPMsfxBlockSetupCode

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
	ld [SFXreq], h
upnotpressed:

	cp a, #11101111b ; down
  jrs nz, downnotpressed
	ld h, #01h
	ld [SFXreq], h
downnotpressed:

	cp a, #11011111b ; left
  jrs nz, leftnotpressed
	ld h, #02h
	ld [SFXreq], h
leftnotpressed:

	cp a, #10111111b ; right
  jrs nz, rightnotpressed
	ld h, #03h
	ld [SFXreq], h
rightnotpressed:

	cp a, #01111111b ; sleep
  jrs nz, sleepnotpressed
	ld [br:71h], #0
	int [42h]
sleepnotpressed:
	ld [1FE0h], l
skipinputget:
	
  carl _ADPMrunSFX
  carl _ADPMengineA
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
	;


; WHAT TO DO?
;
; [X]  VERIFY CORE CODE
; [X]  MOUNT TEST NOTE COMMAND
; [X]  MOUNT PHRASE END COMMAND
; [X]  MOUNT SONG END COMMAND
; [X]  MOUNT TEST DATA
; [X]  ASSEMBLE AND RUN - REPEAT UNTILL WORKING AS INTENDED

; [X] RESERVE ALL NEEDED RAM SPACE
; [X] WORK ON NOTE HANDLER AND FIX COMMANDS 
; [X] ADD ALL DESIRED COMMANDS

; [X] IMPLEMENT KILL COUNTER
; [X] IMPLEMENT DELAYED NOTE COUNTER
; [X] IMPLEMENT GENERAL MACRO'S BASE FUNCTIONINGS

; [/] ENGINE B EXIT VECTOR
; [X] SEPARATE SFX CALL
; [X] CHANGE SET RATE COMMAND TO ACCOMODATE TIMER WRITES


; ///////////////////////////////////////////////////////////////////////// /  /  / 
; ///////   ____ ______   ______ ____    ____   //////////////// /// /  /    /
; //////  /     |   __  \|   __  \   \  /    |  ///////////// // // /    /
; /////  /  /|  |  |  \  \  |__|  |   \/     |  ///////////////     /  /
; ////  /  /_|  |  |   |  |  _____||\    /|  |  ///////////  /   /  /
; ///  /  ___   |  |   |  | |   |  | \  / |  |  ///////// /   /   /
; //  /  /   |  |  |__/  /  |   |  |  \/  |  |  ////////  /      /
; /  /__/    |__|_______/|__|   |__|      |__|  ///////////  //   /  /
; /        Audio Driver for Pokémon Mini        ///////// //  /   /
; ////////////////////////////////////////////////////   /     /

; programmed by jvsTSX (just jvs for short if you want to)
; 2022, 3 months of development

; thanks to 
; YasaSheep, Jhynjhiruu, Scylus for helping me sort out the timer 3's registers and answering my overall doubts on the S1C88 asm
; TildeArrow and AkumaNatt for the Duty-to-Pivot code

; ...and thanks to all of the good people on the Pokémon mini discord, if i forgot someone please let me know
; (discord at this link: https://discord.com/invite/QZJaNZu, taken from the webpage: https://www.pokemon-mini.net/chat/)

; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// SETUP CODE / /   / /    /
; //////////////////////////////////////////////////////// /  / /   /    /  /

; HOW TO USE:
; load register pair HL with the #Label of your song header location and call the setup code, [label] will not work
; the label MUST be above the word locations of the song elements and the header MUST be correctly formatted
; otherwise you'll load garbage data into the RAM ADPM uses, there is no error detection

; HEADER FORMAT:

; LABEL
; DW YourSong Time Line Start
; DW YourSong Phrase Index Table Start
; DW YourSong Instrument Index Table Start
; DW YourSong Gmacro Index Table Start
; DB SONG RATE VALUE

DEFSECT    ".ADPM", CODE
SECT    ".ADPM"

GLOBAL _ADPMsongSetupCode
GLOBAL _ADPMsfxBlockSetupCode
GLOBAL _ADPMrunSFX
GLOBAL _ADPMengineA

_ADPMsongSetupCode:
	ld ix, [hl]
	ld [TmLineLocal], ix
	ld iy, ix ; i'll need this to initialize the phrase pos
	add hl, #2
	ld ix, [hl]
	ld [PhraseLocal], ix
	add hl, #2
	ld ix, [hl]
	ld [InstrmLocal], ix
	add hl, #2
	ld ix, [hl]
	ld [GmacroLocal], ix
	add hl, #2
	ld a, [hl]
	ld [TickAmmnt], a
	ld a, #0FFh
	ld [TickCount], a
	ld [SFXreq], a
	ld [FixedNoteReq], a
	
	; INIT FLAGS
	xor a, a
	ld [PitchFlag], a
	ld [Flags], a
	ld [PWMautoFlags], a ; 0
	ld [VolumeLevel], a
	ld [DutyOverride], a
	inc a
	ld [RestCounter], a
	
	; INIT SOUND POS
	ld hl, [iy]
	add iy, #2
	ld [TimeLinePos], iy
	ld [TransposeWait], h
	ld ix, [PhraseLocal]
	ld h, #0
	add hl, hl
	add hl, ix
	ld hl, [hl]
	ld [PhrasePos], hl
  ret

; SFX documentation:

; ADPM's SFX subengine is kept simple to minimize RAM usage, but it still lets you
; freely define a PWM duty rate, note, volume and also offset the current note you're at

; directory format:
; SFXdtaLocal -> SFXindexList -> SFXpattern

; on the SFX pattern:
; AWDPM-VVb

; A = Action     - tells whether the SFX ends or plays a note
; W = Wait       - requests an 8-bit wait time if this bit is set
; D = Duty       - requests an 8-bit duty rate if this bit is set
; P = Pitch      - requests a pitch value if this bit is set
; M = Mode       - defines what to do with the pitch value
;   0 = lookup pitch on the pitchlut; 1 = add/sub from Timer 3 current value
; - = not used   - yes
; V = Volume     - literal volume value for 2071h register

; POSSIBILITIES:

; 1000M-VVb
; 1100M-VVb, WWh
; 1110M-VVb, WWh, DDh
; 1111M-VVb, WWh, DDh, PPh
; 1010M-VVb, DDh
; 1001M-VVb, PPh
; 1011M-VVb, DDh, PPh
; 0-------b (ends SFX and unmutes music)


; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// SFX PATTERN EXECUTE / /   /
; //////////////////////////////////////////////////////// /  / /   /    /  /
_ADPMrunSFX:
	ld a, [SFXreq]
	inc a
  jrs z, ADPMsfxHandleSkip ; is it 0FFh?, if so: no SFX; skip
	inc a
  jrs z, ADPMsfxHandleContinueSFX ; is it 0FEh?, if so: continue running SFX
	; otherwise... initialize new SFX
	sub a, #2
	ld hl, [SFXdtaLocal]
	ld b, #0
	add a, a
	adc hl, ba
	ld hl, [hl]
	ld [SFXpos], hl
	ld a, #0FEh
	ld [SFXreq], a
	ld a, #01h
	ld [SFXrest], a
	
ADPMsfxHandleContinueSFX:
	ld hl, #SFXrest ; rest counter
	dec [hl]
  jrs nz, ADPMsfxHandleSkip

	ld iy, [SFXpos] ; get current command
	ld a, [iy]
	bit a, #10000000b ; is it an end command?
  jrs nz, ADPMsfxHandleActionCMD
	ld a, #0FFh
	ld [SFXreq], a
ADPMsfxHandleSkip:
  ret
	
ADPMsfxHandleActionCMD: ; otherwise action command
	ld b, a             ; copy command header into B
	and a, #00000011b
	ld [br:71h], a      ; apply volume
	and b, #11111000b   ; we only need the top 3 bits, B will be the only preserved reg
	inc b               ; (to preserve a value of how many bytes to skip in the end)
	
	; check for wait time
	xor a, a
	bit b, #01000000b
  jrs z, ADPMsfxWaitTimeIsOne
	inc iy
	ld a, [iy]
	inc b ; skip 2 bytes now
ADPMsfxWaitTimeIsOne:
	inc a
	ld [SFXrest], a

	; check for duty
	bit b, #00100000b
  jrs z, ADPMsfxSkipDuty
	inc b ; skip 2 (or 3) bytes now
	inc iy
	ld a, [iy]
	ld [SFXduty], a
ADPMsfxSkipDuty:

	; check for frequency value
	bit b, #00010000b
  jrs z, ADPMsfxNoPitchChange
	inc b ; skip 3 (or 2, or 1) bytes now
	inc iy
	ld a, [iy]
	bit b, #00001000b ; check mode, 1 = offset
  jrs nz, ADPMsfxPitchOffset
	; otherwise absol index value
	ld ix, #pitchLut
	add a, a
	ld l, a
	ld h, #0
	adc hl, ix
	ld hl, [hl]
	ld [204Ah], hl
  jrs ADPMsfxNoPitchChange
ADPMsfxPitchOffset:
	ld l, b
	sep ; if bit 7 is set, act as subtraction
	ld ix, [204Ah]
	add ix, ba
	ld [204Ah], ix
	ld b, l
	
ADPMsfxNoPitchChange:
	
; end section, how many bytes to skip?
	and b, #00000111b
	ex a, b
	ld hl, #SFXpos
	add [hl], a
	inc hl
	adc [hl], #0
	
; duty to frequency correction
	ld a, [SFXduty]
	ld l, [br:04Ah]
	mlt
	ld b, h
	ld l, [br:04Bh]
	mlt
	ld a, b
	ld b, #0
	add hl, ba
	ld [204Ch], hl
  ret

; SFX setup... i might remove it later because it's really not a big thing
_ADPMsfxBlockSetupCode:
	ld [SFXdtaLocal], hl
  ret

; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// MAIN SOUNDENGINE //// / /
; //////////////////////////////////////////////////////// /  / /   /    /  /


_ADPMengineA:


; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// KILL NOTE //// //  /    /
; //////////////////////////////////////////////////////// /  / /   /    /  /
	ld b, [Flags]
	bit b, #00001000b
  jrs z, ADPMkillNoteSkip
	ld hl, #KillNoteCount
	dec [hl]
  jrs nz, ADPMkillNoteSkip
	ld hl, #Flags
	and [hl], #10110111b ; disable macro and kill note count
	ld a, #0
	ld [VolumeLevel], a ; zero out the volume
ADPMkillNoteSkip:



; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// DELAY NOTE /////  // /
; //////////////////////////////////////////////////////// /  / /   /    /  /
	bit b, #00000100b
  jrs z, ADPMdelayNoteSkip
	ld hl, #DelayCount
	dec [hl]
  jrs nz, ADPMdelayNoteSkip
	
	ld a, [PendingNote]
	ld [CurrentNote], a
	ld l, [PendingInstr]
  carl ADPMnoteHandleDelayEnter
	
	ld hl, #Flags
	and [hl], #11111011b
ADPMdelayNoteSkip:



; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// GENERAL PURPOSE MACRO EXECUTE
; //////////////////////////////////////////////////////// /  / /   /    /  /
	ld b, [Flags]
	bit b, #01000000b   ; check if active
  jrs z, ADPMskipGmacro
	ld hl, #GMacroWaitCnt
	dec [hl]
  jrs nz, ADPMskipGmacro
	ld hl, #Flags
	or [hl], #00010000b
ADPMgmacroRepeatCMDfetch: ; same thing as main pattern stepper
	ld iy, [GMacroPos]    ; ...but at Engine A speed
	ld a, [iy]
	swap a
	and a, #0Fh
	add a, a
	ld b, #0
	ld hl, #ADPMgmacroCMDlist
	add hl, ba
	ld hl, [hl]
  jp hl

ADPMgmacroReturnSection:
	ld hl, #GMacroPos
	add [hl], a             ; reg A holds how many bytes the command had
  jrs nc, ADPMgmacroRepeatCMDfetch
	inc hl
	inc [hl]
  jrs ADPMgmacroRepeatCMDfetch
ADPMskipGmacro:



; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// PWM AUTO //////   / /    /
; //////////////////////////////////////////////////////// /  / /   /    /  /
	ld b, [PWMautoFlags]
	and b, #00000011b
  jrs z, ADPMpwmAutoSkip ; is it 0? if so it's disabled
	ld hl, #PWMautoShift ; rate decrementer
	dec [hl]
  jrs nz, ADPMpwmAutoSkip
	ld a, [PWMautoPreset] ; reload if zero and execute PWM routine code
	ld [hl], a
	
	ld ix, #PWMautoTarget
	ld hl, #PWMautoFlags
	dec b ; is it 0? if so ping-pong
	ld a, [PWMcurrent]
  jrs z, PWMautoHandlePingPong
	add a, [PWMautoRate]
  jrs c, PWMautoOverflowOthers
	cp a, [ix]
  jrs c, ADPMpwmAutoSkipWithWrite
PWMautoOverflowOthers:
	dec b
  jrs z, PWMautoHandleLoop
	; fall condition: once
	xor a, a
	ld [hl], a
  jrs ADPMpwmAutoSkip

PWMautoHandlePingPong:
	bit [hl], #80h
  jrs nz, PWMautoHandleSubtract
	add a, [PWMautoRate]
  jrs c, PWMautoOverflowPingPongUp
	cp a, [ix]
  jrs c, ADPMpwmAutoSkipWithWrite 
PWMautoOverflowPingPongUp:
	xor [hl], #80h
	ld a, [ix]
  jrs ADPMpwmAutoSkipWithWrite 

PWMautoHandleSubtract:
	dec ix
	sub a, [PWMautoRate]
  jrs c, PWMautoOverflowPingPongDown
	cp a, [ix]
  jrs nc, ADPMpwmAutoSkipWithWrite 
PWMautoOverflowPingPongDown:
	xor [hl], #80h
	ld a, [ix]
  jrs ADPMpwmAutoSkipWithWrite

PWMautoHandleLoop:
	ld a, [PWMautoLoop]
ADPMpwmAutoSkipWithWrite:
	ld [PWMcurrent], a
ADPMpwmAutoSkip:

; hey babe, you ok? you barely touched your JRS rat nest



; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// VIBRATO //////   / /    /
; //////////////////////////////////////////////////////// /  / /   /    /  /
	ld b, [PitchFlag]     ; check if active
	bit b, #00000001
  jrl z, ADPMvibratoSkip
	ld hl, #VibratoShift  ; tick counter
	dec [hl]
  jrl nz, ADPMvibratoSkip
	ld a, [VibratoPreset] ; reload counter
	ld [hl], a
	ld ix, [VibratoOffset]
	
	ld a, b
	srl b
	srl b
	and b, #00000011b
  jrs z, ADPMvibratoModeDownOnly
	dec b
  jrs z, ADPMvibratoModeUpOnly
	dec b
  jrs z, ADPMvibratoTriangleMode
	; fall condition: square wave mode
	ld hl, #VibratoOffset
	cpl [hl]
	inc hl
	cpl [hl]
  jrs ADPMvibratoSkip


ADPMvibratoModeDownOnly:
	ld a, [VibratoRate]
	add ix, ba ; remember B is 0 in order to enter here
  jrs ADPMvibratoSawReloadCheck

ADPMvibratoModeUpOnly:
	ld a, [VibratoRate]
	sub ix, ba

ADPMvibratoSawReloadCheck:
	ld hl, #VibratoProgCnt
	dec [hl]
  jrs nz, ADPMvibratoSawModeRelSkip
	ld a, [VibratoProgPre]
	ld [hl], a
	ld ba, ix
	cpl a
	cpl b
	ld [VibratoOffset], ba
  jrs ADPMvibratoSkip
 
ADPMvibratoSawModeRelSkip:
	ld [VibratoOffset], ix
  jrs ADPMvibratoSkip


ADPMvibratoTriangleMode:
	ld h, b
	ld l, [VibratoRate]
	bit a, #00000010b
  jrs nz, ADPMvibratoAltModeUp 
	
	sub ix, hl
  jrs ADPMvibratoAltModeCheckProg
	
ADPMvibratoAltModeUp:
	add ix, hl
	
ADPMvibratoAltModeCheckProg:
	ld [VibratoOffset], ix
	ld hl, #VibratoProgCnt
	dec [hl]
  jrs nz, ADPMvibratoSkip
	ld b, [VibratoProgPre]
	ld [hl], b
	xor a, #00000010b
	ld [PitchFlag], a
ADPMvibratoSkip:



; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// SWEEP / PORTAMENTO  //  /
; //////////////////////////////////////////////////////// /  / /   /    /  /
	ld b, [PitchFlag]   ; check if active
	bit b, #00010000b
  jrl z, ADPMsweepSkip
	ld hl, #SweepShift  ; tick counter
	dec [hl]
  jrl nz, ADPMsweepSkip
	ld a, [SweepPreset] ; reload counter
	ld [hl], a
	bit b, #00100000b   ; check mode
  jrl nz, ADPMsweepLinear

; /////////////////////////////////////////////////////// EXPONENTIAL ///
	ld l, [SweepRate]   ; get some values all snippets down from here will use
	ld h, #0
	add hl, hl          ; amplify rate value <256x is too slow>
	ld ix, [PitchProgrs]
	bit b, #01000000b   ; check diretcion
  jrs nz, ADPMsweepExpUp

	; /// exponential sweep down ///
	add ix, hl
	ld [PitchProgrs], ix
  jrl ADPMsweepSkip
  
ADPMsweepExpUp:
	; /// exponential sweep up ///
	sub ix, hl
	ld [PitchProgrs], ix
  jrl ADPMsweepSkip

ADPMsweepLinear: ; /////////////////////////////////////////// LINEAR ///
	ld hl, #SweepLinProgrs
	ld ix, #SweepRate
	ld a, [SweepGRA]
	or a, #11111100b    ; setup in a way where carry will set if we end up with a number larger than 3h
	bit b, #01000000b   ; check diretcion
	ld b, [ix]
  jrs z, ADPMsweepLinearDown

	srl b ; up
	srl b              ; b = sweeprate / 4
	add a, [ix]        ; prog + sweeprate
	ex a, b
	adc [hl], a        ; SweepLinProg <- sweeprate/4 + carry
	and b, #00000011b  ; clear bits
	ld [SweepGRA], b

	ld a, [hl] ; check limit
	add a, [Transpose]
	add a, [CurrentNote]
	cp a, #53h
  jrs c, ADPMsweepLinNoOvUp
	ld a, [PitchFlag]
	bit a, #10000000b
  jrs nz, ADPMDisableSweepLin
	sub [hl], #53h
ADPMsweepLinNoOvUp:

	ld b, [PitchFlag] ; portamento check
	bit b, #10000000b
  jrs z, ADPMsweepSkip
	ld a, [hl]
	add a, [Transpose]
	add a, [CurrentNote]
	ld b, [SweepGRB]
	cp a, b
  jrs ge, ADPMDisableSweepLin
  jrs ADPMsweepSkip

ADPMsweepLinearDown: ; down
	srl b
	srl b              ; b = sweeprate / 4
	add a, [ix]
	ex a, b
	sbc [hl], a        ; sweeprate/4 + carry
	and b, #00000011b  ; clear bits
	ld [SweepGRA], b

	ld a, [hl] ; check limit
	add a, [Transpose]
	add a, [CurrentNote]
	cp a, #053h
  jrs c, ADPMsweepLinNoOvDown
  	ld a, [PitchFlag]
	bit a, #10000000b
  jrs nz, ADPMDisableSweepLin
	add [hl], #53h
ADPMsweepLinNoOvDown:

	ld a, [PitchFlag] ; portamento check
	bit a, #10000000b
  jrs z, ADPMsweepSkip
	ld a, [hl]
	add a, [Transpose]
	add a, [CurrentNote]
	ld b, [SweepGRB]
	cp a, b
  jrs le, ADPMDisableSweepLin
  jrs ADPMsweepSkip

ADPMDisableSweepLin:
	ld hl, #PitchFlag
	and [hl], #00001111b ; disable sweep
	xor a, a
	ld [SweepGRA], a
	ld a, [SweepGRB]
	sub a, [CurrentNote]
	ld [SweepLinProgrs], a
ADPMsweepSkip:



; tick counter for entering Engine B section
	ld hl, #TickAmmnt
	ld a, [hl]
	inc hl ; note to self: 16-bit and 8-bit INC/DEC take the same amount of time
	add [hl], a
  jrl c, ADPMengineB

; check for SFX run state
	ld a, [SFXreq]
	inc a
  jrs z, ADPMpitchCalcNotRet
  ret
ADPMpitchCalcNotRet:

; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// PITCH CALCULATION / //  /
; //////////////////////////////////////////////////////// /  / /   /    /  /
ADPMpitchCalc:	
	ld ix, #pitchLut
	ld ba, [Transpose] ; A = transpose, B = fixed note request
	inc b              ; check if there is a fixed note waiting to be played, 0FFh = disabled
  jrs z, ADPMpitchCalcEntry

; fixed note calc
	dec b
	ld l, b
	ld h, #0
	add hl, hl ; skip odd entries
	add hl, ix ; merge with pitch lut
	ld ba, [hl]
  jrs ADPMpitchCalcFixedExit

ADPMpitchCalcEntry: ; //////////////////// ACTIVE CASE PITCH PIPE
	; step 1: calculate index
	; A holds transpose
	add a, [CurrentNote]
	add a, [ProgrsIndex]
	add a, [SweepLinProgrs]
	add a, a ; skip odd entries
	ld h, #0
	ld l, a
	add hl, ix ; merge with pitch lut
	ld b, [PitchFlag]
	bit b, #00100000b ; check sweep mode (NECESSARY BECAUSE GRA ALSO HOLD EXP SWEEP DATA)
  jrs z, ADPMpitchCalcASIS
	
	
	; step 2: calculate linear sweep
	ld a, [SweepGRA]
	or a, a                ; is it zero?
  jrs z, ADPMpitchCalcASIS ; if yes don't bother with all this mess below
	bit b, #01000000b      ; check direction
  jrs z, ADPMpitchCalcLinSweepUp
 
	ld ix, [hl]          ; down
	dec hl
	dec hl
	ld iy, [hl]
  jrs ADPMpitchCalcJRLtower

ADPMpitchCalcLinSweepUp: ; up
	ld ix, [hl]
	inc hl
	inc hl
	ld iy, [hl]

ADPMpitchCalcJRLtower:
	ld l, a
	ld ba, iy  ; copy into BA
	add ba, ix
	rr b
	rr a
	dec l
  jrs z, ADPMpitchCalcLinCnt1 ; is it 1? interp twice
	dec l
  jrs z, ADPMpitchCalcSkipLin ; is it 2? interp once (skip to end)
	; fall condition;  bottom top top
	add ba, ix
	rr b
	rr a
  jrs ADPMpitchCalcSkipLin

ADPMpitchCalcASIS: ; exit 0: no interpolation
	ld ba, [hl]
  jrs ADPMpitchCalcSkipLin

ADPMpitchCalcLinCnt1: ; bottom bottom top
	add ba, iy
	rr b
	rr a

	; step 4: calculate raw pitch value
ADPMpitchCalcSkipLin:
	ld iy, [PitchProgrs]
	add ba, iy
	ld iy, [VibratoOffset]
	add ba, iy
ADPMpitchCalcFixedExit:
	ld [204Ah], ba ; T3 preset
	
	; check for duty override request
	ld a, [DutyOverride]
	or a, a
  jrs z, PitchCalcNoOverrideDuty
  jrs PitchCalcOverrideDuty
	
PitchCalcNoOverrideDuty:
	; step 5: correct the pulse duty value (Pivot)
	ld a, [PWMcurrent]
PitchCalcOverrideDuty:
	ld l, [br:04Ah]
	mlt
	ld b, h
	ld l, [br:04Bh]
	mlt
	ld a, b
	ld b, #0
	add hl, ba
	ld [204Ch], hl ; timer 3 pivot low

	; step 6: apply volume
	ld a, [VolumeLevel]
	bit a, #10000000b
  jrs z, PitchCalcNoVolumeOverride
	swap a
	PitchCalcNoVolumeOverride:
	and a, #00000011b
	ld [br:71h], a
  ret

; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// PHRASE STEPPER / /   /
; //////////////////////////////////////////////////////// /  / /   /    /  /
ADPMengineB:
	; rest counter, will only go forwards if it's 0
	ld hl, #RestCounter
	dec [hl]
  jrs nz, ADPMengineBquit

	; reset continuity flag
	ld hl, #Flags
	or [hl], #10000000b

	; check where we are on the phrase
NextCMD:
	ld iy, [PhrasePos]
	ld a, [iy] ; l = current command
	and a, #0F0h
	swap a
	add a, a

	ld hl, #CMDlist
	ld b, #0
	add hl, ba
	ld hl, [hl]
  jp hl

ADPMengineBquit:
  ret

ADPMreturnSection:      	; return from CMD handler
	ld hl, #PhrasePos
	add [hl], a             ; reg A holds how many bytes the command had
  jrs nc, NextCMD
	inc hl
	inc [hl]
  jrs NextCMD



; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// HANDLERS / /   /
; //////////////////////////////////////////////////////// /  / /   /    /  /

ADPMnoteHandler:
	ld a, [iy] ; get note index
	bit a, #10000000b
  jrs z, ADPMnoteHandleUseInstrum
	and a, #01111111b ; get rid of the instrument skip bit
	ld [CurrentNote], a
	ld b, #2
	ld l, [LastInstrument]
  jrs ADPMnoteHandleInstrumentLookup
	
ADPMnoteHandleUseInstrum:
	ld [CurrentNote], a
	ld b, #3
	inc iy
	ld l, [iy]
ADPMnoteHandleDelayEnter:
	ld [LastInstrument], l
	
ADPMnoteHandleInstrumentLookup:
	ld ix, [InstrmLocal]
	ld h, #0
	add hl, hl
	add ix, hl
	ld iy, [ix]

	; detune
	ld a, [iy]
	ld ix, #0
	ld [VibratoOffset], ix
	ld l, b
	sep
	ld [PitchProgrs], ba
	ld b, l

	; pulse ratio
	inc iy
	ld a, [iy]
	ld [PWMcurrent], a

	; Gmacro
	inc iy
	ld a, [iy]
	ld hl, #Flags
	and [hl], #10111111b ; disable Gmacro bit
	inc a                ; is it 0FF?
  jrs z, ADPMnoteHandleSkipGmacro
	dec a
	or [hl], #01000000b  ; enable Gmacro
	ld ix, [GmacroLocal] ; get index local
	ld l, a
	ld h, #0
	add hl, hl    ; skip odd entries
	add ix, hl    ; merge with index table local
	ld ix, [ix]   ; reference from the index we're at
	ld [GMacroPos], ix  ; load new position
	ld a, #01h          ; initialize wait counter
	ld [GMacroWaitCnt], a
	
ADPMnoteHandleSkipGmacro:

	; Volume and PWM auto settings
	inc iy
	ld a, [iy]
	ld hl, #VolumeLevel
	and a, #00000011b
	and [hl], #11111100b
	or [hl], a
	ld a, [iy]
	swap a
	and a, #00000011b ; clear leftover volume bits
	ld hl, #PWMautoFlags
	and [hl], #00h
	or [hl], a
	or a, a                ; is it 0?
  jrs z, ADPMnoteHandleEnd ; if yes, don't write PWM values as we'll not use it at all

	; PWM auto definitions
	inc iy
	ld hl, [iy]
	ld [PWMautoPreset], l
	ld [PWMautoShift], l
	ld [PWMautoRate], h
	inc iy
	inc iy
	ld hl, [iy]
	ld [PWMautoLoop], hl ; load loop and target

ADPMnoteHandleEnd:
	; clear/reset parameters
	xor a, a
	ld [SweepLinProgrs], a
	ld [ProgrsIndex], a
	ld hl, #PitchFlag
	and [hl], #11101110b
	ld a, [TransposeWait]
	ld [Transpose], a
  ret



; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// COMMANDS' CODE / /   /
; //////////////////////////////////////////////////////// /  / /   /    /  /

PlayNote: ; ============================================================================
	; continuity check
	ld hl, #Flags
	bit [hl], #10000000b
  jrs z, ADPMplayNoteExit
	and [hl], #01111111b

	; set rest counter <X param>
	ld b, [iy]
	inc b
	ld [RestCounter], b

	; call note handler
	inc iy
  carl ADPMnoteHandler

	ld a, b ; get ammount of bytes to skip
  jrl ADPMreturnSection

ADPMplayNoteExit:
	ld a, [SFXreq]
	inc a
  carl z, ADPMpitchCalc
  ret



EndPhrase: ; ============================================================================
	; get current phrase index
	ld hl, #TimeLinePos
	ld ix, [hl]
	ld ba, [ix]
	ld [TransposeWait], b
	ld b, #0
	
	; step timeline
	add [hl], #2
  jrs nc, ADPMtimeLineIncNoCarry0
	inc hl
	inc [hl]
ADPMtimeLineIncNoCarry0:
	
	; write new phrase pos
	ld hl, [PhraseLocal]
	add a, a
	adc hl, ba
	ld hl, [hl]
	ld [PhrasePos], hl
  jrl NextCMD



EndSong: ; ============================================================================
	inc iy
	ld a, [iy] ; get offset value (in timeline steps)
	ld b, #0
	ld ix, [TmLineLocal]
	add a, a
	adc ba, ix
	ld hl, #TimeLinePos
	ld [hl], ba
	
	; get current phrase index
	ld ix, [hl]
	ld ba, [ix]
	ld [TransposeWait], b
	ld b, #0
	
	; step timeline
	add [hl], #2
  jrs nc, ADPMtimeLineIncNoCarry1
	inc hl
	inc [hl]
ADPMtimeLineIncNoCarry1:
	
	; write new phrase pos
	ld hl, [PhraseLocal]
	add a, a
	adc hl, ba
	ld hl, [hl]
	ld [PhrasePos], hl
  jrl NextCMD



SetTMRvolume: ; ============================================================================
	; uhhh sure i'll do this one why not lol
	ld a, [iy]
	and a, #00000011b
	ld hl, #VolumeLevel
	and [hl], #11111100b
	or [hl], a
	ld a, #01h
  jrl ADPMreturnSection



AddToDetune: ; =============================================================================
	inc iy
	ld a, [iy]
	sep
	ld hl, [VibratoOffset]
	add hl, ba
	ld [VibratoOffset], hl
	ld a, #02h
  jrl ADPMreturnSection



SetRest: ; =================================================================================
	; continuity check
	ld hl, #Flags
	bit [hl], #10000000b
  jrl z, ADPMsetRestExit
	and [hl], #01111111b
	
	ld a, [iy]
	and a, #00Fh
	ld b, a
	add a, #0F1h
  jrs nz, SetRestOneByte
	inc iy
	ld a, [iy]
	inc a
	ld [RestCounter], a
	
	ld a, #02h
  jrl ADPMreturnSection

SetRestOneByte:
	inc b
	ld [RestCounter], b

	ld a, #01
  jrl ADPMreturnSection

ADPMsetRestExit:
	ld a, [SFXreq]
	inc a
  carl z, ADPMpitchCalc
  ret

SetTMRduty: ; ===============================================================================
	inc iy
	ld a, [iy]
	ld [PWMcurrent], a
	ld a, #02h
  jrl ADPMreturnSection



SetSNGrate: ; ===============================================================================
	ld a, [iy]
	inc iy
	bit a, #00000010b ; check whether to set rate or tempo (timer 1 or 2)
  jrs nz, SetTimerVal ; 4 bytes if so
	; otherwise set rate
	ld a, [iy]
	ld [TickAmmnt], a
	ld a, #02
  jrl ADPMreturnSection

SetTimerVal:
	ld hl, [iy] ; get timer value
	add iy, #2
	bit a, #00000001b ; check what timer to write to: 1 = timer 2, 0 = timer 1
	ld a, #04
  jrs z, SetTimerValTimer2
	ld [203Ah], hl
	ld [br:18h], [iy]
  jrl ADPMreturnSection
	
SetTimerValTimer2:
	ld [2032h], hl
	ld [br:1Ah], [iy]
  jrl ADPMreturnSection

; FUTURE: USE NIBBLE TO TOGGLE BETWEEN TEMPO AND RATE
; THE FUTURE IS NOW



KillNote: ; =================================================================================
	; NOTE: Kill note counter will automatically treat itself as disabled once it expires
	inc iy
	ld a, [iy]
	inc a
	ld [KillNoteCount], a
	ld hl, #Flags
	or [hl], #00001000b
	
	ld a, #02h
  jrl ADPMreturnSection



SetGmacro: ; ================================================================================
	ld a, [iy]
	inc iy
	bit a, #00000001b
	ld a, [iy]
  jrs nz, SetGmacroOffsetMode
	; otherwise absol value
	ld b, #0
	add ba, ba
	ld ix, [GmacroLocal]
	add ix, ba
	ld ix, [ix]
	ld [GMacroPos], ix
	
	; enable Gmacro flag
	ld hl, #Flags
	or [hl], #01000000b
	ld a, #01
	ld [GMacroWaitCnt], a
	
	ld a, #02h
  jrl ADPMreturnSection
	
SetGmacroOffsetMode:
	; notice this mode does not turn on the Gmacro if it's previously disabled
	sep ; act like subtraction if value is 80h+
	ld hl, [GMacroPos]
	add hl, ba
	ld [GMacroPos], hl
	ld a, #02h
  jrl ADPMreturnSection



DelayedNote: ; ==============================================================================
	; NOTE: delay counter will automatically treat itself as disabled once it expires
	inc iy
	ld a, [iy]
	inc a
	ld [DelayCount], a

	inc iy
	ld ba, [iy]
	ld [PendingNote], ba ; initialize both pending note and instrument
	
	ld hl, #Flags
	or [hl], #00000100b
	ld a, #04h
  jrl ADPMreturnSection



Sweep: ; ==================================================================================== 
	ld a, [iy]
	ld hl, #PitchFlag
	and a, #00000111b
	swap a
	and [hl], #0Fh
	or  [hl], a
	ld h, a

	inc iy
	ld a, [iy]
	ld b, a
	ld [SweepShift], ba
	inc iy
	ld a, [iy]
	ld [SweepRate], a

	bit a, #00100000b
  jrs nz, ADPMsweepCMDlin
ADPMsweepCMDlinOut:
	
	ld a, #03h
  jrl ADPMreturnSection

ADPMsweepCMDlin:
	ld a, #0FFh
	ld [SweepGRA], a
  jrs ADPMsweepCMDlinOut



PortamentoNote: ; ===========================================================================
	; continuity check
	ld hl, #Flags
	bit [hl], #10000000b
  jrs z, ADPMportaNoteExit
	and [hl], #01111111b

	ld a, [iy]
	ld hl, #PitchFlag
	and a, #00001111b
	or a,  #00001010b
	swap a
	and [hl], #0Fh
	or  [hl], a
	ld h, a

	inc iy
	ld a, [iy]
	ld b, a
	ld [SweepShift], ba
	inc iy
	ld a, [iy]
	ld [SweepRate], a

	inc iy
	ld b, [iy]
	ld a, #0h
	ld [SweepGRA], ba

	; rest time
	inc iy
	ld a, [iy]
	inc a
	ld [RestCounter], a

	ld a, #5h
  jrl ADPMreturnSection
	


ADPMportaNoteExit:
	ld a, [SFXreq]
	inc a
  carl z, ADPMpitchCalc
  ret


Vibrato: ; ==================================================================================
	ld ba, [iy]  ; recieve flags and rate
	and a, #00Fh ; clear high nibble because we don't need it
	ld hl, #PitchFlag
	and [hl], #0F0h ; clear vibrato bits
	or  [hl], a     ; apply new bits	
	ld [VibratoRate], b

	add iy, #02 ; 1 more byte but 1 less cycle
	ld a, [PitchFlag]
	and a, #00001100b
	cp a, #0Ch
  jrs nz, ADPMcmdVibratoModeNormalApply
	ld ix, [VibratoOffset] ; prepare start pos
	srl b
	xor a, a
	ex a, b
	add ix, ba
	ld [VibratoOffset], ix
	
	ld ba, [iy]
	ld [VibratoShift],  b
	ld [VibratoPreset], b
	
	ld a, #04h
  jrl ADPMreturnSection
	
ADPMcmdVibratoModeNormalApply:
	ld ba, [iy] ; recieve limit count and time shift values
	ld [VibratoProgPre], a
	srl a
	ld [VibratoProgCnt], a
	ld [VibratoShift],  b
	ld [VibratoPreset], b
	
	ld a, #04h
  jrl ADPMreturnSection



PWMauto: ; ==================================================================================
	ld a, [iy]
	and a, #00000011b
	ld hl, #PWMautoFlags
	and [hl], #01111100b
	or  [hl], a

	inc iy
	ld a, [iy]
	ld b, a
	ld [PWMautoShift], ba
	inc iy
	ld a, [iy]
	ld [PWMautoRate], a
	inc iy
	ld ba, [iy]
	ld [PWMautoLoop], ba
	
	
	ld a, #05h
  jrl ADPMreturnSection



LegatoNote: ; ==================================================================================
	; continuity check
	ld hl, #Flags
	bit [hl], #10000000b
  jrs z, ADPMcmdLegatoNoteExit
	and [hl], #01111111b
	
	ld a, [iy]
	and a, #0Fh
	inc a
	ld [RestCounter], a
	
	inc iy
	ld a, [iy]
	ld [CurrentNote], a
	
	ld a, [TransposeWait]
	ld [Transpose], a
	
	ld a, #02h
  jrl ADPMreturnSection

ADPMcmdLegatoNoteExit:
	ld a, [SFXreq]
	inc a
  carl z, ADPMpitchCalc
  ret

; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// GMACRO CMD CODE /// /
; //////////////////////////////////////////////////////// /  / /   /    /  /

SetNote: ; ===============================================================================
	ld a, [iy]
	inc iy
	bit a, #00000001b ; is it relative (arpeggio) or fixed?
	ld a, [iy]        ; recieve the value
  jrs z, ADPMsfxNoteSetRelative
	; otherwise fixed
	ld [FixedNoteReq], a
	ld a, #2
  jrl ADPMgmacroReturnSection
	
ADPMsfxNoteSetRelative:
	ld hl, #ProgrsIndex
	add [hl], a
	ld a, #0FFh
	ld [FixedNoteReq], a
	ld a, #2
  jrl ADPMgmacroReturnSection



SetDuty: ; ===============================================================================
	ld a, [iy]
	inc iy
	bit a, #00000001b
	ld a, [iy]
  jrs z, ADPMsfxDutySetRelative
	; otherwise absol value
	ld [PWMcurrent], a
	ld a, #2h
  jrl ADPMgmacroReturnSection
	
ADPMsfxDutySetRelative:
	ld hl, #PWMcurrent
	add [hl], a
	ld a, #2h
  jrl ADPMgmacroReturnSection



WaitTicks: ; =============================================================================
	; continuity check
	ld hl, #Flags
	bit [hl], #00010000b
  jrl z, ADPMskipGmacro
	and [hl], #11101111b
	
	ld a, [iy]
	and a, #00Fh
	ld b, a
	add a, #0F1h ; will be zero if the wait value is Fh
  jrs nz, SetRestOneByteGmacro
	inc iy
	ld a, [iy]
	inc a
	ld [GMacroWaitCnt], a
	
	ld a, #02
  jrl ADPMgmacroReturnSection

SetRestOneByteGmacro:
	inc b
	ld [GMacroWaitCnt], b

	ld a, #01
  jrl ADPMgmacroReturnSection



EndMacro: ; ==============================================================================
	inc iy
	ld a, [iy]
	inc a
  jrs nz, ADPMgmacroPosOffset
	; kill macro if value is 0FFh
	ld hl, #Flags
	and [hl], #10111111b
  jrl ADPMskipGmacro

ADPMgmacroPosOffset:
	dec a
	sep
	ld ix, [GMacroPos]
	add ix, ba
	ld [GMacroPos], ix
  jrl ADPMgmacroRepeatCMDfetch



ChangeMacro: ; ===========================================================================
	inc iy
	ld a, [iy]
	
	ld ix, [GmacroLocal]
	ld b, #0
	add ba, ba
	add ix, ba
	ld ix, [ix]
	ld [GMacroPos], ix
  jrl ADPMgmacroRepeatCMDfetch



SetVolume: ; =============================================================================
	ld a, [iy]
	ld hl, #VolumeLevel
	and a, #00000011b
	and [hl], #11111100b
	or [hl], a
	ld a, #01
  jrl ADPMgmacroReturnSection



KillNoteGmacro: ; ========================================================================
	ld hl, #Flags
	and [hl], #10110100b
	ld a, #0
	ld [VolumeLevel], a
  jrl ADPMskipGmacro



OverrideCtrl: ; ==========================================================================
	; PPPPO-VV DDDDDDD
	ld a, [iy]
	and a, #0Fh
	swap a
	ld hl, #VolumeLevel
	and [hl], #01001111b
	or [hl], a
	inc iy
	ld a, [iy]
	ld [DutyOverride], a
	
	ld a, #2
  jrl ADPMgmacroReturnSection



; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// LIBRARY SPACE - DO NOT MODIFY /   / 
; //////////////////////////////////////////////////////// /  / /   /    /  /

CMDlist:
dw PlayNote          ; 0 - PX YY ZZ - X = rest; Y = note index; Z = instrument val; Y's bit 7 is instrument ignore
dw EndPhrase         ; 1 - P-
dw EndSong           ; 2 - P- XX
dw SetTMRvolume      ; 3 - PX
dw AddToDetune       ; 4 - P- XX
dw SetRest           ; 5 - PX YY              X: wait time if it's not FF, otherwise YY is requested as wait time
dw SetTMRduty        ; 6 - P- XX
dw SetSNGrate        ; 7 - PX YY / PX YY YY ZZ    X: --RT R=rate select; 0=rate, 1=tempo (timer); T=timer select; (not effective if rate is select) 0=timer 1, 1=timer 2
dw KillNote          ; 8 - P- XX
dw SetGmacro         ; 9 - PX YY              X: ---R R=relative, 0=absol, 1=add/sub to position (signed)
dw DelayedNote       ; A - P- XX YY ZZ        X: wait time, Y: note index, Z: instrument index
dw Sweep             ; B - PX YY ZZ           X: flags, Y: shift, Z: rate
dw PortamentoNote    ; C - PX YY ZZ WW VV     X: flags, Y: shift, Z: rate,  W: note,   V: rest
dw Vibrato           ; D - PX YY ZZ WW        X: flags, Y: rate,  Z: limit, W: shift
dw PWMauto           ; E - PX YY ZZ WW VV     X: flags, Y: speed, Z: rate,  W: loop,   V: target
dw LegatoNote        ; F - PX YY              X: rest,  Y: note

ADPMgmacroCMDlist: ; for use with Gmacro
dw SetNote          ; 0 - PX YY              X: flags, Y: value
dw SetDuty          ; 1 - PX YY
dw WaitTicks        ; 2 - P- XX              X: value
dw EndMacro         ; 3 - P- XX              X: reset offset, 0FFh = auto disable
dw ChangeMacro      ; 4 - P- XX              X: macro index
dw SetVolume        ; 5 - PX
dw KillNoteGmacro   ; 6 - P-
dw OverrideCtrl     ; 7 - PX YY              X: flags and volume, Y: duty

pitchLut:
; octave 1
dw 0EEEEh ; C 1     0
dw 0E186h ; C#1     1
dw 0DAD2h ; D 1     2
dw 0C8E6h ; D#1     3
dw 0BD98h ; E 1     4
dw 0B2FFh ; F 1     5
dw 0A8F0h ; F#1     6
dw 09F74h ; G 1     7
dw 09680h ; G#1     8
dw 08E0Dh ; A 1     9
dw 08614h ; A#1     A
dw 07E8Eh ; B 1     B

; octave 2
dw 07771h ; C 2     C
dw 070BEh ; C#2     D
dw 06A6Bh ; D 2     E
dw 06471h ; D#2     F
dw 05ECEh ; E 2     10
dw 0597Ch ; F 2     11
dw 05476h ; F#2     12
dw 04FB9h ; G 2     13
dw 04B40h ; G#2     14
dw 04705h ; A 2     15
dw 04309h ; A#2     16
dw 03F45h ; B 2     17

; octave 3
dw 03BB8h ; C 3     18
dw 0385Eh ; C#3     19
dw 03534h ; D 3     1A
dw 03232h ; D#3     1B
dw 02F66h ; E 3     1C
dw 02CBDh ; F 3     1D
dw 02A3Bh ; F#3     1E
dw 027DCh ; G 3     1F
dw 0250Fh ; G#3     20
dw 02383h ; A 3     21
dw 02184h ; A#3     22
dw 01FA2h ; B 3     23

; octave 4
dw 01DDCh ; C 4     24
dw 01C2Fh ; C#4     25
dw 01A9Ah ; D 4     26
dw 0191Bh ; D#4     27
dw 017B3h ; E 4     28
dw 0165Eh ; F 4     29
dw 0151Dh ; F#4     2A
dw 013EDh ; G 4     2B
dw 012CFh ; G#4     2C
dw 011C0h ; A 4     2D
dw 010C1h ; A#4     2E
dw 00FD1h ; B 4     2F

; octave 5
dw 00EEDh ; C 5     30
dw 00E17h ; C#5     31
dw 00D4Ch ; D 5     32
dw 00C8Dh ; D#5     33
dw 00BD9h ; E 5     34
dw 00B2Eh ; F 5     35
dw 00A8Eh ; F#5     36
dw 009F6h ; G 5     37
dw 00967h ; G#5     38
dw 008E0h ; A 5     39
dw 00860h ; A#5     3A
dw 007E8h ; B 5     3B

; octave 6
dw 00776h ; C 6     3C
dw 0070Bh ; C#6     3D
dw 006A6h ; D 6     3E
dw 00646h ; D#6     3F
dw 005ECh ; E 6     40
dw 00597h ; F 6     41
dw 00546h ; F#6     42
dw 004FBh ; G 6     43
dw 004B3h ; G#6     44
dw 0046Fh ; A 6     45
dw 00430h ; A#6     46
dw 003F4h ; B 4     47

; octave 7
dw 003BBh ; C 7     48
dw 00385h ; C#7     49
dw 00352h ; D 7     4A
dw 00322h ; D#7     4B
dw 002F5h ; E 7     4C
dw 002CBh ; F 7     4D
dw 002A2h ; F#7     4E
dw 0027Dh ; G 7     4F
dw 00259h ; G#7     50
dw 00237h ; A 7     51
dw 00217h ; A#7     52
dw 001F9h ; B 7     53

; fun fact: register value 0383h is 2222,22Hz



; instrument format: detune, duty, macro, PWM config & volume, PWM speed, PWM rate, PWM loop and PWM target

; FFh, DDh, GGh, --SS--VVb, SSh, RRh, LLh, TTh

; F - fine-tune     : bit 7: direction, bit 6-0: ammount
; D - duty          : 80h = square
; G - General Macro : 8-bit index; 0FFh is disabled
; S - PWM mode      : 00 = disabled; 01 = single shot; 10 = loop; 11 = ping-pong
; V - volume        : 00 = mute; 01 and 10 = 50%; 11 = 100%
; S, R, L, T are in order with the format description

; note : if S is 0, the instrument system will ignore the last 3 bytes


; PLAY NOTE FORMAT

; 0R NN II - R: Rest; N: Note index; I: Instrument 

; note index's bit 7 will toggle off the next instrument fetch and use the last played instrument
; making it 2 bytes long in the process instead of 3



; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// SONG DATA //// / /   /    /
; //////////////////////////////////////////////////////// /  / /   /    /  /

SongData:
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

SFXdata:
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




; ////////////////////////////////////////////////// /  /     /  /
; /////////////////////////////////////////// RESERVED RAM SPACE / /   /
; //////////////////////////////////////////////////////// /  / /   /    /  /
DEFSECT ".RAMspace", DATA
SECT ".RAMspace"

; song data origin
TmLineLocal:      ds 2
PhraseLocal:      ds 2
InstrmLocal:      ds 2
GmacroLocal:      ds 2
SFXdtaLocal:      ds 2

; Engine A reserved RAM space 

; Length counters
DelayCount:       ds 1
PendingNote:      ds 1
PendingInstr:     ds 1
KillNoteCount:    ds 1
; Pulse Width Modulation Auto
PWMautoShift:     ds 1
PWMautoPreset:    ds 1
PWMautoRate:      ds 1
PWMcurrent:       ds 1
PWMautoLoop:      ds 1
PWMautoTarget:    ds 1
PWMautoFlags:     ds 1
; Macro
GMacroPos:        ds 2
GMacroWaitCnt:    ds 1
; pitch Auto Shared data
PitchFlag:        ds 1
CurrentNote:      ds 1
ProgrsIndex:      ds 1
PitchProgrs:      ds 2
SweepLinProgrs:   ds 1
VibratoOffset:    ds 2
TransposeWait:    ds 1
Transpose:        ds 1
FixedNoteReq:     ds 1
; Sweep auto
SweepShift:       ds 1
SweepPreset:      ds 1
SweepRate:        ds 1
SweepGRA:         ds 1 ; mode 0 - target freq. low    mode 1 - step counter  |  target indices are not used
SweepGRB:         ds 1 ;          targer freq. high            target index  |  if portamento flag is reset
; Sound Effects
SFXreq:           ds 1 ; FF = disabled; FE = playing, any = pending
SFXrest:          ds 1 ; wait time
SFXpos:           ds 2
SFXduty:          ds 1
; Vibrato Auto
VibratoShift:     ds 1
VibratoPreset:    ds 1
VibratoRate:      ds 1
VibratoProgCnt:   ds 1
VibratoProgPre:   ds 1
; misc
DutyOverride:     ds 1 ; for Gmacro drums, 00 = disabled
VolumeLevel:      ds 1 ; Z-XX--YY; Z = override volume toggle, X = override value, Y = current volume (music)
; tick counter for Engine B entry
TickAmmnt:        ds 1
TickCount:        ds 1
; Engine B: pattern and timeline handling
RestCounter:      ds 1
Flags:            ds 1
TimeLinePos:      ds 2
PhrasePos:        ds 2
LastInstrument:   ds 1

; current RAM usage: 63 bytes

; flag bits:
; 7 - continuity check         1 = fetch      0 = stop
; 6 - Gmacro enable            1 = on         0 = off
; 5 - SFX continuity check     1 = fetch      0 = stop ; to remove
; 4 - Gmacro continuity check  1 = fetch      0 = stop
; 3 - Kill count enable        1 = on         0 = off
; 2 - Delay count enable       1 = on         0 = off
; 1 - 
; 0 - 


; pitch flag bits:
; 7 - portamento on/off  0 = sweep        1 = portamento
; 6 - sweep direction    0 = down         1 = up
; 5 - sweep mode         0 = exponential  1 = proportional
; 4 - sweep enable       0 = off          1 = on
; 3 - vibrato mode       \
; 2 - vibrato mode       0 = down only    1 = up only    2 = alternate    3 = square
; 1 - vibrato direction  0 = down         1 = up
; 0 - vibrato enable     0 = off          1 = on

; PWM auto flag bits
; 7 - working direction <for ping-pong mode>
; 6 -
; 5 -
; 4 -
; 3 -
; 2 -
; 1 - PWM auto mode bit
; 0 - PWM auto mode bit        0 = off     1 = single shot    2 = loop     3 = ping-pong

DEFSECT ".ScreenData", ROMDATA
SECT ".ScreenData"

align 8
TileBase:
db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0C0h, 0C0h, 00h, 00h, 00h, 00h, 00h
db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 80h, 80h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 80h, 80h, 0B0h, 0B0h, 0A0h, 0BEh, 9Eh, 80h, 8Eh, 9Eh, 0B8h
db 9Eh, 8Eh, 80h, 0ACh, 0AEh, 0AAh, 0BAh, 9Ah, 80h, 81h, 80h, 80h, 80h, 00h, 00h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h
db 80h, 80h, 80h, 80h, 80h, 80h, 80h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 80h, 60h, 18h, 06h, 01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0FFh, 00h, 00h, 00h, 00h
db 00h, 0F8h, 08h, 08h, 08h, 08h, 18h, 60h, 80h, 00h, 01h, 06h, 18h, 7Fh, 80h, 00h, 00h, 00h, 00h, 0F8h, 08h, 08h, 08h, 08h, 08h, 08h, 0F8h, 00h, 00h, 01h, 06h, 18h, 0E0h
db 00h, 00h, 00h, 01h, 06h, 18h, 60h, 80h, 80h, 60h, 18h, 06h, 01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0FFh, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 80h, 60h, 18h, 06h, 01h, 00h, 00h, 00h, 10h, 1Ch, 1Fh, 00h, 00h, 00h, 00h, 00h, 0FFh, 00h, 00h, 00h, 00h, 00h, 0FFh, 00h, 00h, 00h
db 00h, 00h, 00h, 01h, 0FEh, 00h, 00h, 00h, 00h, 01h, 0FEh, 00h, 00h, 00h, 0F1h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 10h, 0F0h, 10h, 10h, 10h, 1Fh, 00h, 0FEh, 18h, 60h
db 80h, 00h, 00h, 01h, 01h, 00h, 00h, 80h, 60h, 18h, 0FEh, 00h, 00h, 00h, 00h, 00h, 0FFh, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
db 00h, 80h, 60h, 18h, 06h, 01h, 00h, 00h, 80h, 60h, 18h, 06h, 02h, 02h, 02h, 0FEh, 00h, 00h, 00h, 00h, 00h, 0FFh, 00h, 00h, 00h, 00h, 00h, 7Fh, 40h, 40h, 40h, 40h, 60h
db 18h, 06h, 01h, 00h, 80h, 60h, 0F8h, 06h, 01h, 00h, 00h, 00h, 0FFh, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0FFh, 00h, 00h, 00h, 00h, 00h, 0FFh, 00h, 00h, 01h, 06h, 18h
db 60h, 60h, 18h, 06h, 01h, 00h, 00h, 0FFh, 00h, 00h, 00h, 00h, 00h, 0FFh, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 76h, 0F5h, 0C4h
db 0F4h, 74h, 04h, 0E4h, 0F6h, 51h, 70h, 60h, 00h, 0F0h, 0F0h, 60h, 37h, 14h, 04h, 04h, 04h, 04h, 07h, 24h, 0F4h, 0F4h, 04h, 04h, 04h, 0E4h, 0F4h, 14h, 0F4h, 0E4h, 04h, 04h
db 04h, 06h, 01h, 00h, 07h, 04h, 04h, 04h, 04h, 04h, 07h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 07h, 04h, 04h, 94h, 0D4h, 54h, 77h, 20h, 00h, 0E0h, 0F0h, 10h, 0F0h, 0E0h
db 00h, 90h, 0D0h, 50h, 70h, 27h, 04h, 94h, 0D4h, 54h, 74h, 27h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, 00h, 00h, 00
db 00h, 01h, 01h, 01h, 00h, 00h, 01h, 01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, 01h, 00h, 01h, 00h, 00h, 01h, 01h, 01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, 01h, 01h, 01h, 01h, 00h, 00h, 01h, 01h, 01h, 00h, 00h, 01h, 01h, 01h, 01h, 01h
db 00h, 01h, 01h, 01h, 01h, 01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0AAh, 0AAh, 0AAh, 0AAh, 0AAh, 0AAh, 0AAh, 0AAh, 0AAh, 0AAh, 0FEh, 82h, 0EAh, 0E6h, 0FEh, 86h
db 0EEh, 0F6h, 0FEh, 0CEh, 0A6h, 0A6h, 0FEh, 0A6h, 0A6h, 96h, 0FEh, 0A6h, 0A6h, 96h, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 82h, 0BAh, 0C6h, 0FEh, 0EEh, 0FEh, 86h, 0D6h, 0EEh, 0FEh
db 96h, 96h, 8Eh, 0FEh, 9Eh, 0AEh, 86h, 0FEh, 0FEh, 0FEh, 0FEh, 0EEh, 86h, 0EAh, 0FEh, 0CEh, 0B6h, 0CEh, 0FEh, 86h, 0EEh, 0F6h, 0FEh, 0FEh, 0FEh, 0B6h, 0AAh, 0AAh, 0DAh
db 0FEh, 82h, 0EAh, 0FAh, 0FEh, 0BAh, 0D6h, 0EEh, 0D6h, 0BAh, 0FEh, 0AAh, 0AAh, 0AAh, 0AAh, 0AAh,0AAh, 0AAh, 0AAh, 0AAh, 0AAh, 0AAh