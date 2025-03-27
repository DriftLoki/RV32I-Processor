# RV32I-Processor
RV32I processor and memory units
Uses RV32I Instruction set Architecture, with 23 insturcitons fully implemented. This was part of a class project so we only implemented necessary Instructions. This code is intended for the DE10-Lite Board which is programmed on Intel Quartus Prime Lite. 

Coded in System Verilog

## Coding and Testing

https://venus.kvakil.me/
Venus is a RV32I simulator and allows you to code in Assembly and convert it to Machince Code. This is used to create a program to run on the cpu. Dump your program to machine code and copy it over to the riscvtest_rom_image text file and recompile and flash to the board. 

Inside the imem and dmem modules, replace the file path with the file path where the rom and ram files are when you extract the folder. Make sure to replace every \ with \\.

## Physical Operation

Key[0]: resets the Program Counter
      Key[1]: increments the Program Counter

Sw[9]: ON: LEDs displys the Program Counter
       OFF: LEDs displays the contents of the memory address slected bt the switches

SW[7:0]: controls which memory address is being selected to display    
