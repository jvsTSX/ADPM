# ADPM
<br><p align="left"><img src="https://github.com/jvsTSX/ADPM/blob/main/ADPM_ex_screen.png?raw=true" alt="ADPM" width="460" height="350"/>
 
Audio Driver for Pokémon Mini
A simple but hopefully good enough for music Sound Driver for Nintendo's Pokémon Mini console, written fully in S1C88 assembly. 

## changelog
version 1.1
- full rewrite of the driver, taking into account my improvements on ADVM
- groove table added
- fixed bugs regarding Gmacro loop
- reworked the Gmacro format
- new pitch pipe using interpolation for consistent sweeps and vibratos anywhere in the pitch range
- speed control changed to integer instead of accumulator-based, you can still emulate what it does using the groove table
- songs now can be in any ROM bank, just make sure ADPM itself stays in the home bank (bank 0)

## info
- RAM usage: 7 bytes for SFX sub-engine and 55 bytes for music engine (total 62 bytes)
- CPU consumption: (WIP, Cycle counting takes a while)
- Driver size: 2078 bytes

## Usage
- There are three global labels to call, two must be called upon Vsync or Timer overflow (the main engine calls, one for the SFX subengine) and one to setup your song, you must load register pair `HL` with the `#Label` and register `A` with the `#@dpag(Label)` of your song's header location before calling the setup code (WARNING: YOU MUST `PUSH IP` AND `POP IP` BEFORE AND AFTER CALLING THE DRIVER AND SETUP, THESE DON'T DO THIS AUTOMATICALLY TO NOT PUSH THINGS TWICE IN CASE YOU WANT TO SET THE TIMING SOURCE TO THE TIMER IRQS)
- Most features have been tested before creating this repo, but things might be buggy still, please report if anything is misbehaving
- PRC should be disabled for fast tempos, and enabled for V-sync tempo (~36hz)
- Setup the SFX subdriver by adding these lines of code:
```asm
 ld a, #@dpag(SFXlist)
 ld [_ADPM_SFXbank], a
 ld hl, #SFXlist      
 ld [_ADPM_SFXdir], hl
```

## Assembling 

In order to assemble the example song from source you will need to download "startup.asm" from [this repo](https://github.com/pokemon-mini/c88-pokemini/blob/master/examples/helloworld/src/startup.asm) and then follow the steps:
- 1: make sure cc88.exe and screc_cat.exe are set to PATH (dropping the files on the BIN epson toolchain folder also works but it's pretty messy)
- 2: put ADPM.asm, example.asm and startup.asm in the same folder
- 3: type `cd [directory path]` (example: `cd C:/Users/ScottHere/Desktop/pokemonminiexample`)
- 4: type `cc88 -srec -v -Md -d pokemini example.asm adpm.asm startup.asm`
- 5: type `srec_cat example.sre -o example.min -binary`
- 6: open the resulting .MIN file into any pokémon mini emulator

A video of the example song is available [on my youtube channel](https://youtu.be/Z2X9NSDcpnk)

Further documentation available at the end of the ADPM.asm source file

There is currently no converter or utility available for ADPM
