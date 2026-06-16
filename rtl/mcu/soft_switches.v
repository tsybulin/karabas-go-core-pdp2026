`timescale 1ns / 1ps
module soft_switches(
	input				clk,
	input [15:0]	sw_command,
	
	output reg			sw_reset = 1'b0,
	output reg			sw_cont  = 1'b0,
	output reg			sw_slow  = 1'b0,
	output reg [7:0]	sw_bank	= 8'b0,
	output reg [1:0]	sw_color	= 2'b00,
	output reg			sw_leds	= 1'b0,
	output reg [1:0]	sw_sound	= 2'b00,
	output reg [2:0]  sw_bank_offset = 3'b0
) ;
	
	always @(posedge clk) begin
		case (sw_command[15:8])
			8'h00 : sw_reset	<= sw_command[0] ;
			8'h01 : sw_cont	<= sw_command[0] ;
			8'h02 : sw_slow	<= sw_command[0] ;
			8'h03 : sw_bank_offset <= sw_command[2:0] ;
			8'h04 : sw_bank[1:0]	<= sw_command[1:0] ;
			8'h05 : sw_bank[3:2]	<= sw_command[1:0] ;
			8'h06 : sw_bank[5:4]	<= sw_command[1:0] ;
			8'h07 : sw_bank[7:6]	<= sw_command[1:0] ;
			8'h08 : sw_color	<= sw_command[1:0] ;
			8'h09 : sw_leds	<= sw_command[0] ;
			8'h0A : sw_sound	<= sw_command[1:0] ;
		endcase
	end

endmodule
