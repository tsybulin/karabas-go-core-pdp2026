module adac(
	input clk,
	input speaker,
	output reg din, lrck, bck
) ;

	reg [15:0] mix = 16'b0 ;

	always @(posedge clk) begin
		mix[14] <= speaker ;
	end
	
	reg [2:0] i2s_clk = 1'b0 ;
	
	always @(posedge clk) begin
		i2s_clk <= i2s_clk + 1'b1 ;
	end
	
	wire ce = i2s_clk == 3'b0 ;
	reg [5:0] i2sword = 0 ;
	reg [15:0] o2c ;
	
	always @(posedge clk) begin
		if (ce == 1'b0 && i2sword == 6'b111111) begin
			o2c <= mix ;
		end
	end

	always @(posedge clk) begin
		if (ce == 1'b1) begin
			lrck <= i2sword[5] ;
			bck <= i2sword[0] ;
			din <= o2c[16 - i2sword[4:1]] ;
			i2sword	<= i2sword + 1 ;
		end
	end

endmodule
