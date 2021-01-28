# KIM-1 / PAL-1 / KIM UNO


Some code and experiments for the KIM-1, but as I don't have a KIM-1, it's really the PAL-1 and Kim Uno.

## Serial Status

When debugging, it can be useful to have a log of the executed instructions and state of the 
registers. 

This code can be placed in ROM, and by changing the regular  NMI vector at $17FA/$17FB to point at it,
it will called every single-stepped instruction. It uses monitor code to send the register status to the serial port. 
