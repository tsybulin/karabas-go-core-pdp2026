`timescale 1ns / 1ps

module dpram #(parameter DATAWIDTH=8, ADDRWIDTH=8, NUMWORDS=1<<ADDRWIDTH, MEM_INIT_FILE="")
(
	input	wire                 clka,
	input wire						clkb,

	input	wire [ADDRWIDTH-1:0] address_a,
	input	wire [DATAWIDTH-1:0] data_a,
	input	wire                 wren_a,
	output reg [DATAWIDTH-1:0] q_a,

	input	wire [ADDRWIDTH-1:0] address_b,
	input	wire [DATAWIDTH-1:0] data_b,
	output reg [DATAWIDTH-1:0] q_b
);

   reg [DATAWIDTH-1:0] mem[0:NUMWORDS];
   initial begin  // usa $readmemb/$readmemh dependiendo del formato del fichero que contenga la ROM
    if (MEM_INIT_FILE != "") begin
      $readmemh(MEM_INIT_FILE, mem);
    end
   end

  always @(posedge clka) begin
    if (wren_a) begin
      mem[address_a] <= data_a;
      q_a <= data_a;
    end else
      q_a <= mem[address_a];
  end

  always @(posedge clkb) begin
      q_b <= mem[address_b];
  end


endmodule
