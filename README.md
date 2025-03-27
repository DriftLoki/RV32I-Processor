# RV32I-Processor
RV32I processor and memory units
Uses RV32I Instruction set Architecture, with 23 insturcitons fully implemented. This was part of a class project so we only implemented necessary Instructions. This code is intended for the DE10-Lite Board which is programmed on Intel Quartus Prime Lite. 

Coded in System Verilog

## Operation:

Key[0]: resets the Program Counter
Key[1]: increments the Program Counter

Sw[9]: ON: LEDs displys the Program Counter
       OFF: LEDs displays the contents of the memory address slected bt the switches

SW[7:0]: controls which memory address is being selected to display    
