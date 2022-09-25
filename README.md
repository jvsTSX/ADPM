# ADPM
Audio Driver for Pokémon Mini
A simple but hopefully good enough for music Sound Driver for Nintendo's Pokémon Mini console, written fully in S1C88 assembly. 
In order to assemble and run this on your ROM you will need:
- The Epson S1C88 toolchain, available here: https://github.com/pokemon-mini/c88-pokemini
- A Pokémon Mini emulator
- A file with your main ASM or C code and an additional file for your Music and SFX data if you want to include it outside of your main code

Notes:
- There are four global labels to call, two must be called upon Vsync or Timer overflow (the main engine calls, one for the SFX subengine) and two to setup your song, make sure you load register pair HL with the #Label of your song header and SFX location before calling the setup codes, some detail is on the source itself
- Most features have been tested before creating this repo, but things might be buggy still, please report if anything is misbehaving
- CPU consumption has not been measured
- PRC should be disabled for fast tempos, and enabled for V-sync tempo (~36hz)
 main

- In order to assemble the test song from source you will need to download "startup.asm" from https://github.com/pokemon-mini/c88-pokemini/blob/master/examples/helloworld/src/startup.asm and then follow the steps:
- 1: make sure cc88.exe and screc_cat.exe are set to PATH (dropping the files on the BIN epson toolchain folder also works but it's pretty messy)
- 2: put both example.asm and startup.asm in the same folder
- 3: type cd [directory path] (example: cd C:/Users/ScottHere/Desktop/pokemonminiexample)
- 4: type "cc88 -srec -v -Md -d pokemini example.asm startup.asm"
- 5: type "srec_cat example.sre -o example.min -binary"
- 6: open the resulting .MIN file into any pokémon mini emulator

A video of the example song is available here: https://youtu.be/Z2X9NSDcpnk

There is currently no converter or utility available for ADPM
