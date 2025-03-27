module CEL_PROJECT(

	//////////// CLOCK //////////
	input 		          		ADC_CLK_10,
	input 		          		MAX10_CLK1_50,
	input 		          		MAX10_CLK2_50,

	//////////// SEG7 //////////
	output		     [7:0]		HEX0,
	output		     [7:0]		HEX1,
	output		     [7:0]		HEX2,
	output		     [7:0]		HEX3,
	output		     [7:0]		HEX4,
	output		     [7:0]		HEX5,

	//////////// KEY //////////
	input 		     [1:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// GPIO, GPIO connect to GPIO Default //////////
	inout 		    [35:0]		GPIO
);


wire [31:0] my_PC, my_rd;

assign clk = ~KEY[1]; //ADC_CLK_10;

my_computer U1(.clk(clk), .reset(~KEY[0]), .my_sw(SW[7:0]), .my_rd(my_rd), .my_PC(my_PC));		// Excluding comments 200+ lines of "code"

assign LEDR = SW[9] ? my_PC : my_rd;

endmodule
