module pr11(
	input							clk_p,
	input							sys_init,

	// BUS
	input				[21:0]	wb_adr_i,
	input				[15:0]	wb_dat_i,
	output	reg	[15:0]	wb_dat_o,
	input							bus_stb,
	input							wb_we_i,
	input				[1:0]		wb_sel_i,
	output	reg				pr11_ack,
	
   // IRQ
	output reg             irq,         // запрос
   input                  iack,        // подтверждение

	input							fload_state,
	input			[7:0]			fload_slot,
	input			[15:0]		fload_size,
	input			[7:0]			fload_data,
	input							fload_wr
) ;
	// FILE LOAD
	reg prev_fload_state = 1'b0 ;
	reg [12:0] bytes_available = 13'b0 ;
	reg [7:0] buffer[8191:0] ;
	
	always @(posedge clk_p) begin
		if (sys_init) begin
			prev_fload_state <= 1'b0 ;
			bytes_available <= 13'b0 ;
		end else begin
			prev_fload_state <= fload_state ;
			
			if (prev_fload_state == 1'b0 && fload_state == 1'b1) begin
				bytes_available <= 13'b0 ;
			end
			
			if (fload_state == 1'b1 && fload_wr == 1'b1) begin
				bytes_available <= bytes_available + 1'b1 ;
				buffer[bytes_available] <= fload_data ;
			end
		end
	end

	wire [14:0] adr_i = wb_adr_i[15:1] ;
	wire pr11_stb = bus_stb & ((adr_i == 15'o77664) || (adr_i == 15'o77665)) ; // 177550, 177552
	
	reg [15:0] csr = 16'b0 ; // command-status 177550
	reg [15:0] dbr = 16'b0 ;   // data 177552
	
	localparam IS_IDLE = 2'd0 ;    // ожидание прерывания
	localparam IS_REQ  = 2'd1 ;     // запрос векторного прерывания
	localparam IS_WAIT = 2'd2 ;    // ожидание обработки прерывания со стороны процессора

	reg[1:0] interrupt_state = IS_IDLE ;
	reg interrupt_trigger = 1'b0 ;
	wire ie = csr[6] ; // interrupt enabled
	
	localparam PS_IDLE	= 3'd0 ;
	localparam PS_GO		= 3'd1 ;
	
	reg [2:0] pr_state = PS_IDLE ;
	
	reg [12:0] bytes_required = 13'b0 ;

	always @(posedge clk_p) begin
		if (sys_init) begin
			csr <= 16'b0 ;
			dbr <= 16'b0 ;
			irq <= 1'b0 ;
			pr11_ack	<= 1'b0 ;
			bytes_required <= 13'b0 ;
			interrupt_trigger <= 1'b0 ;
			pr_state <= PS_IDLE ;
			interrupt_state <= IS_IDLE ;
		end else begin
			case (interrupt_state)
				IS_IDLE : begin
					if (ie & interrupt_trigger) begin
						irq <= 1'b1 ;
						interrupt_state <= IS_REQ ;
					end else
						irq <= 1'b0 ;
				end
				
				IS_REQ : begin
					if (~ie) begin
						interrupt_trigger <= 1'b0 ;
						interrupt_state <= IS_IDLE ;
					end else if (iack) begin
						irq <= 1'b0 ;
						interrupt_trigger <= 1'b0 ;
						interrupt_state <= IS_WAIT ;
					end
				end
				
				IS_WAIT :
					if (~iack)
						interrupt_state <= IS_IDLE ;
			endcase
		
			if (pr11_stb) begin
				if (wb_we_i) begin
					if (wb_sel_i[0])
						case (adr_i)
							15'o77664 : begin
								csr[0] <= wb_dat_i[0] ; //only bits 6,0 is write-able
								csr[6] <= wb_dat_i[6] ;
								
								if (wb_dat_i[0]) begin
									if (csr[15]) begin  // Operation of this bit is disabled if Error = 1; attempting to set it when Error = 1 will cause an immediate interrupt if Interrupt Enable = 1. 
										csr[0] <= 1'b0 ;
										if (ie | wb_dat_i[6])
											interrupt_trigger <= 1'b1 ;
									end else begin  // if GO - clear buffer; clear done and set busy
										dbr <= 16'b0 ;
										csr[7] <= 1'b0 ;
										csr[11] <= 1'b1 ;
									end
								end
							end
						endcase
				end else begin
					case (adr_i)
						15'o77664 : wb_dat_o <= csr ;
						
						15'o77665 : begin
							wb_dat_o <= dbr ;
							csr[7]	<= 1'b0 ; // clear done
						end
					endcase
				end
				pr11_ack <= 1'b1 ;
			end else begin
				pr11_ack	<= 1'b0 ;
				if (prev_fload_state == 1'b0 && fload_state == 1'b1) begin
					bytes_required <= 13'b0 ;
				end
				
				case (pr_state)
					PS_IDLE : begin
						if (csr[0]) begin
							csr[0] <= 1'b0 ;
							pr_state <= PS_GO ;
						end
					end
					
					PS_GO : begin
						if (!(bytes_required > bytes_available)) begin
							csr[7] <= 1'b1 ;
							if (ie)
								interrupt_trigger <= 1'b1 ;
							csr[11] <= 1'b0 ;
							dbr[7:0] <= buffer[bytes_required] ;
							bytes_required <= bytes_required + 1'b1 ;
							pr_state <= PS_IDLE ;
						end
					end
				endcase
			end
			
			csr[15] <= (bytes_required > fload_size[12:0]) ;
		end
	end
endmodule
