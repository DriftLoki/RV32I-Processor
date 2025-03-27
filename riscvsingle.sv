// riscvsingle.sv

// RISC-V single-cycle processor
// From Section 7.6 of Digital Design & Computer Architecture
// 27 April 2020
// David_Harris@hmc.edu 
// Sarah.Harris@unlv.edu

// run 210
// Expect simulator to print "Simulation succeeded"
// when the value 25 (0x19) is written to address 100 (0x64)


// Single-cycle implementation of RISC-V (RV32I)
// User-level Instruction Set Architecture V2.2 (May 7, 2017)
// Implements a subset of the base integer instructions:
//    lw, sw
//    add, sub, and, or, slt, 
//    addi, andi, ori, slti
//    beq
//    jal
// Exceptions, traps, and interrupts not implemented
// little-endian memory

// 31 32-bit registers x1-x31, x0 hardwired to 0
// R-Type instructions
//   add, sub, and, or, slt
//   INSTR rd, rs1, rs2
//   Instr[31:25] = funct7 (funct7b5 & opb5 = 1 for sub, 0 for others)
//   Instr[24:20] = rs2
//   Instr[19:15] = rs1
//   Instr[14:12] = funct3
//   Instr[11:7]  = rd
//   Instr[6:0]   = opcode
// I-Type Instructions
//   lw, I-type ALU (addi, andi, ori, slti)
//   lw:         INSTR rd, imm(rs1)
//   I-type ALU: INSTR rd, rs1, imm (12-bit signed)
//   Instr[31:20] = imm[11:0]
//   Instr[24:20] = rs2
//   Instr[19:15] = rs1
//   Instr[14:12] = funct3
//   Instr[11:7]  = rd
//   Instr[6:0]   = opcode
// S-Type Instruction
//   sw rs2, imm(rs1) (store rs2 into address specified by rs1 + immm)
//   Instr[31:25] = imm[11:5] (offset[11:5])
//   Instr[24:20] = rs2 (src)
//   Instr[19:15] = rs1 (base)
//   Instr[14:12] = funct3
//   Instr[11:7]  = imm[4:0]  (offset[4:0])
//   Instr[6:0]   = opcode
// B-Type Instruction
//   beq rs1, rs2, imm (PCTarget = PC + (signed imm x 2))
//   Instr[31:25] = imm[12], imm[10:5]
//   Instr[24:20] = rs2
//   Instr[19:15] = rs1
//   Instr[14:12] = funct3
//   Instr[11:7]  = imm[4:1], imm[11]
//   Instr[6:0]   = opcode
// J-Type Instruction
//   jal rd, imm  (signed imm is multiplied by 2 and added to PC, rd = PC+4)
//   Instr[31:12] = imm[20], imm[10:1], imm[11], imm[19:12]
//   Instr[11:7]  = rd
//   Instr[6:0]   = opcode


							//Preimplemented
				
//   Instruction  opcode    funct3    funct7
//   add          0110011   000       0000000
//   sub          0110011   000       0100000
//   and          0110011   111       0000000
//   or           0110011   110       0000000
//   slt          0110011   010       0000000
//   addi         0010011   000       immediate
//   andi         0010011   111       immediate
//   ori          0010011   110       immediate
//   slti         0010011   010       immediate
//   beq          1100011   000       immediate
//   lw	         0000011   010       immediate
//   sw           0100011   010       immediate
//   jal          1101111   immediate immediate


							//What we implemented

//   Instruction_N	opcode	funct3	funct7
//   xor					0110011 	100		0000000
//   xori				0010011 	100		0000000
//   sll					0110011 	001		0000000
//   slli			   0010011 	001		0000000
//   srl					0110011 	101		0000000
//   srli				0010011	101		0100000
//   sra					0110011 	101		0100000
//   bne					1100011 	001		- 
//   blt					1100011 	100		- 
//   bge					1100011 	101		- 



// This part is modified by Dr.Toker

module my_computer(
			  input  logic clk, reset, 
			  input  logic[ 9:0] my_sw,
			  output logic[31:0] my_rd,
			  output logic[31:0] my_PC
);

  logic [31:0] PC, Instr, ReadData, WriteData, DataAddr;
  logic MemWrite;
  
  // instantiate processor 
  riscvsingle rvsingle(clk, reset, PC, Instr, MemWrite, DataAddr, WriteData, ReadData);
  
  imem imem(PC, Instr); // program memory - ROM
  dmem dmem(clk, MemWrite, DataAddr, WriteData, ReadData, my_sw, my_rd); // data memort - RAM
  
  assign my_PC = PC;
endmodule

// =======================================================================
// NEW STUFF ABOUT MEMORIES - MUST REVIEW FIRST
// =======================================================================

module regfile(
					input  logic clk, 
               input  logic we3, 
               input  logic [ 4:0] a1, a2, a3,
               input  logic [31:0] wd3, 
               output logic [31:0] rd1, rd2
);

  logic [31:0] rf[31:0];

  // three ported register file
  // read two ports combinationally (A1/RD1, A2/RD2)
  // write third port on rising edge of clock (A3/WD3/WE3)
  // register 0 hardwired to 0

  always_ff @(posedge clk)
    if (we3) rf[a3] <= wd3;	

  assign rd1 = (a1 != 0) ? rf[a1] : 0;
  assign rd2 = (a2 != 0) ? rf[a2] : 0;
endmodule
 
module imem(
				input  logic [31:0] a,
            output logic [31:0] rd
);

  logic [31:0] ROM[63:0];

  // Initialize the program memory
  // Simulator : ok
  // Hardware  : For FPGA ok, non-FPGA we need a 3rd party solution to program the FLASH memory (ROM)
  initial
      $readmemh("C:\\Users\\eugen\\OneDrive\\Desktop\\CEL_PROJECT\\riscvtest_rom_image.txt", ROM);

  assign rd = ROM[a[31:2]]; // word aligned
endmodule

// This part is modified by Dr. Toker
module dmem(
				input  logic clk, we,
            input  logic [31:0] a, wd,
            output logic [31:0] rd,
				input  logic [ 7:0] my_sw,
				output logic [31:0] my_rd
);

  logic [31:0] RAM[127:0];

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
  begin
    if (we) RAM[a[31:2]] <= wd;
	 
	 // Used only for simulation, does not correspond to ANY hardware
	 if (we)
		$display("Write RAM[%08x]=%08x at %t", a[31:2], wd, $time);
	 else
		$display("Read  RAM[%08x]=%08x at %t", a[31:2], rd, $time);	
		
  end
  
  assign my_rd = RAM[my_sw[7:2]];
  
  // Initialize the program memory
  // Simulator : ok
  // Hardware  : For FPGA ok, non-FPGA we need a 3rd party solution to program the DATA memory (RAM)
  initial
      $readmemh("C:\\Users\\eugen\\OneDrive\\Desktop\\CEL_PROJECT\\riscvtest_ram_image.txt", RAM);  
  
endmodule
 
module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset,
               input  logic [WIDTH-1:0] d, 
               output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule
  
// =======================================================================
// OLD STUFF - Component Instantiation or New Combinatorial Designs
// =======================================================================

module riscvsingle(
						input  logic clk, reset,
                  output logic [31:0] PC,
                  input  logic [31:0] Instr,
                  output logic MemWrite,
             		output logic [31:0] ALUResult, WriteData,
                  input  logic [31:0] ReadData
);

  logic       ALUSrc, RegWrite, Jump, Zero;
  logic [1:0] ResultSrc, ImmSrc;
  logic [3:0] ALUControl;

  controller c(Instr[6:0], Instr[14:12], Instr[30], Zero,
               ResultSrc, MemWrite, PCSrc,
               ALUSrc, RegWrite, Jump,
               ImmSrc, ALUControl);
  datapath dp(clk, reset, ResultSrc, PCSrc,
              ALUSrc, RegWrite,
              ImmSrc, ALUControl,
              Zero, PC, Instr,
              ALUResult, WriteData, ReadData);
endmodule

module controller( //handles the breakdown of the control bits to what they enable and disable
						input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  input  logic       Zero,
                  output logic [1:0] ResultSrc,
                  output logic       MemWrite,
                  output logic       PCSrc, ALUSrc,
                  output logic       RegWrite, Jump,
                  output logic [1:0] ImmSrc,
                  output logic [3:0] ALUControl
);

  logic [1:0] ALUOp;
  logic       Branch;

  maindec md(op, ResultSrc, MemWrite, Branch, ALUSrc, RegWrite, Jump, ImmSrc, ALUOp); //specific breakdown of opcode
  aludec  ad(op[5], funct3, funct7b5, ALUOp, ALUControl);
  
//PCSrc is specific for branch instructions. it is enabled if specific things are active
  assign PCSrc = Branch & Zero | Jump | Branch & !Zero & funct3 == 3'b001 | Branch & !Zero & funct3 == 3'b100 | Branch & funct3 == 3'b101;
//(Branch, Zero = beq) or (jump enabled) or (Branch, !Zero, funct3(001) = bne) or (Branch, !Zero, funct3(100) = blt) or (Branch, funct3(101) = bge)
endmodule

module maindec( //Opcode to controls
					input  logic [6:0] op,
               output logic [1:0] ResultSrc,
               output logic       MemWrite,
               output logic       Branch, ALUSrc,
               output logic       RegWrite, Jump,
               output logic [1:0] ImmSrc,
               output logic [1:0] ALUOp
);

  logic [10:0] controls;

  assign {RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp, Jump} = controls;

  always_comb
    case(op)
    // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump
      7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw
      7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw
      7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; // R-type 
      7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq / bne
      7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I-type ALU
      7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
      default:    controls = 11'bx_xx_x_x_xx_x_xx_x; // non-implemented instruction
    endcase
endmodule

module aludec(
				  input  logic opb5,
              input  logic [2:0] funct3,
              input  logic       funct7b5, 
              input  logic [1:0] ALUOp,
              output logic [3:0] ALUControl
);

  logic  RtypeSub;
  assign RtypeSub = funct7b5 & opb5;  // TRUE for R-type subtract instruction
  

  always_comb
    case(ALUOp)
      2'b00:                ALUControl = 4'b0000; // addition
      2'b01:                ALUControl = 4'b0001; // subtraction
      default: case(funct3) // R-type or I-type ALU. We also added B-type alue
                 3'b000:  if (RtypeSub) 
                            ALUControl = 4'b0001; // sub
                          else      
								  ALUControl = 4'b000; // add, addi
								 
					  3'b001:	 if(RtypeSub)
									ALUControl = 4'b0110; // sll
									else if(funct7b5 == 1'b0) //checks specific bit 5 of funct7 to differentiate between slli and bne
									ALUControl = 4'b0110; // slli
									else 
									ALUControl = 4'b0001; //bne 
					  
					  3'b101:	if(RtypeSub)
									ALUControl = 4'b0111; //srl
									else if(funct7b5 == 1'b1) //checks specific bit 5 of funct7 to differentiate between srli and sra
									ALUControl = 4'b0111; // srli
									else 
									ALUControl = 4'b1000; // sra
									
									
						
                 3'b010:    ALUControl = 4'b0101; // slt, slti
                 3'b110:    ALUControl = 4'b0011; // or, ori
                 3'b111:    ALUControl = 4'b0010; // and, andi
					  
					  3'b100:	if(RtypeSub)  //we added this to associate this ALUop with xor and xori if R-type is active
										ALUControl = 4'b0100; // xor, xori
										else //same ALUop but not R-type fo blt and bge
										ALUControl = 4'b0101; // blt, bge
                 default:   ALUControl = 4'bxxxx; // ???
               endcase
    endcase
endmodule

module datapath(
					 input  logic        clk, reset,
                input  logic [1:0]  ResultSrc, 
                input  logic        PCSrc, ALUSrc,
                input  logic        RegWrite,
                input  logic [1:0]  ImmSrc,
                input  logic [3:0]  ALUControl,
                output logic        Zero,
                output logic [31:0] PC,
                input  logic [31:0] Instr,
                output logic [31:0] ALUResult, WriteData,
                input  logic [31:0] ReadData
);

  logic [31:0] PCNext, PCPlus4, PCTarget;
  logic [31:0] ImmExt;
  logic [31:0] SrcA, SrcB;
  logic [31:0] Result;

  // next PC logic
  flopr #(32) pcreg(clk, reset, PCNext, PC); 
  adder       pcadd4(PC, 32'd4, PCPlus4);
  adder       pcaddbranch(PC, ImmExt, PCTarget);
  mux2 #(32)  pcmux(PCPlus4, PCTarget, PCSrc, PCNext);
 
  // register file logic
  regfile     rf(clk, RegWrite, Instr[19:15], Instr[24:20], 
                 Instr[11:7], Result, SrcA, WriteData);
  extend      ext(Instr[31:7], ImmSrc, ImmExt);

  // ALU logic
  mux2 #(32)  srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
  alu         alu(SrcA, SrcB, ALUControl, ALUResult, Zero);
  mux3 #(32)  resultmux(ALUResult, ReadData, PCPlus4, ResultSrc, Result);
endmodule


module adder(input  [31:0] a, b,
             output [31:0] y);

  assign y = a + b;
endmodule

module extend(input  logic [31:7] instr,
              input  logic [1:0]  immsrc,
              output logic [31:0] immext);
 
  always_comb
    case(immsrc) 
               // I-type 
      2'b00:   immext = {{20{instr[31]}}, instr[31:20]};  
               // S-type (stores)
      2'b01:   immext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; 
               // B-type (branches)
      2'b10:   immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; 
               // J-type (jal)
      2'b11:   immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; 
      default: immext = 32'bx; // undefined
    endcase             
endmodule

module mux2 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, 
              input  logic             s, 
              output logic [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 
endmodule

module mux3 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, d2,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);

  assign y = s[1] ? d2 : (s[0] ? d1 : d0); 
endmodule

module alu(input  logic [31:0] a, b,
           input  logic [3:0]  alucontrol,
           output logic [31:0] result,
           output logic        zero);

  logic [31:0] condinvb, sum;
  logic        v;              // overflow
  logic        isAddSub;       // true when is add or subtract operation

  assign condinvb = alucontrol[0] ? ~b : b;
  assign sum = a + condinvb + alucontrol[0];
  assign isAddSub = ~alucontrol[2] & ~alucontrol[1] |
                    ~alucontrol[1] & alucontrol[0];

  always_comb
    case (alucontrol)
      4'b0000:  result = sum;         // add
      4'b0001:  result = sum;         // subtract
      4'b0010:  result = a & b;       // and
      4'b0011:  result = a | b;       // or
      4'b0100:  result = a ^ b;       // xor
      4'b0101:  result = sum[31] ^ v; // slt
      4'b0110:  result = a << b[4:0]; // sll
      4'b0111:  result = a >> b[4:0]; // srl
		4'b1000:  result = a >>> $signed(b[4:0]); // sra
		4'b1001:  result = a < b;		// compare
      default: result = 32'bx;
    endcase

  assign zero = (result == 32'b0);
  assign v = ~(alucontrol[0] ^ a[31] ^ b[31]) & (a[31] ^ sum[31]) & isAddSub;
  
endmodule
