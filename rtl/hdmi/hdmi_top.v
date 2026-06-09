module hdmi_top(

	input wire clk,

	input wire reset,
	
	input wire [23:0] vga_rgb,
	input wire vga_hs,
	input wire vga_vs,
	input wire vga_de,
	
	output wire [3:0] tmds_p,
	output wire [3:0] tmds_n
);

// clocks
wire clk_hdmi, clk_hdmi_n;
wire p_clk_int, p_clk_div2;
wire [7:0] hdmi_freq;
wire lockedx5;
wire pll_reset;

hdmi_pll hdmi_pll (
	.clk(clk),
	.reset(reset),
	.clk_hdmi(clk_hdmi),
	.clk_hdmi_n(clk_hdmi_n),
	.clk_pix(p_clk_int),
	.clk_pix2(p_clk_div2),
	.freq(hdmi_freq),
	.locked(lockedx5),
	.o_reset(pll_reset)
);

// reg signals in p_clk_int clock
reg [23:0] host_vga_rgb;
reg host_vga_hs, host_vga_vs, host_vga_blank;

always @(posedge p_clk_int) begin
	host_vga_rgb <= (vga_de) ? vga_rgb : 24'b0;
	host_vga_hs <= vga_hs;
	host_vga_vs <= vga_vs;
	host_vga_blank <= ~vga_de;
end

// dvi only

wire [9:0] dvi_red, dvi_green, dvi_blue;

dvi dvi(
	.CLK(p_clk_int),
	.RESET(pll_reset),
	.RGB(host_vga_rgb),
	.HSYNC(host_vga_hs),
	.VSYNC(host_vga_vs),
	.DE(~host_vga_blank),
	.ENC_RED(dvi_red),
	.ENC_GREEN(dvi_green),
	.ENC_BLUE(dvi_blue)
);

// serializer

hdmi_out_xilinx hdmiio(
	.clock_pixel_i(p_clk_int),
	.clock_tdms_i(clk_hdmi),
	.clock_tdms_n_i(clk_hdmi_n),
	.red_i(dvi_red),
	.green_i(dvi_green),
	.blue_i(dvi_blue),
	.tmds_out_p(tmds_p),
	.tmds_out_n(tmds_n)
);

endmodule
