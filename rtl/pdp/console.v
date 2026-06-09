`include "config.v"

module console(
	input							clk_p,
	input							sys_init,
	input				[21:0]	wb_adr_i,
	input				[15:0]	wb_dat_i,
	output	reg	[15:0]	wb_dat_o,
	input							bus_stb,
	input							wb_we_i,
	output	reg				cons_ack,
	output	reg	[15:0]	startup_adr,
	output			[2:0]		cons_dispreg_leds
) ;

`ifdef bootrom_module
	initial startup_adr	= 16'o165020 ;
`else
	initial startup_adr	= 16'o140000 ;
`endif

	reg [15:0] display_reg = 16'd0 ;
	reg [15:0] switch_sr = 16'd0 ;
	
	assign cons_dispreg_leds = display_reg[2:0] ;

	wire cons_stb = bus_stb & (wb_adr_i[15:1] == 15'o77674) ; // 177570 >> 1
	
	always @(posedge clk_p) begin
		if (sys_init) begin
			cons_ack <= 1'b0 ;
			display_reg <= 16'b0 ;
		end else if (cons_stb) begin
			if (wb_we_i)
				display_reg <= wb_dat_i ;
			else
				wb_dat_o <= switch_sr[15:0] ;
			cons_ack <= 1'b1 ;
		end else begin
			cons_ack <= 1'b0 ;
		end
	end

endmodule
