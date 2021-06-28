# KIM-1 / PAL-1 / KIM UNO


Some code and experiments for the KIM-1, but as I don't have a KIM-1, it's really the PAL-1 and Kim Uno.

## Manual - June 27, 2021

An updated PDF manual that is baked into the [Virtual 6502 iOS](https://appstoreconnect.apple.com/apps/1548356829/appstore/info#:~:text=Additional%20Information-,View,-on%20App%20Store) currently on the App Store. It is impossible to refer to the manual while using the app, so you might want to download it from here. The filename is ```Manual-for-app.pdf```.




## Audio - June 15, 2021

In the audio folder you'll find some programs saved from the PAL-1. These can be particularly useful when setting up the PAL-1 cassette interface - especially Vu-Tape.wav. Refer to the [instructions for the PAL-1 Cassette interface](http://pal.aibs.ws/assets/Cassette_expansion_manual.pdf) for more details. 

## Serial Status

When debugging, it can be useful to have a log of the executed instructions and state of the 
registers. 

This code can be placed in a new ROM image, and by changing the regular NMI vector at $17FA/$17FB to point at it,
it will be called every single-stepped instruction. It uses monitor code to send the register status to the serial port. 

The NMI is generated by the hardware switch (slide SST on, press GO). There’s a little magic that prevents it from 
happening when the PC is in ROM space, but that’s it. The NMI makes the 6502 to do a few things (like push register
states) and then go to an address, stored in a fixed address the 6502 always uses. The KIM, unlike many systems, 
keeps that vector in RAM so you can write in a new location. So when the user presses the switch, the NMI is triggered, 
it pushes the registers, looks in the vector, and jumps to this new code. This code pops the registers and then sends 
them to the serial port with a little text labelling. 

To create a log file, you must manually keep pressing the GO key every instruction.

Note: The code can't be in RAM. Making your own EEPROM is pretty easy these days with cheap programmers and second-hand
EEPROMS from eBay. If you are buying a PAL-1, you could always try asking the seller to add this code to the ROM image
for you ;-)

This technique might work on the Kim Uno, but it would be simpler on the Uno to edit the source code to add print statements, 
as the Uno's code already mirrors the LED display over serial. On the Uno I would comment out the LED display, and then
add print statements to the main loop (perhaps only outputting when a specific key is pressed, or memory address range
is active).

## Papertape

What's the easiest way to load a program into the KIM-1? Using the monitor programs L command, which will let your serial app
send a file in .PTP or "papertape" format. A papertape file is really a plain text file containing the binary data in the form 
of hex strings, with a few additions for the loading address and a checksum.

I found a program to generate the papertape format, but it was written a long time ago and my current Windows system threw
a fit when I tried to run it. So here is some C# code that will get you most of the way to writing a utility that can take
your assembled 6502 (from a emulated assembler for example) into a format you can load into the KIM-1 or clone.



## Kim Uno Case

Some guides on making a case for the KIM Uno: a small, battery powered handheld KIM clone designed by Oscar Vermeulen. 
This case is constructed using laser-cut acrylic and a 3D printed frame. Photos are included.

## Retroshield Fuzzing

[Some code and ideas](retroshield/retroshield.md) as I work out whether testing emulated 6502 opcodes against real ones is possible and useful.

## PAL-1 Case

Using some laser-cut acrylic and 3D printing, I made a case and keypad for the PAL-1. Gives it a little protection and is easier to type on. The files are in the archive.

![](pal1a.jpeg)

![](pal1b.jpeg)

![](pal1c.jpeg)


## Links

* [KIM-1](https://www.wikipedia.org/wiki/KIM-1)
* [PAL-1](https://www.tindie.com/products/tkoak/pal-1-a-mos-6502-powered-computer-kit/)
* [KIM Uno](https://obsolescence.wixsite.com/obsolescence/kim-uno-summary-c1uuh)
