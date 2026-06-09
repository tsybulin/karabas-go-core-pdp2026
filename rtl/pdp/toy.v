module toy11(
	input							clk_p,
	input							sys_init,
	input				[21:0]	wb_adr_i,
	input				[15:0]	wb_dat_i,
	output	reg	[15:0]	wb_dat_o,
	input							bus_stb,
	input							wb_we_i,
	input				[1:0]		wb_sel_i,
	output	reg				toy_ack,
	
	output			[7:0]		rtc_a,
	input				[7:0]		rtc_di
) ;
	wire [14:0] adr_i = wb_adr_i[15:1] ;
	wire toy_stb = bus_stb & ((adr_i == 15'o77653) || (adr_i == 15'o77654) || (adr_i == 15'o77655) || (adr_i == 15'o77656)) ; // 177526..177534

	//  [0] : go read
	//  [1] : go write
	//  [7] : i2c done
	// [15] : i2c err
	reg [15:0] csr = 16'o200 ; // command-status register 177526

	reg i2cdone = 1'b1 ; 
	wire i2cerr = 1'b0 ;
	
	reg [7:0]	seconds_r, seconds_o,
					minutes_r, minutes_o,
					hours_r,   hours_o,
					days_r,    days_o,
					months_r,  months_o,
					years_r,   years_o ;
	
	// 7..0 - addr
	// 8 - go
	// 9 - step
	reg [9:0] i2cs = 8'd0 ;
	assign rtc_a = i2cs[7:0] ;

	always @(posedge clk_p) begin
		if (csr[0]) begin
			i2cdone <= 1'b0 ;
			i2cs[9:8] <= 2'b01 ; // lets go from addr 0, step 0
			i2cs[7:0] <= 8'd0 ;
		end
		
		casex (i2cs)
			10'b01xxxxxxxx : begin // addr set, next step
				i2cs[9] <= 1'b1 ;
			end
			
			// get data
			10'b1100000000 : begin
				seconds_r <= rtc_di ;
				i2cs <= 10'b0100000001 ;
			end

			10'b1100000001 : begin
				minutes_r <= rtc_di ;
				i2cs <= 10'b0100000010 ;
			end
			
			10'b1100000010 : begin
				hours_r   <= rtc_di ;
				i2cs <= 10'b0100000100 ;
			end
			
			10'b1100000100 : begin
				days_r    <= rtc_di ;
				i2cs <= 10'b0100000101 ;
			end
			
			10'b1100000101 : begin
				months_r  <= rtc_di ;
				i2cs <= 10'b0100000110 ;
			end

			10'b1100000110 : begin
				years_r <= rtc_di ;
				i2cs <= 10'd0 ; // the end
				i2cdone <= 1'b1 ;
			end
		endcase
	end
	
	always @(posedge clk_p) begin
			csr[1:0] <= 2'b0 ;

			if (sys_init) begin
				toy_ack <= 1'b0 ;
				csr <= 16'b0 ;
			end else if (toy_stb) begin
				{csr[15], csr[7]} <= {i2cerr, i2cdone} ;
				
				if (wb_we_i) begin
					if (wb_sel_i[0])
						case (adr_i)
							15'o77653 : csr[1:0] <= wb_dat_i[1:0] ;
							15'o77654 : seconds_o <= wb_dat_i[7:0] ;
							15'o77655 : hours_o <= wb_dat_i[7:0] ;
							15'o77656 : months_o <= wb_dat_i[7:0] ;
						endcase
					
					if (wb_sel_i[1])
						case (adr_i)
							15'o77654 : minutes_o <= wb_dat_i[15:8] ;
							15'o77655 : days_o <= wb_dat_i[15:8] ;
							15'o77656 : years_o <= wb_dat_i[15:8] ;
						endcase
				end else begin
					case (adr_i)
						15'o77653 : wb_dat_o <= csr ;
						15'o77654 : wb_dat_o <= {minutes_r, seconds_r} ;
						15'o77655 : wb_dat_o <= {days_r, hours_r} ;
						15'o77656 : wb_dat_o <= {years_r, months_r} ;
					endcase
				end
				
				toy_ack <= 1'b1 ;
			end else
				toy_ack <= 1'b0 ;
	end
endmodule
