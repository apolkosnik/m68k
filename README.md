# m68k
M68000 CPU Model in VHDL

Simplified model for the Motorola 68000 processor, coded in the hardware description language VHDL. A simplified architecture for the processor is designed in order to make an implementation of the 68000, as well as an instruction set architecture capable of executing instructions sequentially. 

All subsystems are simplified versions of the original processor, based on the Motorola reference documentation. Control unit, register bank, program counter, state register, as well as a simple external memory and other auxiliary modules are among the subsystems implemented.

Internal processor signals are simulated using ModelSim.

There is a simple assembler in Perl to execute programs written in assembly language for the M68000 processor.
