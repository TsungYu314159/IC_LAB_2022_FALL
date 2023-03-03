`timescale 1ns/100ps
`include "PATTERN.v"
`ifdef RTL
    `include "MH.v"
`endif
`ifdef GATE
    `include "MH_SYN.v"
`endif
`ifdef APR
    `include "CHIP_SYN.v"
`endif

`ifdef POST
    `include "CHIP.v"
`endif

module TESTBED();
//Connection wires
wire			  clk,clk2,rst_n;
wire			  in_valid;
wire 			  op_valid;
wire [2:0] 		  op;
wire [31:0]       pic_data;     
wire [7:0]        se_data;     
wire              out_valid;          
wire [31:0]		  out_data;


// -----------------------------
initial begin
    `ifdef RTL
        //$fsdbDumpfile("MH.fsdb");
        //$fsdbDumpvars(0,"+mda");
    `endif
    `ifdef GATE
        $sdf_annotate("MH_SYN.sdf", u_MH);
        //$fsdbDumpfile("MH_SYN.fsdb");
		//$fsdbDumpvars(0,"+mda"); 
    `endif
    `ifdef APR
        $sdf_annotate("MH_SYN.sdf", U_CHIP.CORE);
        //$fsdbDumpfile("CHIP_SYN.fsdb");
        //$fsdbDumpvars(2,"+mda");
    `endif
    `ifdef POST
        $sdf_annotate("CHIP.sdf", U_CHIP);
        //$fsdbDumpfile("CHIP.fsdb");
        //$fsdbDumpvars(2,"+mda");
    `endif
end
`ifdef RTL
MH u_MH(
    .clk(clk),
    .clk2(clk2),
    .rst_n(rst_n),
    .in_valid(in_valid),
	.pic_data(pic_data),
	.se_data(se_data),
	.op_valid(op_valid),
	.op(op),
	.out_valid(out_valid),
	.out_data(out_data)
	);
`endif
`ifdef GATE
    MH u_MH(
    .clk(clk),
    .clk2(clk2),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .pic_data(pic_data),
    .se_data(se_data),
    .op_valid(op_valid),
    .op(op),
    .out_valid(out_valid),
    .out_data(out_data)
    );
`endif
`ifdef APR
    CHIP U_CHIP(
    .clk(clk),
    .clk2(clk2),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .pic_data(pic_data),
    .se_data(se_data),
    .op_valid(op_valid),
    .op(op),
    .out_valid(out_valid),
    .out_data(out_data)
    );
`endif
`ifdef POST
    CHIP U_CHIP(
    .clk(clk),
    .clk2(clk2),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .pic_data(pic_data),
    .se_data(se_data),
    .op_valid(op_valid),
    .op(op),
    .out_valid(out_valid),
    .out_data(out_data)
    );
`endif
PATTERN u_PATTERN(
    .clk(clk),
    .clk2(clk2),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .op_valid(op_valid),
    .pic_data(pic_data),
    .se_data(se_data),
    .op(op),
	.out_valid(out_valid),
	.out_data(out_data)
);
endmodule
