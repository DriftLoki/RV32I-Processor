`timescale 1ns/1ps

module my_computer_tb();

	reg        clk, reset;

	// instantiate device to be tested
	my_computer U1(.clk(clk), .reset(reset), .my_sw(0), .my_rd(), .my_PC());

	always
	begin
		#5; clk <= ~clk;
	end

	initial
	begin
		reset <= 1; clk = 1;
		#22; reset <= 0;
		#1000;
		$stop;
	end

endmodule