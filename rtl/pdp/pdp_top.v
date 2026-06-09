//  Проект DVK-FPGA
//
//  Интерфейсный модуль для платы QMTECH Cyclone IV
//=================================================================
//
`include "config.v"

module pdp_top(
	input					clk50,
	input					clk_p,
	input					clk_n,
	input					sdclock,
	input					clkrdy,
	input					rst_n,
	input 		[1:0] button,
	input					sw_slow,			// переключатели конфигурации
	input			[7:0] sw_bank,

   // Интерфейс SRAM
	output	[20:0]	MA,
	inout		[15:0]	MD,
	output	[1:0]		MWR_N,
	output	[1:0]		MRD_N,
	
   // интерфейс SD-карты
   output				sdcard_cs, 
   output				sdcard_mosi, 
   output				sdcard_sclk, 
   input					sdcard_miso, 

   // дополнительный UART 
   output				irps_txd,
   input					irps_rxd,
	
	// TOY
	output			[7:0]		rtc_a,
	input				[7:0]		rtc_di,
	
	output			[7:0]		leds
) ;

	//********************************************
	//* Светодиоды
	//********************************************
	wire disk_led, timer_led, led2, led1, led3 ;

//	assign led[0] = disk_led ;    // запрос обмена диска 
//	assign led[1] = ~led1 ;      // Индикатор состояния процессора 1
//	assign led[2] = ~led2 ;      // Индикатор состояния процессора 2
//	assign led[3] = ~led3 ;      // Индикатор состояния процессора 3
//	assign led[4] = ~timer_led ; // индикация включения таймера

	//************************************************
	//* тактовый генератор 
	//************************************************
	wire [2:0] cons_dispreg_leds ;
	
	assign leds = {cons_dispreg_leds[0], cons_dispreg_leds[1], cons_dispreg_leds[2], disk_led, led3, led1, timer_led, led2} ;

	reg [1:0] slow_filter ;

	always @ (posedge clk_p)  begin
		slow_filter[0] <= sw_slow ;
		slow_filter[1] <= slow_filter[0] & sw_slow ;
	end

	wire sdram_reset;
	wire sdram_we;
	wire sdram_stb;
	wire [1:0] sdram_sel;
	wire sdram_ack ;
	wire [21:1] sdram_adr;
	wire [15:0] sdram_out;
	wire [15:0] sdram_dat ;
	wire sdram_ready = 1'b1 ;

	sram ram(
		.clk_p(clk_p),
		.sdram_stb(sdram_stb),
		.sdram_we(sdram_we),
		.sdram_sel(sdram_sel),
		.sdram_adr(sdram_adr[21:1]),
		.sdram_out(sdram_out),
		.sdram_ack(sdram_ack),
		.sdram_dat(sdram_dat),
		.MA(MA),
		.MD(MD),
		.MWR_N(MWR_N),
		.MRD_N(MRD_N)
	) ;

	//************************************
	//* Соединительная плата
	//************************************

	`TOPBOARD kernel(
		.clk50(clk50),                  // 50 МГц
		.clk_p(clk_p),                  // тактовая частота процессора, прямая фаза
		.sdclock(sdclock),              // тактовая частота SD-карты
		.clkrdy(clkrdy),                // готовность PLL
		
		.bt_reset(~button[0]),          // общий сброс
		.bt_halt(~button[1]),           // режим программа-пульт / выход из состояния HALT
		.bt_terminal_rst(1'b0),         // сброс терминальной подсистемы
		.bt_timer(1'b0),               // выключатель таймера
		
		.sw_diskbank(sw_bank),   // выбор дискового банка
		.sw_cpuslow(slow_filter[1]),             // режим замедления процессора
		
		// индикаторные светодиоды      
		.disk_led(disk_led),               // запрос обмена диска
		.timer_led(timer_led),         // индикация включения таймера
		.led1(led1),               // признак ожидания прерывания по WAIT
		.led3(led3),                // признак включения MMU 
		.led2(led2),                // признак ативности секвенсера
		
		// Интерфейс SDRAM
		.sdram_reset(sdram_reset),     // сброс
		.sdram_stb(sdram_stb),         // строб начала транзакции
		.sdram_we(sdram_we),           // разрешение записи
		.sdram_sel(sdram_sel),         // выбор байтов
		.sdram_ack(sdram_ack),         // подтверждение транзакции
		.sdram_adr(sdram_adr),         // шина адреса
		.sdram_out(sdram_out),         // выход шины данных
		.sdram_dat(sdram_dat),         // вход шины данных
		.sdram_ready(sdram_ready),     // флаг готовности SDRAM

		// интерфейс SD-карты
		.sdcard_cs(sdcard_cs), 
		.sdcard_mosi(sdcard_mosi), 
		.sdcard_sclk(sdcard_sclk), 
		.sdcard_miso(sdcard_miso), 
		
		// дополнительный UART 
		.irps_txd(irps_txd),
		.irps_rxd(irps_rxd),

		.cons_dispreg_leds(cons_dispreg_leds),

		.rtc_a(rtc_a),
		.rtc_di(rtc_di)
	);
	
endmodule
