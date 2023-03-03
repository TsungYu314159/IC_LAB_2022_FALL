//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN_IP.v
//   Module Name : PATTERN_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL
    `define CYCLE_TIME 6.0
`endif

`ifdef GATE
    `define CYCLE_TIME 6.0
`endif

module PATTERN_IP #(parameter WIDTH = 4, parameter DIGIT = 2) (
    // Input signals
    Binary_code,
    // Output signals
    BCD_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
output reg [WIDTH-1:0]   Binary_code;
input      [DIGIT*4-1:0] BCD_code;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
real CYCLE = `CYCLE_TIME;
parameter pat_num=30;
integer SEED=0;
integer i,j,dec_num;

//================================================================
// Wire & Reg Declaration
//================================================================
reg clk;

//================================================================
// Clock
//================================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// Initial
//================================================================
initial begin
	for(i=0;i<pat_num;i=i+1)begin
		Binary_code=$random(SEED);
		@(negedge clk);
		dec_num=0;
		for(j=0;j<DIGIT;j=j+1)begin
			dec_num=dec_num+BCD_code[(j*4)+:4]*(10**j);
		end
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m BCD_CODE is %b , Binary input is %d",i,BCD_code,Binary_code);
		if(dec_num!==Binary_code)begin
			$display("\033[5;31;40m ERROR\033[0m","\033[0;33;");
			$finish;
		end
		repeat(5)@(negedge clk);
	end
	$display("\033[5;32;40mPASS ALL\033[0m","\033[0;33;");
	$finish;
	
end

//================================================================
// TASK
//================================================================



endmodule