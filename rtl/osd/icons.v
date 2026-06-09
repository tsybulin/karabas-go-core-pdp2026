module icons(
	input						clk,
	input			[10:0]	hcnt,
	input			[10:0]	vcnt,
	input			[7:0]		leds,
	output reg	[23:0]	rgb_o,
	output reg				visible
) ;

	localparam H_OFFSET = 11'd512 ;
	localparam V_OFFSET = 11'd48 ;
	localparam CLEAR = 24'h0 ;

	localparam [23:0] LED_COLORS[0:7] = {
		24'h00FF00, // fetcher
		24'hFFFFFF, // timer
		24'hFFFF00, // wait
		24'hFFFF00, // mmu
		24'h0000FF, // disk
		24'hFF0000, // cons2
		24'hFF0000, // cons1
		24'hFF0000  // cons0
	} ;
	
	localparam [23:0] OFF_COLORS[0:7] = {
		24'h002000, // fetcher
		24'h102020, // timer
		24'h102000, // wait
		24'h202000, // mmu
		24'h000020, // disk
		24'h200000, // cons2
		24'h200000, // cons1
		24'h200000  // cons0
	} ;

	initial visible = 1'b0 ;
	
	wire [15:0] douta ;
	reg  [15:0] pixel_mask = 16'h0001 ;
	wire [15:0] pixel = douta & pixel_mask ;
	
	ledfont ledfont_inst(
		.clka(clk),
		.addra(vcnt[3:0]),
		.douta(douta)
	) ;
	
	always @(posedge clk) begin
		if (hcnt >= H_OFFSET && hcnt < H_OFFSET + 128 && vcnt >= V_OFFSET && vcnt < V_OFFSET + 16) begin
			visible <= 1'b1 ;
			pixel_mask <= pixel_mask << 1 ;
			if (pixel_mask == 16'h8000) pixel_mask <= 16'h0001 ;


			case (hcnt[6:4]) // led_no
				3'd0 :
					if (leds[0])
						rgb_o <= (douta & pixel_mask) ? LED_COLORS[0] : CLEAR ;
					else
						rgb_o <= (douta & pixel_mask) ? OFF_COLORS[0] : CLEAR ;
				
				3'd1 :
					if (leds[1])
						rgb_o <= (douta & pixel_mask) ? LED_COLORS[1] : CLEAR ;
					else
						rgb_o <= (douta & pixel_mask) ? OFF_COLORS[1] : CLEAR ;
				
				3'd2 :
					if (leds[2])
						rgb_o <= (douta & pixel_mask) ? LED_COLORS[2] : CLEAR ;
					else
						rgb_o <= (douta & pixel_mask) ? OFF_COLORS[2] : CLEAR ;
				
				3'd3 :
					if (leds[3])
						rgb_o <= (douta & pixel_mask) ? LED_COLORS[3] : CLEAR ;
					else
						rgb_o <= (douta & pixel_mask) ? OFF_COLORS[3] : CLEAR ;
				
				3'd4 :
					if (leds[4])
						rgb_o <= (douta & pixel_mask) ? LED_COLORS[4] : CLEAR ;
					else
						rgb_o <= (douta & pixel_mask) ? OFF_COLORS[4] : CLEAR ;
				
				3'd5 :
					if (leds[5])
						rgb_o <= (douta & pixel_mask) ? LED_COLORS[5] : CLEAR ;
					else
						rgb_o <= (douta & pixel_mask) ? OFF_COLORS[5] : CLEAR ;
				
				3'd6 :
					if (leds[6])
						rgb_o <= (douta & pixel_mask) ? LED_COLORS[6] : CLEAR ;
					else
						rgb_o <= (douta & pixel_mask) ? OFF_COLORS[6] : CLEAR ;
				
				3'd7 :
					if (leds[7])
						rgb_o <= (douta & pixel_mask) ? LED_COLORS[7] : CLEAR ;
					else
						rgb_o <= (douta & pixel_mask) ? OFF_COLORS[7] : CLEAR ;
			endcase ;
		end else begin
			pixel_mask <= 16'h0001 ;
			rgb_o <= CLEAR ;
			visible <= 1'b0 ;
		end
	end ;
	
endmodule
