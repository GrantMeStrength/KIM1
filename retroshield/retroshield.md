# Retroshield experiment

The [Retroshield](http://www.8bitforce.com/projects/retroshield/) is a piece of hardware and software that lets you use a real vintage CPU with an Arduino providing an emulation of RAM, ROM, clock and control signals.

It's the ideal way to use a real CPU without the hassle of sourcing and building the rest of the computer.

As I worked on the 6502 emulation part of the Virtual Kim project, I kept thinking it would be great to find a way to automate testing the opcode implementation code against a *real* 6502.

This is a project where I try to do that - by using a Retroshield with a real 6502, connected to the computer running the 6502 emulation I wrote, I hope to run code side-by-side on a virtual and a real 6502 and check for discrepencies.

To do this, I need to write some Swift code that can communicate with the Retroshield - it connects over the Arduino's USB port by default. I also need to write some code on the Retroshield 'rom' that listens for commands from the serial port, takes an instruction, executes it, and then responds with the 6502 status (registers, flags, and maybe zero page or full memory map?).

I'll start by taking the [KIM-1 Retroshield code](https://gitlab.com/8bitforce/retroshield-arduino/-/tree/master/k6502/k65c02_kim1) (as I know the KIM-1 now pretty well) and adapting that.