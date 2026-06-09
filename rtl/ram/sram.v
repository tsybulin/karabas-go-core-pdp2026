module sram(
   input          		clk_p,        // основной синхросигнал, прямая фаза
   input         			sdram_stb,    // строб транзакции
   input         			sdram_we,     // разрешение записи
   input			[1:0]		sdram_sel,    // выбор байтов
	input 		[21:1]	sdram_adr,    // шина адреса
   input 		[15:0]	sdram_out,    // шина данных хост -> память
	output reg				sdram_ack,    // подтверждение транзакции
	output reg	[15:0]	sdram_dat,    // шина данных память -> хост
	
	output reg	[20:0]	MA,
	inout	 		[15:0]	MD,
	output reg	[1:0]		MWR_N,
	output reg	[1:0]		MRD_N
) ;

	localparam [3:0] MS_INIT    = 0 ;
	localparam [3:0] MS_IDLE    = 1 ;
	localparam [3:0] MS_READ1   = 2 ;
	localparam [3:0] MS_READ2   = 3 ;
	localparam [3:0] MS_READ3   = 4 ;
	localparam [3:0] MS_WRITE1  = 5 ;
	localparam [3:0] MS_WRITE2  = 6 ;
	localparam [3:0] MS_WRITE3  = 7 ;
	localparam [3:0] MS_WRITE4  = 8 ;

	reg [3:0] mem_state = MS_INIT ;
	
	reg mwe ;
	reg [15:0] memdata_o = 16'd0 ;
	assign MD = mwe ? memdata_o : 16'hZZZZ ;
	
	always @(posedge clk_p) begin
		case (mem_state)
			MS_INIT : begin
				mwe <= 1'b0 ;
				MA <= 16'd0 ;
				MRD_N <= 2'b11 ;
				MWR_N <= 2'b11 ;
				sdram_ack <= 1'b0 ;
				mem_state <= MS_IDLE ;
			end
			
			MS_IDLE : begin
				if (sdram_stb == 1'b1) begin
					MA <= sdram_adr ;
					if (sdram_we == 1'b0)
						mem_state <= MS_READ1 ;
					else
						mem_state <= MS_WRITE1 ;
				end 
			end

			MS_READ1 : begin
				MRD_N <= 2'b00 ;
				mem_state <= MS_READ2 ;
			end

			MS_READ2 : begin
				sdram_dat <= MD ;
				sdram_ack <= 1'b1 ;
				mem_state <= MS_READ3 ;
			end

			MS_READ3 : begin
				MRD_N <= 2'b11 ;
				if (sdram_stb == 1'b0) begin
					sdram_ack <= 1'b0 ;
					mem_state <= MS_IDLE ;
				end
			end

			MS_WRITE1 : begin
				memdata_o <= sdram_out ;
				mwe <= 1'b1 ;
				mem_state <= MS_WRITE2 ;
			end

			MS_WRITE2 : begin
				MWR_N <= {~sdram_sel[1], ~sdram_sel[0]} ;
				mem_state <= MS_WRITE3 ;
			end

			MS_WRITE3 : begin
				MWR_N <= 2'b11 ;
				sdram_ack <= 1'b1 ;
				mem_state <= MS_WRITE4 ;
			end
			
			MS_WRITE4 : begin
				mwe <= 1'b0 ;
				if (sdram_stb == 1'b0) begin
					sdram_ack <= 1'b0 ;
					mem_state <= MS_IDLE ;
				end
			end
		endcase
	end
	

endmodule
