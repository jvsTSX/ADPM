DEFSECT    ".ADPM", CODE
SECT    ".ADPM"

GLOBAL _ADPM_RUN
GLOBAL _ADPM_SETUP
GLOBAL _ADPM_SFXbank
GLOBAL _ADPM_SFXdir
GLOBAL _ADPMrunSFX
GLOBAL _ADPM_SFXoverlay

; //////////////////////////////////////////////////////////
;           ____ ______   ______ ____    ____       _--------_
;         /     |   __  \|   __  \   \  /    |     | _-====-_ ||
;        /  /|  |  |  \  \  |__|  |   \/     |    | #|""""""|# ||
;       /  /_|  |  |   |  |  _____||\    /|  |    ||#|      |#|||
;      /  ___   |  |   |  | |   |  | \  / |  |    | #|______|# |
;     /  /   |  |  |__/  /  |   |  |  \/  |  |   |   ""====""   |
;    /__/    |__|_______/|__|   |__|      |__|   |  _+_  o    O |
;                Audio Driver for Pokémon Mini    \  +   .  O   |
;                       jvsTSX  /  2022 - 2023     """"""==--.. |
; //////////////////////////////////////////////////////////   "

;	 2022, 3 months of development (1.0)
;	 2023, many months of procrastination (1.1)

;	 thanks to 
;	 YasaSheep, Jhynjhiruu, Scylus for helping me sort out the timer 3's registers and answering my overall doubts on the S1C88 asm
;	 TildeArrow and AkumaNatt for the Duty-to-Pivot code
;	 jesse-stojan for the frequency interpolation formula
;	 Lyra for mentioning me use cases for Fixed pitch Gmacro (leading to a little behaviour change, check the DOCUMENTATION section)
;
;	 ...and thanks to all of the good people on the Pokémon mini discord, if i forgot someone please let me know
;	 (discord at this link: https://discord.com/invite/QZJaNZu, taken from the webpage: https://www.pokemon-mini.net/chat/)
;
;	features
;	- Vibrato and portamento, both with proportional ranges
;	- General purpose macro (Gmacro)
;	- Kill and Delayed note counters
;	- B-0 to B-7 note range
;	- 8-bit PWM formula
;	- Fixed notes for better drums
;	- comes with a Sound effects sub-driver (can be optionally removed)



;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                       SFX SUBDRIVER                        ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//
_ADPMrunSFX:
	ld a, [_ADPM_SFXoverlay]
	inc a
  jrs z, SFX_Done ; is it 0FFh?, if so: no SFX; skip
	inc a
  jrs z, SFX_Running ; is it 0FEh?, if so: continue running SFX
	; otherwise... initialize new SFX
	sub a, #2
	ld iy, [_ADPM_SFXdir]
	ld b, #0
	add ba, ba
	add iy, ba
	
	ld a, [_ADPM_SFXbank]
	ld yp, a
	
	ld iy, [iy]
	ld [SFXpos], iy
	ld a, #0FEh
	ld [_ADPM_SFXoverlay], a
  jrs SFX_Start
	
SFX_Running:
	ld a, [_ADPM_SFXbank]
	ld yp, a
	ld hl, #SFXwait ; rest counter
	dec [hl]
  jrs nz, SFX_Done

SFX_Start:
	ld iy, [SFXpos] ; get current command
	ld a, [iy]
	bit a, #10000000b ; is it an end command?
  jrs nz, SFX_Act
	ld a, #0FFh
	ld [_ADPM_SFXoverlay], a
SFX_Done:
  ret
	
SFX_Act: ; otherwise action command
	ld b, a             ; copy command header into B
	and a, #00000011b
	ld [br:71h], a      ; apply volume
	
	; check for wait time
	xor a, a
	bit b, #01000000b
  jrs z, SFX_WaitIsOne
	inc iy
	ld a, [iy]
SFX_WaitIsOne:
	inc a
	ld [SFXwait], a

	; check for duty
	bit b, #00100000b
  jrs z, SFX_NoDuty
	inc iy
	ld a, [iy]
	ld [SFXduty], a
SFX_NoDuty:

	; check for frequency value
	bit b, #00010000b
  jrs z, SFX_NoFreq
	inc iy
	ld a, [iy]
	bit b, #00001000b ; check mode, 1 = offset
  jrs nz, SFX_Sweep
	; otherwise absol index value
	ld hl, #pitchLut
	ld b, #0
	add a, a
	adc hl, ba
	ld hl, [hl]
	xor l, #0FFh
	xor h, #0FFh
  jrs SFX_FreqDone

SFX_Sweep:
	sep ; if bit 7 is set, act as subtraction
	ld hl, [204Ah]
	add hl, ba
SFX_FreqDone:
	ld [204Ah], hl
SFX_NoFreq:
	
; end section, how many bytes to skip?
	inc iy
	ld [SFXpos], iy

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



;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                         SETUP CODE                         ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//
_ADPM_SETUP:
	ld [SongBank], a ; current song bank
	ld xp, a
;	ld yp, a
	ld hl, [ix]
	ld [TmLineLocal], hl
	ld iy, hl; i'll need this to initialize the phrase pos
	add ix, #2
	ld hl, [ix]
	ld [PhraseLocal], hl
	add ix, #2
	ld hl, [ix]
	ld [InstrmLocal], hl
	add ix, #2
	ld hl, [ix]
	ld [GmacroLocal], hl
	add ix, #2
	ld hl, [ix]
	ld [GrooveLocal], hl
	add ix, #2
	ld a, [ix]
	ld [TickReload], a
	ld a, #0FFh
	ld [_ADPM_SFXoverlay], a
	ld [NoteOverlay], a
	
	; INIT FLAGS
	xor a, a
	ld [PitchState], a
	ld [WorkFlags], a
	ld [VolumeLevel], a
	ld [DutyOverlay], a
	inc a ; 1
	ld [WaitCount], a
	ld [TickCount], a
	
	; INIT SOUND POS
	ld ix, iy
	ld hl, [ix] ; get current timeline position
	add ix, #2
	ld [TimeLinePos], ix
	ld [TransposeNext], h
	ld ix, [PhraseLocal]
	ld h, #0
	add hl, hl
	add ix, hl
	ld ix, [ix]
	ld [PhrasePos], ix
  ret



;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                       DRIVER BLOCK A                       ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//
_ADPM_RUN:
	ld a, [SongBank]
	ld yp, a

; Kill note count
	ld b, [WorkFlags]
	bit b, #00000001b
  jrs z, KILL_End
	ld hl, #KillCount
	dec [hl]
  jrs nz, KILL_End
	ld hl, #WorkFlags
	and [hl], #11111010b
	ld a, #0FFh
	ld [NoteOverlay], a
	xor a, a
	ld [VolumeLevel], a
KILL_End:

; Delay note handle
	bit b, #00000010b
  jrs z, DELAY_End
	ld hl, #DelayCount
	dec [hl]
  jrs nz, DELAY_End
	ld ba, [PendingNote]
	and a, #01111111b
	ld [CurrntNote], a
	ld a, b
	ld b, #0
  carl INSTRUMENT_PROCESS ; B must be 0; A is the instrument you want to process
	ld hl, #WorkFlags ; disable delay
	and [hl], #11111101b
DELAY_End:

;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                          PWM AUTO                          ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//
	ld b, [WorkFlags]
	bit b, #00110000b
  jrs z, PWMAUTO_Done
	ld hl, #PWMwait
	dec [hl]
  jrs nz, PWMAUTO_Done
	ld a, [PWMreload]
	ld [hl], a
	
	ld a, [PWMrate]
	ld hl, #PWMcurr
	ld ix, #PWMtrgt
	; what mode are we running?
	; 00 = off
	; 01 = ping-pong
	; 10 = loop
	; 11 = once
	bit b, #00100000b
  jrs z, PWMAUTO_PingPong

	; loop or once
	add [hl], a
  jrs c, PWMAUTO_Hit
	cp [hl], [ix]
  jrs c, PWMAUTO_Done
PWMAUTO_Hit:
	bit b, #00010000b
  jrs z, PWMAUTO_RelLoop
	; or else once
	ld [hl], [ix]
	ld hl, #WorkFlags
	and [hl], #11001111b
  jrs PWMAUTO_Done

PWMAUTO_RelLoop:
	dec ix ; = loop now
	ld [hl], [ix]
  jrs PWMAUTO_Done

PWMAUTO_PingPong:
	; ping-pong
	bit b, #01000000b
  jrs z, PWMAUTO_PingUp
	dec ix ; = loop now
	sub [hl], a
  jrs c, PWMAUTO_PingHitDown
	cp [hl], [ix]
  jrs nc, PWMAUTO_Done
PWMAUTO_PingHitDown:
	ld [hl], [ix]
  jrs PWMAUTO_Flip
	
PWMAUTO_PingUp:
	add [hl], a
  jrs c, PWMAUTO_PingHitUp
	cp [hl], [ix]
  jrs c, PWMAUTO_Done
PWMAUTO_PingHitUp:
	ld [hl], [ix]

PWMAUTO_Flip:
	ld hl, #WorkFlags
	xor [hl], #01000000b
PWMAUTO_Done:



;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                          VIBRATO                           ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//



; REDO THIS SCHEIBECODE
; AND THEN ADD SFX SUBDRIVER

	ld b, [PitchState]
	bit b, #10000000b
  jrs z, VIBRA_Done
	ld hl, #VibratoWait
	dec [hl]
  jrs nz, VIBRA_Done
	ld a, [VibratoReload]
	ld [hl], a

	ld hl, #VibratoPos
	ld a, [VibratoRate]
	ld ix, #VibratoLut

	; this vibrato algorythm is a LUT-based vibrato with some MLT math
	; better than the ADPM 1.0 algorythm because it is
	; - range propotional
	; - friendly to mid-note changes
	bit b, #00100000b
  jrs nz, VIBRA_UpOrDown
	bit b, #00010000b
  jrs nz, VIBRA_Square
	; triangle
	and a, #00001111b ; todo: see if i can delay this to not affect square mode
	add [hl], a ; step lut
	and [hl], #00011111b ; mask lut
	ld l, [hl] ; get index
	ld a, [ix+l] ; reference lut
	ld [VibratoProg], a
  jrs VIBRA_DepthAndWrite
	
VIBRA_Square:
	xor b, #01000000b
	bit b, #01000000b
	ld [PitchState], b
  jrs nz, VIBRA_Write
	neg a
  jrs VIBRA_Write
	
VIBRA_UpOrDown:
	and a, #00001111b ; todo: see if i can delay this to not affect square mode
	add [hl], a
	and [hl], #00001111b
	ld l, [hl]
	ld a, [ix+l]
	
	bit b, #00010000b
  jrs z, VIBRA_DepthAndWrite
	neg a
	
VIBRA_DepthAndWrite:
	ld b, a
	ld a, [VibratoRate]
	swap a
	and a, #00001111b
	inc a
	ld l, a
	ld a, b
	mlt
	ld a, l
VIBRA_Write:
	ld [VibratoProg], a
	
VIBRA_Done:



;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                      SWEEP PORTAMENTO                      ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//
	ld b, [PitchState]
	bit b, #00001000b
  jrl z, SWEEP_Done
	ld hl, #SweepWait
	dec [hl]
  jrs nz, SWEEP_Done
	ld a, [SweepReload]
	ld [hl], a
	
	ld ix, #SweepInterp
	
	bit b, #00000100b ; check direction
	ld a, [SweepRate]
	upck
  jrs nz, SWEEP_Down
	; up
	or a, #11110000b
	add a, [ix]
	ex a, b
	ld hl, #SweepIndCnt
	adc [hl], a
	and b, #00001111b
	ld [ix], b
	
	ld b, [PitchState]
	bit b, #00000010b ; is it portamento?
  jrs z, SWEEP_Done
	ld a, [hl]
	add a, [CurrntNote]
	cp a, [SweepTrgt]
  jrs c, SWEEP_Done
  jrs SWEEP_Disable
	
SWEEP_Down:
	ld l, b
	ld b, a
	ld a, [ix]
	sub a, b
	ld b, a
	ld a, l
	ld hl, #SweepIndCnt
	sbc [hl], a
	and b, #00001111b
	ld [ix], b
	
	ld b, [PitchState]
	bit b, #00000010b ; is it portamento?
  jrs z, SWEEP_Done
	ld a, [hl]
	add a, [CurrntNote]
;	cp a, #53h
  jrs nc, SWEEP_Disable ; if it adds a negative number and gives you a negative result you know it past its target
	cp a, [SweepTrgt]
  jrs nc, SWEEP_Done

SWEEP_Disable:
	ld a, [SweepTrgt]
	ld [CurrntNote], a
	and b, #11110111b
	ld [PitchState], b
	xor a, a
	ld b, a
	ld [SweepInterp], ba
		
SWEEP_Done:



;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                           GMACRO                           ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//
	ld b, [WorkFlags]
	bit b, #00000100b ; check if Gmacro is enabled
  jrl z, GM_Done
	ld hl, #GmacroWait
	dec [hl]
  jrl nz, GM_Done

	ld iy, [GmacroPos]
GM_Decode:
	ld a, [iy] ; first byte: header
	bit a, #10000000b ; check if it's an action command
  jrs nz, GM_EventRowProcess

	; ///////////////////////////////////////// end or loop
	or a, a
  jrs nz, GM_Disable
	; zero - loop macro
	inc iy
	ld a, [iy]
	ld b, #0
	sub iy, ba
	ld [GmacroPos], iy
	
	ld a, [iy]
	or a, a
  jrs nz, GM_Decode    ; if the incoming byte is zero after the offset this is not good
GM_Disable:            ; it will get the CPU caught in a loop and crash your entire main loop
	ld hl, #WorkFlags  
	and [hl], #11111011b ; so for when this happen, this check is here to stop the macro
  jrl GM_Done

	; ///////////////////////////////////////// begin action
GM_EventRowProcess:
	ld b, a
	bit b, #01000000b ; first bit: retrigger
  jrs z, GM_SkipRetrigger
	or [br:48h], #00000010b
GM_SkipRetrigger:
	bit b, #00100000b ; second bit: wait req
	ld a, #1
  jrs z, GM_WaitIsOne
	inc iy
	add a, [iy]
GM_WaitIsOne:
	ld [GmacroWait], a

	ld hl, #VolumeLevel
	ld a, b
	and a, #00000011b ; get volume stuff
	bit b, #00010000b ; third bit: pitch mode
  jrs z, GM_NormalNote

	; ///////////////////////////////////////// fixed note
	cp a, #10b
  jrs z, GM_FixedIgnoreVol
	swap a
	and [hl], #11001111b
	or [hl], a ; apply volume
GM_FixedIgnoreVol:
	inc iy ; get fixed note
	ld a, [iy]
	ld [NoteOverlay], a
	bit b, #00000100b ; check duty
	ld a, [PWMcurr]
  jrs z, GM_FixedLastDuty
	inc iy
	ld a, [iy]
GM_FixedLastDuty:
	ld [DutyOverlay], a
  jrs GM_DonePos
	
GM_NormalNote: ;  ////////////////////////////// normal note
	cp a, #10b
  jrs z, GM_IgnoreVol
	and [hl], #11111100b
	or [hl], a ; apply volume
GM_IgnoreVol:
	bit b, #00001000b ; note offset (for arps)
  jrs z, GM_RelNoNote
	inc iy
	ld a, [iy]
	ld [OffsetNote], a
GM_RelNoNote:
	bit b, #00000100b ; PWM
  jrs z, GM_RelNoDuty
	inc iy
	ld a, [iy]
	ld [PWMcurr], a
GM_RelNoDuty:
	ld a, #0FFh
	ld [NoteOverlay], a ; disable overlay if it was on previously
	
GM_DonePos:
	inc iy
	ld [GmacroPos], iy
GM_Done:


;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                         PITCH PIPE                         ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//
	ld a, [_ADPM_SFXoverlay]
	cp a, #0FFh
  jrl nz, TickCounter ; check for SFX
	ld a, [NoteOverlay]
	cp a, #0FFh
  jrs z, PITCH_Normal ; check for fixed note 
	ld hl, #pitchLut
	ld b, #0
	add a, a
	adc hl, ba
	ld hl, [hl]
	xor l, #0FFh
	xor h, #0FFh
	
	ld a, [VolumeLevel]
	swap a
	and a, #00000011b
	ld [br:71h], a
	
	ld a, [DutyOverlay]
  jrl PITCH_EndWrites
	
PITCH_Normal:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; BASIC MATH
	ld a, [VibratoProg]
	upck ; b = index offset (signed), a = interpolate offset (unsigned)
	add a, [Detuning]
	add a, [SweepInterp]
	ld l, a ; save it into L for later, high is index low is interp
	
	; now for the index
	; sign extend the result, we are looking at the high nibble of A reg
	bit a, #10000000b
  jrs nz, PITCH_SignExResult
	and a, #11110000b
  jrs PITCH_SkipSignExRes
PITCH_SignExResult:
	or a, #00001111b
PITCH_SkipSignExRes:
	swap a
	
	; sign extend the vibrato index, we are looking at the Low nibble of B reg
	bit b, #00001000b
  jrs nz, PITCH_SignExVibrato
	and b, #00001111b
  jrs PITCH_SkipSignExVibr
PITCH_SignExVibrato:
	or b, #11110000b
PITCH_SkipSignExVibr:

	add a, b ; vibrato + result index offset
	add a, [CurrntNote]
	add a, [OffsetNote]
	add a, [SweepIndCnt]
	add a, [TransposeCurr]
	ld h, a
	
	ld b, [PitchState]   ; check if sweep is on
	bit b, #00001000b
  jrs z, PITCH_Clobber
	bit b, #00000010b    ; is it a portamento?
  jrs nz, PITCH_Clobber

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; WRAP
	; otherwise just wrap the range as the sweep functions
	ld ix, #SweepIndCnt
	bit b, #00000100b ; wrap up or down?
  jrs z, PITCH_WrapUp
  
	cp a, #53h
  jrs c, PITCH_RangeDone
	ld a, [ix]
	add a, #53h 
	ld [ix], a
  jrs PITCH_RangeDone
	
PITCH_WrapUp:
	cp a, #53h
  jrs c, PITCH_RangeDone
	ld a, [ix]
	sub a, #53h 
	ld [ix], a
  jrs PITCH_RangeDone

PITCH_Clobber: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CLOBBER
	cp a, #053h
  jrs c, PITCH_RangeDone ; taken: in-range, no problem
	; or else clobber
	cp a, #0A9h ; ACh / 2 = 56h + 53h = A9h
  jrs c, PITCH_ClobberToTop
	; or else clobber to bottom
	ld hl, #0000h
  jrs PITCH_RangeDone
	
PITCH_ClobberToTop:
	ld hl, #5300h

PITCH_RangeDone: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTERPOLATE
	; H = index, L = interpolation
	; grab pitch value
    ld ix, #pitchLut
    ld a, h
    ld b, #0
    add ba, ba ; note lut is 2 bytes per entry
    add ix, ba
    ld iy, [ix] ; NoteX
    add ix, #2
    ld ix, [ix] ; NoteY
    
    ; Pitch = (((NoteX - NoteY) * Point) >> 8) + NoteX
    ld ba, iy
    sub ix, ba ; get delta
    ld a, l
    and a, #00001111b ; A = Point
    swap a
    ld hl, ix
    ld b, h
    mlt
    ld l, b ; L being trashed causes the '>> 8' part
    ld b, h
    mlt
    ld a, b
    ld b, #0
    add hl, ba ; complete the multiplication
    add hl, iy ; final + NoteX
    xor h, #0FFh ; invert to store into the timer 3 registers
    xor l, #0FFh
	
	ld a, [VolumeLevel] ; apply volume
	ld [br:71h], a
	ld a, [PWMcurr] ; grab current PWM
PITCH_EndWrites:
	ld [204Ah], hl ; store pitch
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; PWM ADJUST
	; Pivot = (Pitch * PWMcurr) >> 8
	ld l, [br:04Ah]
	mlt
	ld b, h
	ld l, [br:04Bh]
	mlt
	ld a, b
	ld b, #0
	add hl, ba
	ld [204Ch], hl ; timer 3 pivot low
; note to self  -  MUL:  L * A = HL



;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                       DRIVER BLOCK B                       ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//
TickCounter:
	ld hl, #TickCount ; tick counter
	dec [hl]
  jrs nz, QUIT
	
	ld iy, [GrooveLocal] ; process groove
	ld l, [TickReload]
	ld a, [iy+l]
	cp a, #0FFh
  jrs nz, GT_Continue
	; otherwise end
	inc l
	ld a, [iy+l]
	ld [TickReload], a
	ld l, a
	ld a, [iy+l]
GT_Continue:
	inc a
	ld [TickCount], a
	inc l
	ld [TickReload], l

	ld hl, #WaitCount ; check wait counter
	dec [hl]
  jrs nz, QUIT
	ld hl, #WorkFlags ; reset continue flag
	or [hl], #10000000b
NextCMD:
	ld iy, [PhrasePos]
	ld a, [iy]
	and a, #11110000b
	swap a

	ld hl, #CMDlist
	ld b, #0
	add a, a
	add hl, ba
	ld hl, [hl]
  jp hl

CMDreturn: ; register A must hold the amount to offset
	ld hl, #PhrasePos
	add [hl], a
  jrs nc, NextCMD
	inc hl
	inc [hl]
  jrs NextCMD

QUIT:
  ret



;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                        LIBRARY SPACE                       ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//

CMDlist:
dw CMD_PlayNote	    ; 2-3 bytes  :  0X YY ZZ
dw CMD_EndEvent	    ; 1-2 bytes  :  10 XX   or   11
dw CMD_Wait         ; 1-2 bytes  :  2F XX   or   2X
dw CMD_KillNote     ;  2  bytes  :  3- XX
dw CMD_DelayNote    ; 3-4 bytes  :  4- XX YY ZZ
dw CMD_RunGmacro    ;  2  bytes  :  5- XX
dw CMD_SetDuty      ;  2  bytes  :  6- XX
dw CMD_SetSpeed     ;  2  bytes  :  7X YY

dw CMD_Portamento   ;  4  bytes  :  8X YY ZZ WW
dw CMD_Sweep        ;  3  bytes  :  9X YY ZZ
dw CMD_Vibrato      ;  3  bytes  :  AX YY ZZ
dw CMD_PWMauto      ; 1-5 bytes  :  BX YY ZZ WW VV
dw CMD_Volume       ;  1  byte   :  CX
dw CMD_Legato       ;  2  bytes  :  DX YY
dw CMD_Detune       ;  1  byte   :  EX
dw CMD_Null         ;  1  byte   :  F-     ; basically a driver NOP



pitchLut:
; octave 0
dw ~0FD17h ; B-0     0

; octave 1
dw ~0EEEEh ; C 1     1
dw ~0E186h ; C#1     2
dw ~0DAD2h ; D 1     3
dw ~0C8E6h ; D#1     4
dw ~0BD98h ; E 1     5
dw ~0B2FFh ; F 1     6
dw ~0A8F0h ; F#1     7
dw ~09F74h ; G 1     8
dw ~09680h ; G#1     9
dw ~08E0Dh ; A 1     A
dw ~08614h ; A#1     B
dw ~07E8Eh ; B 1     C

; octave 2
dw ~07771h ; C 2     D
dw ~070BEh ; C#2     E
dw ~06A6Bh ; D 2     F
dw ~06471h ; D#2     10
dw ~05ECEh ; E 2     11
dw ~0597Ch ; F 2     12
dw ~05476h ; F#2     13
dw ~04FB9h ; G 2     14
dw ~04B40h ; G#2     15
dw ~04705h ; A 2     16
dw ~04309h ; A#2     17
dw ~03F45h ; B 2     18

; octave 3
dw ~03BB8h ; C 3     19
dw ~0385Eh ; C#3     1A
dw ~03534h ; D 3     1B
dw ~03232h ; D#3     1C
dw ~02F66h ; E 3     1D
dw ~02CBDh ; F 3     1E
dw ~02A3Bh ; F#3     1F
dw ~027DCh ; G 3     20
dw ~0250Fh ; G#3     21
dw ~02383h ; A 3     22
dw ~02184h ; A#3     23
dw ~01FA2h ; B 3     24

; octave 4
dw ~01DDCh ; C 4     25
dw ~01C2Fh ; C#4     26
dw ~01A9Ah ; D 4     27
dw ~0191Bh ; D#4     28
dw ~017B3h ; E 4     29
dw ~0165Eh ; F 4     2A
dw ~0151Dh ; F#4     2B
dw ~013EDh ; G 4     2C
dw ~012CFh ; G#4     2D
dw ~011C0h ; A 4     2E
dw ~010C1h ; A#4     2F
dw ~00FD1h ; B 4     30

; octave 5
dw ~00EEDh ; C 5     31
dw ~00E17h ; C#5     32
dw ~00D4Ch ; D 5     33
dw ~00C8Dh ; D#5     34
dw ~00BD9h ; E 5     35
dw ~00B2Eh ; F 5     36
dw ~00A8Eh ; F#5     37
dw ~009F6h ; G 5     38
dw ~00967h ; G#5     39
dw ~008E0h ; A 5     3A
dw ~00860h ; A#5     3B
dw ~007E8h ; B 5     3C

; octave 6
dw ~00776h ; C 6     3D
dw ~0070Bh ; C#6     3E
dw ~006A6h ; D 6     3F
dw ~00646h ; D#6     40
dw ~005ECh ; E 6     41
dw ~00597h ; F 6     42
dw ~00546h ; F#6     43
dw ~004FBh ; G 6     44
dw ~004B3h ; G#6     45
dw ~0046Fh ; A 6     46
dw ~00430h ; A#6     47
dw ~003F4h ; B 4     48

; octave 7
dw ~003BBh ; C 7     49
dw ~00385h ; C#7     4A
dw ~00352h ; D 7     4B
dw ~00322h ; D#7     4C
dw ~002F5h ; E 7     4D
dw ~002CBh ; F 7     4E
dw ~002A2h ; F#7     4F
dw ~0027Dh ; G 7     50
dw ~00259h ; G#7     51
dw ~00237h ; A 7     52
dw ~00217h ; A#7     53
dw ~001F9h ; B 7     54

; fun fact: register value 0383h is 2222,22Hz

VibratoLut: ; vibrato algorythm:
db 0F8h ; use all the table length = triangle
db 0F9h ; use only 4 bits of VibratoPos = saw up
db 0FAh ; use only 4 bits of VibratoPos + complement = saw down
db 0FBh ; use direction bit to complement depth = square
db 0FCh
db 0FDh
db 0FEh
db 0FFh
db 000h ; <- initial state
db 001h
db 002h
db 003h
db 004h
db 005h
db 006h
db 007h
db 008h
db 008h
db 007h
db 006h
db 005h
db 004h
db 003h
db 002h
db 001h
db 000h
db 0FFh
db 0FEh
db 0FDh
db 0FCh
db 0FBh
db 0FAh
db 0F9h
db 0F8h


;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                       COMMANDS' CODE                       ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//

CMD_PlayNote: ; //////////////////////////////////////////////////////////////////////////////////// 0
	ld hl, #WorkFlags
	bit [hl], #10000000b
  jrs z, CMD_Note_ContinueIsZero
	and [hl], #01111111b
	
	ld a, [TransposeNext]
	ld [TransposeCurr], a
	
	ld a, [iy] ; grab wait value
	inc a
	ld [WaitCount], a
	
	inc iy ; grab note index
	ld a, [iy]

	bit a, #10000000b
  jrs nz, CMD_Note_ReuseInstrm
	ld [CurrntNote], a
	inc iy
	ld a, [iy] ; get instrument index
	ld [LastInstrm], a
	ld b, #3
  jrs CMD_Note_SkipInstrm
	
CMD_Note_ReuseInstrm:
	and a, #01111111b
	ld [CurrntNote], a
	ld a, [LastInstrm]
	ld b, #2
CMD_Note_SkipInstrm:
	push b
	ld b, #0
  cars INSTRUMENT_PROCESS
	pop a
  jrl CMDreturn

CMD_Note_ContinueIsZero:
  ret

INSTRUMENT_PROCESS:
	; word[index*2 + local]
	ld iy, [InstrmLocal]
	add ba, ba
	add iy, ba
	ld iy, [iy]
	ld a, [iy] ; get Gmacro

	ld hl, #WorkFlags
	and [hl], #10001011b ; note: also makes flags ready to recieve PWM auto settings
	cp a, #0FFh
  jrs z, INSTRPROC_GmacroSkip
	or [hl], #00000100b
	
	ld ix, iy ; IY for ROM access ONLY
	ld iy, [GmacroLocal]
	ld b, #0
	add ba, ba
	add iy, ba
	ld iy, [iy]
	ld [GmacroPos], iy
	ld a, #1
	ld [GmacroWait], a
	ld iy, ix	
INSTRPROC_GmacroSkip:
	
	inc iy
	ld ba, [iy] ; pulse duty and then misc values
	ld [PWMcurr], a
	
	ld a, b
	and a, #00001111b
	sub a, #8
	ld [Detuning], a
	
	ld a, b ; apply PWM mode and check if it's off
	and a, #00110000b
	or [hl], a ; HL = WorkFlags
	
	ld a, b ; apply volume level
	ld hl, #VolumeLevel
	rlc a
	rlc a
	and a, #00000011b
	and [hl], #11111100b
	or [hl], a
	
	bit b, #00110000b
  jrs z, INSTRPROC_EXIT
	add iy, #2
	ld ba, [iy] ; wait and then rate
	ld [PWMreload], ba
	ld [PWMwait], a
	add iy, #2
	ld ba, [iy] ; loop and then target
	ld [PWMloop], ba

INSTRPROC_EXIT:
	; clear/reset parameters
	xor a, a
	ld b, a
	ld [SweepInterp], ba
	ld [OffsetNote], a
	ld [VibratoProg], a
	ld [PitchState], a
	ld a, #8
	ld [VibratoPos], a
	ld a, #1
	ld [VibratoWait], a
  ret



CMD_EndEvent: ; //////////////////////////////////////////////////////////////////////////////////// 1
; END SONG PROCEDURE:    TimeLinePos  = offset*2 + [TimeLineLocal] ; then do below
; END PHRASE PROCEDURE:  NewTranspose = byte[TimeLinePos + 1]
;                        TimeLinePos  + 2
;                        PhrasePos    = word[ byte[TimeLinePos + 0]*2 + word[PhraseLocal] ]
	ld a, [iy]
	bit a, #00000001b
  jrs nz, CMD_EndEv_NxtPhra

	; otherwise it's end song
	ld hl, [TmLineLocal]
	inc iy
	ld a, [iy] ; grab offset parameter
	ld b, #0
	add a, a ; *2 then add
	adc hl, ba
	ld iy, hl
  jrs CMD_EndEv_EndToPhra
	
CMD_EndEv_NxtPhra:
	ld iy, [TimeLinePos] ; grab new timeline parameter
CMD_EndEv_EndToPhra:
	ld ba, [iy]
	ld [TransposeNext], b
	ld b, #0

	add iy, #2
	ld [TimeLinePos], iy

	ld iy, [PhraseLocal] ; write new phrase position
	add ba, ba
	add iy, ba
	ld iy, [iy]
	ld [PhrasePos], iy
  jrl NextCMD


CMD_Wait: ; //////////////////////////////////////////////////////////////////////////////////////// 2
	ld hl, #WorkFlags
	bit [hl], #10000000b
  jrs z, CMD_Wait_ContinueIsZero
	and [hl], #01111111b

	ld a, [iy]
	cp a, #2Fh
  jrs z, CMD_Wait_TwoBytes
	; or else one byte
	and a, #00001111b
	inc a
	ld [WaitCount], a
	ld a, #1
  jrl CMDreturn

CMD_Wait_TwoBytes:
	inc iy
	ld a, [iy]
	inc a
	ld [WaitCount], a
	ld a, #2
  jrl CMDreturn

CMD_Wait_ContinueIsZero:
  ret

CMD_KillNote: ; //////////////////////////////////////////////////////////////////////////////////// 3
	inc iy
	ld a, [iy]
	inc a
	ld [KillCount], a
	ld hl, #WorkFlags
	or [hl], #00000001b
	ld a, #2
  jrl CMDreturn



CMD_DelayNote: ; /////////////////////////////////////////////////////////////////////////////////// 4
	ld hl, #WorkFlags ; enable delay
	or [hl], #00000010b
	inc iy
	ld ba, [iy] ; wait and then note
	inc a
	ld [DelayCount], ba
	add iy, #2
	bit b, #10000000b ; check for instrument bit
  jrs nz, CMD_Delay_NoInstrm
	ld a, [iy]
	ld [PendingInstr], a
	ld a, #4
  jrl CMDreturn

CMD_Delay_NoInstrm:
	ld a, [LastInstrm]
	ld [PendingInstr], a
	ld a, #3
  jrl CMDreturn



CMD_RunGmacro: ; /////////////////////////////////////////////////////////////////////////////////// 5
; GmacroPos = word[ byte[PhrasePos]*2 + word[GmacroLocal] ]
	ld a, [iy]
	inc iy
	bit a, #00000001b
	ld a, [iy]
  jrs nz, CMD_Gmacro_Relative

	; or else absol
	ld hl, #WorkFlags
	and [hl], #11111011b
	cp a, #0FFh
  jrs z, CMD_Gmacro_Skip
	or [hl], #00000100b
	
	ld iy, [GmacroLocal]
	ld b, #0
	add ba, ba
	add iy, ba
	ld iy, [iy]
	ld [GmacroPos], iy

	ld a, #1
	ld [GmacroWait], a	
	
CMD_Gmacro_Skip:
	ld a, #2
  jrl CMDreturn

CMD_Gmacro_Relative:
	sep
	ld hl, [GmacroPos]
	add hl, ba
	ld [GmacroPos], hl
	ld a, #2
  jrl CMDreturn



CMD_SetDuty: ; ///////////////////////////////////////////////////////////////////////////////////// 6
	inc iy
	ld a, [iy]
	ld [PWMcurr], a
	ld a, #2
  jrl CMDreturn



CMD_SetSpeed: ; //////////////////////////////////////////////////////////////////////////////////// 7
	ld b, [iy]
	inc iy
	bit b, #00000001b ; tempo mode?
	ld a, #2
  jrs nz, CMD_Speed_IsTempo
	; otherwise just speed
	ld b, [iy]
	ld [TickReload], b
	ld [TickCount], b
  jrl CMDreturn

CMD_Speed_IsTempo:
	bit b, #00000010b ; timer 1 or 2?
  jrs nz, CMD_Speed_Timer2

; timer 1
	bit b, #00000100b
	ld b, [iy]
  jrs nz, CMD_Speed_T1isHigh
	ld [br:32h], b
  jrl CMDreturn

CMD_Speed_T1isHigh:
	ld [br:33h], b
  jrl CMDreturn


CMD_Speed_Timer2:
	bit b, #00000100b
	ld b, [iy]
  jrs nz, CMD_Speed_T2isHigh
	ld [br:3Ah], b
  jrl CMDreturn

CMD_Speed_T2isHigh:
	ld [br:3Bh], b
  jrl CMDreturn





CMD_Portamento: ; ////////////////////////////////////////////////////////////////////////////////// 8
	ld hl, #WorkFlags
	bit [hl], #10000000b
  jrs z, CMD_PortaNote_ContinueIsZero
	and [hl], #01111111b
	ld a, [TransposeNext] ; update transpose
	ld [TransposeCurr], a

	ld ba, [iy] ; wait and then note target
	and a, #00001111b
	inc a
	ld [WaitCount], a
	ld [SweepTrgt], b
	ld l, b
	add iy, #2
	ld ba, [iy] ; reload and then rate
	ld [SweepReload], ba

	xor a, a ; initialize stuff
	ld b, a
	ld [SweepInterp], ba ; sweep interpolate count and then index count
	inc a
	ld [SweepWait], a
	
	ld a, l ; what direction
	cp a, [CurrntNote]
	ld hl, #PitchState
	ld a, #4
  jrs c, CMD_PortaDown
	and [hl], #11111011b
	or [hl],  #00001010b
  jrl CMDreturn
	
CMD_PortaDown:
	or [hl], #00001110b
  jrl CMDreturn

CMD_PortaNote_ContinueIsZero:
  ret


CMD_Sweep: ; /////////////////////////////////////////////////////////////////////////////////////// 9
	ld a, [iy]
	and a, #00001100b
	ld hl, #PitchState
	and [hl], #11110001b
	or [hl], a
	
	inc iy
	ld ba, [iy]
	ld [SweepReload], ba ; reload and then rate
	ld a, #1
	ld [SweepWait], a

	ld a, #3
  jrl CMDreturn



CMD_Vibrato: ; ///////////////////////////////////////////////////////////////////////////////////// A
	ld a, [iy] ; flags
	and a, #00001011b
	swap a
	ld hl, #PitchState
	and [hl], #01001111b
	or [hl], a

	inc iy
	ld ba, [iy]
	ld [VibratoReload], ba ; reload and then rate
	; notice: Vibrato progress is only cleared at note command

	ld a, #3
  jrl CMDreturn



CMD_PWMauto: ; ///////////////////////////////////////////////////////////////////////////////////// B
	ld a, [iy]
	and a, #00000111b
	ld hl, #WorkFlags
  jrs z, CMD_PWMauto_IsDisable
	swap a
	and [hl], #10001111b
	or [hl], a
	inc iy
	ld ba, [iy] ; reload and rate
	ld [PWMreload], ba
	ld [PWMwait], a
	add iy, #2
	ld ba, [iy] ; loop and target
	ld [PWMloop], ba
	
	ld a, #5
  jrl CMDreturn

CMD_PWMauto_IsDisable:
	and [hl], #10111111b
	ld a, #1
  jrl CMDreturn



CMD_Volume: ; ////////////////////////////////////////////////////////////////////////////////////// C
	ld a, [iy]
	and a, #00000011b ; only keep current volume bits
	ld hl, #VolumeLevel
	and [hl], #11111100b ; wipe the bits to replace
	or [hl], a
	ld a, #1
  jrl CMDreturn



CMD_Legato: ; ////////////////////////////////////////////////////////////////////////////////////// D
	ld hl, #WorkFlags
	bit [hl], #10000000b
  jrs z, CMD_Legato_ContinueIsZero
	and [hl], #01111111b
	
	ld a, [TransposeNext]
	ld [TransposeCurr], a
	ld a, [iy]
	and a, #0Fh
	inc a
	ld [WaitCount], a
	inc iy
	ld a, [iy]
	ld [CurrntNote], a

	ld a, #2
  jrl CMDreturn

CMD_Legato_ContinueIsZero:
  ret


CMD_Detune: ; ////////////////////////////////////////////////////////////////////////////////////// E
	ld a, [iy]
	and a, #00001111b
	sub a, #8
	ld [Detuning], a
	ld a, #1
  jrl CMDreturn



CMD_Null: ; //////////////////////////////////////////////////////////////////////////////////////// F
	ld a, #1
  jrl CMDreturn




;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                       RAM DEFINITIONS                      ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//
DEFSECT "ADPM_RAM_SPACE", DATA
SECT "ADPM_RAM_SPACE"

	; position block
SongBank:			ds 1
TmLineLocal:		ds 2
PhraseLocal:		ds 2
InstrmLocal:		ds 2
GmacroLocal:		ds 2
GrooveLocal:		ds 2

	; Block A definitions
KillCount:			ds 1
DelayCount:			ds 1
PendingNote:		ds 1
PendingInstr:		ds 1

GmacroPos:			ds 2
GmacroWait:			ds 1

VibratoWait:		ds 1 ; amount to wait before running vibrato
VibratoReload:		ds 1
VibratoRate:		ds 1 ; amount to add to offset
VibratoProg:		ds 1 ; current vibrato offset table position
VibratoPos:			ds 1 ; current working position of the vibrato wave gen

PitchState:			ds 1 ; Vibrato < - > Sweep/portamento

SweepWait:			ds 1 ; amount to wait before running sweep
SweepReload:		ds 1
SweepRate:			ds 1 ; amount to add per sweep step
SweepInterp:		ds 1
SweepIndCnt:		ds 1
SweepTrgt:			ds 1 ; for portamento mode, holds note index

PWMwait:			ds 1
PWMreload:			ds 1
PWMrate:			ds 1
PWMcurr:			ds 1
PWMloop:			ds 1
PWMtrgt:			ds 1

CurrntNote:			ds 1 ; current note entry playing from note table
OffsetNote:			ds 1 ; arpeggio entry offset
Detuning:			ds 1
TransposeCurr:		ds 1
TransposeNext:		ds 1

NoteOverlay:		ds 1 ; overrides current note result, 0FFh = not effective
DutyOverlay:		ds 1
VolumeLevel:		ds 1 ; MSB = overlay, LSB = normal
_ADPM_SFXoverlay:	ds 1 ; SFX muting if it's 0FEh, disabled if 0FFh

	; Block B definitions
TickCount:			ds 1
TickReload:			ds 1

WaitCount:			ds 1
WorkFlags:			ds 1
PhrasePos:			ds 2
TimeLinePos:		ds 2
LastInstrm:			ds 1

; MUSIC: 55 bytes

	; SFX Subdriver block
_ADPM_SFXbank:		ds 1
_ADPM_SFXdir:		ds 2
SFXwait:			ds 1	
SFXpos:				ds 2
SFXduty:			ds 1

; SFX: 7 bytes

;  //"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""||
; ||                        DOCUMENTATION                       ||
; ||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//


;   //////////////////////////////////////////////// TIMELINE
;
;	header just specifies its location within the music data
;
;		HEADER  ->  TIMELINE DATA  
;		
;			in header: 'db TimeLine'
;
;			points to label containing timeline data
;				'TimeLine:'
;				'db 00, 00'
;				'db 00, 02'
;				'db 01, 00' ...
;
;
;	Timeline format:
;
;		Phrase Number    Transpose value
;		           00h, 02h
;		           ||   ||
;		           ||   ++--- Transpose by 2 semitones up (0FEh for down)
;		           ++-------- Use the first phrase in the phrase index list
;
;
;
;
;
;   //////////////////////////////////////////////// PHRASE
;
;	header and index table fomatting - see example song
;
;		HEADER        ->  address to index table
;		INDEX TABLE   ->  address to the start of the Phrase data
;		PHRASE ENTRY  ->  start of Phrase data
;
;			in header: 'db Song_Phrases'
;
;			points to label containing the list
;				'Song_Phrases:'
;				'db Intro'
;				'db Phrase_00'
;				'db Phrase_01' ...
;
;			and data starts at one of the labels in these entries
;				'Intro:'
;				'db 01h, 20h, 00'
;				'db 01h, 90h' ...
;
;
;
;
;
;   //////////////////////////////////////////////// INSTRUMENT
;
;	header and index table fomatting - see example song
;
;		HEADER        ->  address to index table
;		INDEX TABLE   ->  address to the start of the Instrument data
;		INSTRM ENTRY  ->  start of Instrument data
;
;			in header: 'db Instrm_List'
;
;			points to label containing the list
;				'Instrm_List:'
;				'db Instrm_00'
;				'db Instrm_01'
;				'db Instrm_02' ...
;
;			and data starts at one of the labels in these entries
;				'Instrm_00:'
;				'db 0FFh, 60h, 11001000b'
;
;
;	instrument format: detune, duty, macro, PWM config & volume, PWM speed, PWM rate, PWM loop and PWM target
;
;		GGh, DDh, VVMMFFFFb, SSh, RRh, LLh, TTh
;
;		G: Gmacro
;			0FFh = disabled
;			any = use this entry from the list
;
;		D: Duty
;			80h = square wave, 40h = 25% duty, 20h = 12.5% duty (for reference)
;
;		V: Volume
;			00 = mute
;			01 = half volume
;			10 = half volume
;			11 = full volume
;
;		M: pwm Mode
;			00 = disabled, causes the bytes afterwards to be ignored
;			01 = ping-pong mode   :   reverse PWM direction on target and reverse again on loop
;			10 = loop mode        :   loop on target, reload value is loop
;			11 = one-shot mode    :   disables PWM auto on target
;
;		F: Finetune
;			0 = detune down, 8 = neutral, F = detune up
;
;		S: pwm Shift   <- vvv   these parameters will be ignored if M bits are 00b
;		R: pwm Rate
;		L: pwm Loop
;		T: pwm Target
;
;
;
;
;
;   //////////////////////////////////////////////// GMACRO
;
;	header and index table fomatting - see example song
;
;		HEADER        ->  address to index table
;		INDEX TABLE   ->  address to the start of the Gmacro data
;		GMACRO ENTRY  ->  start of Gmacro data
;
;			in header: 'db Gmacro_List'
;
;			points to label containing the list
;				'Gmacro_List:'
;				'db Macro_00'
;				'db Macro_01'
;				'db Macro_02' ...
;
;			and data starts at one of the labels in these entries
;				'Macro_00:'
;				'db 11000010b'
;				'db 00h, 02h'
;
;
;	Gmacro format:
;
;		ATWMPDVV WWWWWWWW PPPPPPPP DDDDDDDD
;		|||||||| |||||||| |||||||| ||||||||
;		|||||||| |||||||| |||||||| ++++++++--- pulse Duty
;		|||||||| |||||||| ++++++++------------ Pitch
;		|||||||| ++++++++--------------------- Wait (if W=1) 
;		||||||++------------------------------ Volume
;		|||||+-------------------------------- Duty request
;		||||+--------------------------------- Pitch request
;		|||+---------------------------------- pitch Mode
;		||+----------------------------------- Wait request
;		|+------------------------------------ reTrigger
;		+------------------------------------- Action
;
;		Action - see below
;			0 = End or Loop
;			1 = Gmacro command header
;
;		reTrigger
;			0 = no retrigger
;			1 = set Timer 3 reload flag
;
;		Wait request
;			0 = default wait time to 1
;			1 = request the W field for a longer wait time untill next header/end/loop
;
;		pitch Mode
;			0 = Relative mode, used for arpeggios
;			1 = Fixed mode, use parameters to overlay the regular note untill a relative command runs
;
;		Pitch request
;			0 = no frequency value, keep last; however on fixed mode, this setting is treated as always 1
;			1 = request P field for a new Note table index
;
;		Duty request
;			0 = use last duty on relative mode; use last duty from normal mode as overlay on fixed mode
;			1 = request and use D field
;
;		Volume
;			00 = mute
;			01 = half volume
;			10 = use last volume
;			11 = full volume
;
;
;	if Action is 0
;
;		0------E SSSSSSSS
;		       | ||||||||
;		       | ++++++++--- Subtract offset
;		       +------------ End macro
;
;		End macro:
;			0 = subtract current macro position with S field and continue
;			1 = ignore S field and disable the Gmacro on the WorkFlags var
;
;		S field for reference:
;			0 = no offset (forbidden, will execute the offset data) 
;			1 = offset into loop command (forbidden, causes end)
;			2 = offset 1 byte before loop
;			3 = offset 2 bytes before loop
;			... and so on untill 255
;
;
;
;
;
;   //////////////////////////////////////////////// GROOVE TABLE
;
;	header just specifies its location within the music data
;
;		HEADER  ->  GROOVE DATA  
;		
;			in header: 'db GrooveTable'
;
;			points to label containing groove sequence data
;				'GrooveTable:'
;				'db 04'
;				'db 06'
;				'db 0FFh, 00'
;
;
;	Groove table format:
;
;		Any byte (0 to FE) = a wait time value (0 is wait 255 ticks, beware)
;		FFh byte (255)     = end event marker
;
;		- whenever any byte (00-FE) is seen its value is directly loaded into the TickCount variable
;
;		- but if this byte is FF, the groove table counter will ask for a second byte
;		this end byte specifies a direct position within the 256 possible entries the groove table can have
;		so for example, if this value is 0, it will go to that position in the table and use the byte there
;
;		see example song
;
;
;
;
;
;   //////////////////////////////////////////////// OTHER 
;
;   WorkFlags: CDPP -GDK
;              ||||  |||
;              ||||  ||+--- Kill enable
;              ||||  |+---- Delay pending
;              ||||  +----- Gmacro running
;              ||++-------- PWM mode
;              |+---------- PWM direction
;              +----------- Continue flag (0 = will exit next)
;
;
;                    vibrato  sweep
;   PitchState:        EDMM  EDM-
;                      ||||  |||
;             enable --+|||  ||+-- mode (0 = free, 1 = targeted)
; (0 = up) direction ---+||  |+--- direction (0 = up)
;               mode ----++  +---- enable
;
;		vibrato modes: 0 = up, 1 = down, 2 = updown, 3 = square
;		sweep modes: 0 = free running, 1 = portamento (targeted)
;
;
;
;
;
; //////////////////////////////////////////////// COMMANDS
;
;	0 = Play Note  -  0X YY ZZ 
;		X = Wait time in ticks (0 = 1 tick, F = 16 ticks)
;		Y = Note table index number
;			however the top most bit (7) serves a different use
;				0 = request instrument (Z field)
;				1 = use last instrument
;		Z = instrument number
;
;		This command will cause a loop exit
;		Note: this command will cause running sweeps and vibratoes to stop
;
;
;
;	1 = End Event  -  11  or  10 XX
;		11 = End Phrase
;		
;		10 = End Song
;		XX = start offset (use for skip intro)
;
;
;
;	2 = Wait  -  2X  or  2F XX
;		X = wait time
;
;		This command will cause a loop exit
;
;
;
;	3 = Kill Note  -  3- XX
;		X = wait time
;		note: this command sets the Kill count, ticks here are in Block A ticks
;
;
;
;	4 = Delay Note  -  4- XX YY ZZ
;		X = wait time
;		Y = note table index number
;		Z = instrument to use
;
;		note: Y works like the regular Play Note command (see command 0)
;		note: this command sets the Delay count, ticks here are in Block A ticks
;
;
;
;	5 = Run Gmacro  -  5- XX
;		X = Gmacro index list number
;			- however if the macro value is FF it will stop the current playing Gmacro
;
;
;
;	6 = Set Duty  -  6- XX
;		X = Duty ratio value
;
;
;
;	7 = Set Speed  -  7X YY
;		X = target
;			-HTM
;			 |||
;			 ||+-- Mode
;			 |+--- Timer number
;			 +---- timer Half
;
;			Mode:
;				0 = set Groove position (ignores other bits)
;				1 = set Tempo timers
;
;			Timer number:
;				0 = Timer 1
;				1 = Timer 2
;
;			timer Half
;				0 = Low
;				1 = High
;
;		Y = value to apply
;
;		Note: to refresh an entire 16-bit mode timer, use two of this command
;
;
;
;	8 = Portamento  -  8X YY ZZ WW
;		X = wait time
;		Y = target note
;		Z = sweep wait
;		W = sweep rate
;
;		Note: target direction is determined by the command itself
;
;
;
;	9 = Sweep  -  9X YY ZZ
;		X = flags
;			ED--
;			||
;			|+-- Direction (0 = up, 1 = down)
;			+--- Enable (0 = off)
;
;		Y = sweep wait
;		Z = sweep rate
;
;
;
;	A = Vibrato  -  AX YY ZZ
;		X = flags
;			E-MM
;			| ||
;			| ++- Mode
;			+---- Enable (0 = off)
;
;		Mode:
;			00 = Up Down
;			10 = square (toggle)
;			01 = saw up (increment)
;			11 = saw down (decrement)
;
;		Note: this command does not restart the Vibrato position
;
;
;
;	B = PWM auto  -  BX YY ZZ WW VV  or  B0
;		X = flags
;			-DMM
;			 |||
;			 |++-- Mode
;			 +---- Direction (0 = forwards, ping-pong only)
;
;		Mode:
;			00 = disabled (causes the command to be 1-byte)
;			01 = ping-pong
;			10 = loop
;			11 = one-shot
;
;		Y = Wait
;		Z = Rate
;		W = Loop
;		V = Target
;
;
;
;	C = Volume  -  CX
;		X = volume
;			00 = mute
;			01 = half volume
;			10 = half volume
;			11 = full volume
;
;
;
;	D = Legato  -  DX YY
;		X = wait time
;		Y = Note list number
;			unlike Play Note (0), the uppermost bit is used for index as well
;
;		Note: basically a variant of Play Note that only changes the pitch
;
;
;
;	E = Detune  =  EX
;		X = detune value 
;			0 = detune down
;			8 = neutral
;			F = detune up
;
;
;
;
; //////////////////////////////////////////////// NOTES
;
;	- when referring to the sweep, vibrato and PWM, wait is the reload parameter
;	and rate means a value it's either added or subtracted to its current progress variable
;
;	- Sweep when not targeted (triggered by command 9) will wrap around to either
;		lowest  pitch (note 00h) when going up and hits the last note
;		highest pitch (note 54h) when going down and hits the first note
;
;		but when on targeted mode (triggered by command 8)
;		will clobber to the lowest or highest notes when exceeding the index list
;
;	- clobbering also happens when you exceed the index list with the sweep disabled