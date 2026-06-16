`timescale 1ns / 1ps
/*-------------------------------------------------------------------------------------------------------------------
-- 
-- 
-- #       #######                                                 #                                               
-- #                                                               #                                               
-- #                                                               #                                               
-- ############### ############### ############### ############### ############### ############### ############### 
-- #             #               # #                             # #             #               # #               
-- #             # ############### #               ############### #             # ############### ############### 
-- #             # #             # #               #             # #             # #             #               # 
-- #             # ############### #               ############### ############### ############### ############### 
--                                                                                                                 
--         ####### ####### ####### #######                                         ############### ############### 
--                                                                                 #               #             # 
--                                                                                 #   ########### #             # 
--                                                                                 #             # #             # 
-- https://github.com/andykarpov/karabas-go                                        ############### ############### 
--
-- FPGA pdp-11/70 core for Karabas-Go
--
-- @author Pavel Tsybulin, 2026
-- @author Andy Karpov <andy.karpov@gmail.com>
-- EU, 2026
------------------------------------------------------------------------------------------------------------------*/

module karabas_go_top(
	input 				CLK_50MHZ,
	
	//--------- SRAM ------------------
	output	[20:0]	MA,
	inout		[15:0]	MD,
	output	[1:0]		MWR_N,
	output	[1:0]		MRD_N,

	//--------- SD2 ------------------
	output				SD_CS_N,
	output				SD_CLK,
	inout					SD_DI,
	inout					SD_DO,
	input					SD_DET_N,

	//---------- VGA -----------------
	output	[7:0] 	VGA_R,
	output	[7:0] 	VGA_G,
	output	[7:0] 	VGA_B,
	output				VGA_HS,
	output				VGA_VS,
	output				V_CLK,

	//---------- VDAC2 -----------------
	output				FT_OE_N,

	//---------------------------	
	output reg			BEEPER,

	//---------- DAC -----------------
	output				DAC_LRCK,
	output				DAC_DAT,
	output				DAC_BCK,
	output				DAC_MUTE,

	//--------- MCU ------------------
	input					MCU_CS_N,
	input					MCU_SCK,
	inout					MCU_MOSI,
	output				MCU_MISO
) ;

	assign DAC_MUTE		= 1'b1 ; // _N, Unmuted
	
	wire clk10, clkready, clk_p, clk_n, sdclock ;
	
	pll pll_top(
		.inclk0(CLK_50MHZ),
		.areset(1'b0),
		.locked(clkready),
		.c0(clk10), 	// 10MHz VT100
		.c1(clk_p),		// 50MHz CPU
		.c2(clk_n),		// 50Mhz CPU 180deg
		.c3(sdclock)	//	12.5Mhz SD Card
	) ;
	
	wire areset = ~clkready ;

	// mouse / cursor
	wire [7:0] ms_x, ms_y, cursor_x, cursor_y ;
	wire [3:0] ms_z, cursor_z ;
	wire [2:0] ms_b, cursor_b ;
	wire ms_upd ;
	
	// kbd
	wire [7:0] hid_kb_status, hid_kb_dat0, hid_kb_dat1, hid_kb_dat2 ;
	wire [7:0] hid_kb_dat3, hid_kb_dat4, hid_kb_dat5, ps2_scancode ;
	wire ps2_scancode_upd ;
	
	// joy
	wire [12:0] joy_l, joy_r ;
	
	// hw buttons
	wire [1:0] hw_btn ;
	
	// soft switches
	wire sw_reset, sw_cont, sw_slow, sw_leds ;
	wire [1:0] sw_color, sw_sound ;
	wire [7:0] sw_bank ;
	wire [2:0] sw_bank_offset ;
	
	// RTC
	wire [7:0] rtc_addr, rtc_di, rtc_do ;
	wire rtc_wr, rtc_rd ;
	
	// UART
	wire [7:0] uart_rx_data, uart_rx_idx, uart_tx_data, uart_dlm, uart_dll ;
	wire uart_dll_wr, uart_dlm_wr ;
	wire uart_tx_mode = 1'b1 ;
	reg  uart_tx_wr = 1'b0 ;
	
	// ROM Loader
	wire loader_act, loader_wr ;
	wire [21:1] loader_addr ;
	wire [15:0] loader_data ;
	
	// OSD cmd
	wire [15:0] softsw_command, osd_command ;
	
	wire mcu_busy ;
	
	// LEDS
	wire [7:0] leds ;
	
	// DEBUG
	wire [15:0] debug_addr ;
	wire [15:0] debug_data ;
	
	mcu mcu(
		.CLK(clk_p),
		.N_RESET(~areset),

		.MCU_MOSI(MCU_MOSI),
		.MCU_MISO(MCU_MISO),
		.MCU_SCK(MCU_SCK),
		.MCU_SS(MCU_CS_N),

		.MS_X(ms_x),
		.MS_Y(ms_y),
		.MS_Z(ms_z),
		.MS_B(ms_b),
		.MS_UPD(ms_upd),

		.KB_STATUS(hid_kb_status),
		.KB_DAT0(hid_kb_dat0),
		.KB_DAT1(hid_kb_dat1),
		.KB_DAT2(hid_kb_dat2),
		.KB_DAT3(hid_kb_dat3),
		.KB_DAT4(hid_kb_dat4),
		.KB_DAT5(hid_kb_dat5),

		.KB_SCANCODE(ps2_scancode),
		.KB_SCANCODE_UPD(ps2_scancode_upd),

		.JOY_L(joy_l),
		.JOY_R(joy_r),

		.BTNS(hw_btn),

		.RTC_A(rtc_addr),
		.RTC_DI(rtc_di),
		.RTC_DO(rtc_do),
		.RTC_CS(1'b1),
		.RTC_WR_N(~rtc_wr),

		.UART_RX_DATA(uart_rx_data),
		.UART_RX_IDX(uart_rx_idx),	 
		.UART_TX_DATA(uart_tx_data),
		.UART_TX_WR(uart_tx_wr),
		.UART_TX_MODE(uart_tx_mode),
		.UART_DLL(uart_dll),
		.UART_DLM(uart_dlm),
		.UART_DLL_WR(uart_dll_wr),
		.UART_DLM_WR(uart_dlm_wr),

		.ROMLOADER_ACTIVE(loader_act),
		.ROMLOAD_ADDR(loader_addr),
		.ROMLOAD_DATA(loader_data),
		.ROMLOAD_WR(loader_wr),

		.SOFTSW_COMMAND(softsw_command),	
		.OSD_COMMAND(osd_command),

		.DEBUG_ADDR(debug_addr),
		.DEBUG_DATA(debug_data),

		.BUSY(mcu_busy)
	) ;
	
	// VIDEO
	
	assign FT_OE_N = 1'b1 ; // disable FT
	
	wire vga_hsync, vga_vsync, vga_clk ;
	wire [7:0] vgar, vgag, vgab ;
	
	assign VGA_HS = vga_hsync ;
	assign VGA_VS = vga_vsync ;
	assign V_CLK  = vga_clk ;
	
	overlay#(.HDMI(1'b0)) overlay(
		.CLK(clk_p),
		.CLK_VGA(vga_clk),
		.RGB_I({vgar, vgag, vgab}),
		.RGB_O({VGA_R, VGA_G, VGA_B}),
		.HSYNC_I(vga_hsync),
		.VSYNC_I(vga_vsync),
		.OSD_COMMAND(osd_command),
		
		.sw_leds(sw_leds),
		.leds(leds),
		.no_sd(SD_DET_N)
	) ;
	
	// VT100
	
	wire tx, rx ;
	wire vgao, audio_o, vga_blank ;
	reg  audio_i ;
	
	always @(posedge clk_n)
		case (sw_sound)
			2'b00 : begin
				BEEPER <= audio_o ;
				audio_i <= 1'b0 ;
			end
			
			2'b01 : begin
				BEEPER <= 1'b0 ;
				audio_i <= audio_o ;
			end
			
			default : begin
				BEEPER <= 1'b0 ;
				audio_i <= 1'b0 ;
			end
		endcase
	
	vt100_top vt100(
		.clkin(clk_p),
		.c0(clk10),
		.resetbtn(1'b1),
		.tx(tx),
		.rx(rx),
		.vgao(vgao),
		.vgah(vga_hsync),
		.vgav(vga_vsync),
		.vgaclk(vga_clk),
		.vga_blank(vga_blank),
		.ps2k_upd(ps2_scancode_upd),
		.ps2k_dat(ps2_scancode),
		.audio(audio_o)
	) ;
	
	//                                        Amber                        Green    White
	assign vgar = vgao ? sw_color == 2'b00 ? 8'd255 : sw_color == 2'b01 ? 8'd51  : 8'd255 : 8'd0 ;
	assign vgag = vgao ? sw_color == 2'b00 ? 8'd183 : sw_color == 2'b01 ? 8'd255 : 8'd255 : 8'd0 ;
	assign vgab = vgao ? sw_color == 2'b00 ? 8'd0   : sw_color == 2'b01 ? 8'd51  : 8'd255 : 8'd0 ;
	
	// AUDIO
	dac vt100dac(
		.clk(clk_n),
		.speaker(audio_i),
		.din(DAC_DAT),
		.lrck(DAC_LRCK),
		.bck(DAC_BCK)
	) ;

	// SOFT SWITCHES
	
	soft_switches sosw(
		.clk(clk_p),
		.sw_command(softsw_command),
		.sw_reset(sw_reset),
		.sw_cont(sw_cont),
		.sw_slow(sw_slow),
		.sw_bank_offset(sw_bank_offset),
		.sw_bank(sw_bank),
		.sw_color(sw_color),
		.sw_leds(sw_leds),
		.sw_sound(sw_sound)
	) ;
	
	// PDP
	
	reg mcu_load = 1'b1 ;
	reg prev_loader_act = 1'b0 ;
	reg [1:0] buttons = 2'b11 ;
	
	always @(posedge clk_p) begin
		buttons[1] <= ~(sw_cont | hw_btn[0]) ;
		buttons[0] <= ~(sw_reset | hw_btn[1] | mcu_load) ;
		
		if (loader_act != prev_loader_act) begin
			prev_loader_act <= loader_act ;
			if (prev_loader_act == 1'b1) begin
				mcu_load <= 1'b0 ;
			end
		end
	end

	pdp_top mainboard(
		.clk50(clk_p),
		.clk_p(clk_p),
		.clk_n(clk_n),
		.sdclock(sdclock),
		.clkrdy(clkready),
		.rst_n(1'b1),
		.button(buttons),
		.sw_slow(sw_slow),
		.sw_bank_offset(sw_bank_offset),
		.sw_bank(sw_bank),
		.MA(MA),
		.MD(MD),
		.MWR_N(MWR_N),
		.MRD_N(MRD_N),
		.sdcard_cs(SD_CS_N),
		.sdcard_mosi(SD_DI),
		.sdcard_sclk(SD_CLK),
		.sdcard_miso(SD_DO),
		.irps_txd(rx),
		.irps_rxd(tx),
		.rtc_a(rtc_addr),
		.rtc_di(rtc_do),
		.leds(leds),
		.loader_wr(loader_wr),
		.loader_addr(loader_addr),
		.loader_data(loader_data) 
	) ;
	
endmodule
