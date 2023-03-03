// synopsys translate_off 
`ifdef RTL
`include "GATED_OR.v"
`else
`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on
module SP(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	in_mode,
	// Output signals
	out_valid,
	out_data
);

// INPUT AND OUTPUT DECLARATION  
input		clk;
input		rst_n;
input		in_valid;
input		cg_en;
input [8:0] in_data;
input [2:0] in_mode;

output reg 		  out_valid;
output reg signed[9:0] out_data;
//---------------------------------------------------------------------
//   	WIRE & REG
//---------------------------------------------------------------------
reg  [2:0] c_state;
reg  [2:0] n_state;

reg  [8:0] in_data_reg;
wire [8:0] transform;
wire [8:0] trans_data;
reg  [9:0] data[8:0];
reg  [9:0] addsub_data[8:0];
reg  [9:0] SMA_data[8:0];
reg  [2:0] in_mode_reg;
reg  input_counter;
wire [9:0] sorted_data [8:0];
reg  [9:0] output_data[1:0];
//reg  [9:0] output_data [8:0];
reg  [1:0] out_counter;
reg  flag_minmax;

reg signed [9:0] min;
reg signed [9:0] max;
reg [9:0] minmax_diff;
reg signed [10:0] mid_point;
//---------------------------------------------------------------------
//   	PARAMETER
//---------------------------------------------------------------------
parameter IDLE   = 3'd0;
parameter INPUT  = 3'd1;
parameter MODE_1 = 3'd2;
parameter MODE_2 = 3'd3;
parameter OUT    = 3'd4;
//---------------------------------------------------------------------
//   	GATED CLK
//---------------------------------------------------------------------
wire clk_input;
reg clk_sleep_input;
GATED_OR GATED_INPUT (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_en&&clk_sleep_input),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(clk_input)
);
always@(*) begin
	clk_sleep_input = !((c_state == INPUT)||(c_state == IDLE));
end

wire clk_input_1cycle;
reg clk_sleep_input_1cycle;
GATED_OR GATED_INPUT_1cycle (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_en&&clk_sleep_input_1cycle),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(clk_input_1cycle)
); 
always@(*) begin
	clk_sleep_input_1cycle = !(((c_state == INPUT)||(c_state == IDLE)) && (input_counter==0));
end

wire clk_mode2;
reg clk_sleep_mode2;
GATED_OR GATED_MODE2 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_en&&clk_sleep_mode2),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(clk_mode2)
); 
always@(*) begin
	clk_sleep_mode2 <= !((c_state == MODE_2)||(c_state == MODE_1));
end


wire clk_minmax;
reg clk_sleep_minmax;
GATED_OR GATED_MINMAX (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_en&&clk_sleep_minmax),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(clk_minmax)
);
always@(*) begin
	clk_sleep_minmax = !((c_state == INPUT) || (c_state == MODE_1));
end

wire clk_out;
reg clk_sleep_out;
GATED_OR GATED_OUT (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_en&&clk_sleep_out),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(clk_out)
);
always@(*) begin
	clk_sleep_out = !((c_state == OUT)||(c_state == MODE_2));
end

wire clk_input_mode2;
reg clk_sleep_input_mode2;
GATED_OR GATED_INPUT_MODE2 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_en&&clk_sleep_input_mode2),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(clk_input_mode2)
);
always@(*) begin
	clk_sleep_input_mode2 = !((c_state == INPUT) || (c_state == MODE_2) || (c_state == MODE_1));
end
//---------------------------------------------------------------------
//   	FSM
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) c_state <= IDLE;
	else c_state <= n_state;
end
always@(*) begin
	case(c_state)
		IDLE: begin
			if(in_valid) n_state = INPUT;
			else n_state = IDLE;
		end
		INPUT: begin
			if(!in_valid) n_state = MODE_1;
			else n_state = INPUT;
		end
		MODE_1: begin
			n_state = MODE_2;
		end
		MODE_2: begin
			n_state = OUT;
		end
		OUT: begin
			if(out_counter == 2) n_state = IDLE;
			else n_state = OUT;
		end
		default: n_state = c_state;
	endcase
end
//---------------------------------------------------------------------
//   	INPUT Block
//---------------------------------------------------------------------
assign transform[8] =  in_data_reg[8];
assign transform[7] =  in_data_reg[7];
assign transform[6] = (in_mode_reg[0]==1)?  transform[7]^in_data_reg[6] 	: 	in_data_reg[6];
assign transform[5] = (in_mode_reg[0]==1)?  transform[6]^in_data_reg[5] 	: 	in_data_reg[5];
assign transform[4] = (in_mode_reg[0]==1)?  transform[5]^in_data_reg[4] 	: 	in_data_reg[4];
assign transform[3] = (in_mode_reg[0]==1)?  transform[4]^in_data_reg[3] 	: 	in_data_reg[3];
assign transform[2] = (in_mode_reg[0]==1)?  transform[3]^in_data_reg[2] 	: 	in_data_reg[2];
assign transform[1] = (in_mode_reg[0]==1)?  transform[2]^in_data_reg[1] 	: 	in_data_reg[1];
assign transform[0] = (in_mode_reg[0]==1)?  transform[1]^in_data_reg[0] 	: 	in_data_reg[0];
assign trans_data = (in_mode_reg[0]==1)? ((transform[8])? {1'b1, ~transform[7:0]+1} : transform ) :  $signed(transform);



always@(posedge clk_input or negedge rst_n) begin
	if(!rst_n) in_data_reg <= 0;
	else begin
		if(n_state == INPUT) in_data_reg <= in_data;
		else in_data_reg <= 0;
	end
end
always@(posedge clk_input_1cycle or negedge rst_n) begin
	if(!rst_n) in_mode_reg <= 0;
	else begin
		if(n_state == INPUT && c_state == IDLE) in_mode_reg <= in_mode;
		else in_mode_reg <= in_mode_reg;
	end
end
genvar j;
generate
	for(j=0; j<9; j=j+1) begin
		always@(posedge clk_mode2 or negedge rst_n) begin
			if(!rst_n) addsub_data[j] <= 0;
			else begin
				if(c_state == MODE_1) begin
					if(in_mode_reg[1]) begin
						if($signed(data[j])>$signed(mid_point)) begin  
							addsub_data[j] <= $signed(data[j])-minmax_diff;
						end
						else if($signed(data[j])<$signed(mid_point)) begin
							addsub_data[j] <= $signed(data[j])+minmax_diff;
						end
						else addsub_data[j] <= $signed(data[j]);
					end
					else addsub_data[j] <= $signed(data[j]); 
				end
				else addsub_data[j] <= 0;
			end		
		end
	end
endgenerate
always@(posedge clk_mode2 or negedge rst_n) begin
	if(!rst_n) SMA_data[0] <= 0;
	else begin
		if(c_state == MODE_2) begin
			if(in_mode_reg[2]) SMA_data[0] <= ($signed(addsub_data[8])+$signed(addsub_data[0])+$signed(addsub_data[1]))/3;
			else SMA_data[0] <= addsub_data[0];
		end
		else SMA_data[0] <= 0;
	end
end
genvar k;
generate
	for(k=1; k<8; k=k+1) begin
		always@(posedge clk_mode2 or negedge rst_n) begin
			if(!rst_n) SMA_data[k] <= 0;
			else begin
				if(c_state == MODE_2) begin
					if(in_mode_reg[2]) SMA_data[k] <= ($signed(addsub_data[k-1])+$signed(addsub_data[k])+$signed(addsub_data[k+1]))/3;
					else SMA_data[k] <= addsub_data[k];
				end
				else SMA_data[k] <= 0;
			end
		end
	end
endgenerate
always@(posedge clk_mode2 or negedge rst_n) begin
	if(!rst_n) SMA_data[8] <= 0;
	else begin
		if(c_state == MODE_2) 
			if(in_mode_reg[2]) SMA_data[8] <= ($signed(addsub_data[7])+$signed(addsub_data[8])+$signed(addsub_data[0]))/3;
			else SMA_data[8] <= addsub_data[8];
		else SMA_data[8] <= 0;
	end
end
genvar i;
generate
	for (i=0;i<8;i=i+1) begin
		always@(posedge clk_input or negedge rst_n) begin
			if(!rst_n) data[i] <= 0;
			else begin
				if(c_state == INPUT) data[i] <= data[i+1];
				else data[i] <= 0;
			end
		end
	end
endgenerate
always@(posedge clk_input or negedge rst_n) begin
	if(!rst_n) data[8] <= 0;
	else begin
		if(c_state == INPUT) data[8] <= $signed(trans_data);
		else data[8] <= 0;
	end
end
always@(posedge clk_out or negedge rst_n) begin
	if(!rst_n) output_data[0] <= 0;
	else begin
		if(c_state == OUT) begin
			if(out_counter == 0) output_data[0] <= sorted_data[4];
			else output_data[0] <= output_data[0];
		end
		else output_data[0] <= 0;
	end
end
always@(posedge clk_out or negedge rst_n) begin
	if(!rst_n) output_data[1] <= 0;
	else begin
		if(c_state == OUT) begin
			if(out_counter == 0) output_data[1] <= sorted_data[8];
			else output_data[1] <= output_data[1];
		end
		else output_data[1] <= 0;
	end
end
sort9 SORT1 (SMA_data[0], SMA_data[1], SMA_data[2], SMA_data[3], SMA_data[4], SMA_data[5], SMA_data[6], SMA_data[7], SMA_data[8], 
		   sorted_data[0], sorted_data[1], sorted_data[2], sorted_data[3], sorted_data[4], sorted_data[5], sorted_data[6], sorted_data[7], sorted_data[8]);
//---------------------------------------------------------------------
//   	Design Block
//---------------------------------------------------------------------
always@(posedge clk_input or negedge rst_n) begin
	if(!rst_n) flag_minmax <= 0;
	else begin
		if(in_valid) flag_minmax <= 1;
		else flag_minmax <= 0;
	end
end
always@(posedge clk_input_mode2 or negedge rst_n) begin
    if(!rst_n) input_counter <= 0;
	else begin
	    if(c_state == INPUT || c_state == MODE_1) input_counter <=  1;
		else input_counter <= 0;
	end
end
always@(posedge clk_out or negedge rst_n) begin
    if(!rst_n) out_counter <= 0;
	else begin
	    if(c_state == OUT) out_counter <= out_counter + 1;
		else out_counter <= 0;
	end
end
//----------------------MIN---------------------------------------
always@(posedge clk_minmax or negedge rst_n) begin
	if(!rst_n) min <= 0;
	else begin
		case(c_state)
			IDLE: min <= 0;
			INPUT, MODE_1: begin
				case(in_mode_reg[0]) 
					1'b0: begin
						if(input_counter == 0) min <= $signed(in_data_reg);
						else begin
							if($signed(in_data_reg)<$signed(min)) min <= $signed(in_data_reg);
							else min <= min;
						end
					end
					1'b1: begin
						if(input_counter == 0) min <= $signed(trans_data);
						else begin
							if($signed(trans_data)<$signed(min)) min <= $signed(trans_data);
							else min <= min;
						end
					end
				endcase
			end
			default: min <= 0;
		endcase
	end
end
//-----------------------MAX-------------------------------------
always@(posedge clk_minmax or negedge rst_n) begin
	if(!rst_n) max <= 0;
	else begin
		case(c_state)
		    IDLE: begin
		        max <= 0;
		    end
		    INPUT, MODE_1: begin
		        case(in_mode_reg[0])
		            1'b0: begin
						if(input_counter == 0) max <= $signed(in_data_reg);
						else begin
							if($signed(in_data_reg) > $signed(max)) max <= $signed(in_data_reg);
							else max <= max;
						end
				    end
		            1'b1: begin
						if(input_counter == 0) max <= $signed(trans_data);
						else begin
							if($signed(trans_data) > $signed(max)) max <= $signed(trans_data);
							else max <= max;
						end
		            end
			    endcase
		    end
			default: max <= 0;
		endcase
	end
end
//-----------------------MIN_MAX_DIFFERENCE-------------------------------------
always@(*) begin
	if(c_state == MODE_1) minmax_diff = ($signed(max)-$signed(min))>>>1; //for in_mode[0] = 0;
	else minmax_diff = 0;
end
always@(*) begin
	if(c_state == MODE_1) mid_point = ($signed(max)+$signed(min))/2; //for in_mode[0] = 0;
	else mid_point = 0;
end


//---------------------------------------------------------------------
//   	OUTPUT Block
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
	else begin
		if(c_state == OUT) out_valid <= 1;
		else out_valid <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_data <= 0;
	else begin
		if(c_state == OUT) begin
			case(out_counter) 
				2'd0: out_data <= $signed(sorted_data[0]);
				2'd1: out_data <= $signed(output_data[0]);
				2'd2: out_data <= $signed(output_data[1]);
				default: out_data <= 0;
			endcase
		end
		else out_data <= 0;
	end
end
endmodule

module sort3(in0,in1,in2,out0,out1,out2);
input signed [9:0] in0, in1, in2;
output signed [9:0] out0, out1, out2;
wire signed [9:0] stage1[1:0];
wire signed [9:0] stage2;

assign stage1[0] = (in0>in1)? in0 : in1; 
assign stage1[1] = (in0>in1)? in1 : in0;


assign stage2 = (stage1[1] > in2)? stage1[1] : in2;
assign out2   = (stage1[1] > in2)? in2       : stage1[1];

assign out0 = (stage1[0]>stage2)? stage1[0] : stage2;
assign out1 = (stage1[0]>stage2)? stage2    : stage1[0];
endmodule

module sort9(
in0, in1, in2, in3, in4, in5, in6, in7, in8,
out0, out1, out2, out3, out4, out5, out6, out7, out8);
input  signed [9:0] in0, in1, in2, in3, in4, in5, in6, in7, in8;
output signed [9:0] out0 ,out1, out2, out3, out4, out5, out6, out7, out8;
wire signed [9:0] stage1[0:8];
wire signed [9:0] middle[2:0];
sort3 SORT1(.in0(in0), .in1(in1), .in2(in2), .out0(stage1[0]), .out1(stage1[1]), .out2(stage1[2]));
sort3 SORT2(.in0(in3), .in1(in4), .in2(in5), .out0(stage1[3]), .out1(stage1[4]), .out2(stage1[5]));
sort3 SORT3(.in0(in6), .in1(in7), .in2(in8), .out0(stage1[6]), .out1(stage1[7]), .out2(stage1[8]));

sort3 SORT4(.in0(stage1[0]), .in1(stage1[3]), .in2(stage1[6]), .out0(out0), .out1(out3), .out2(middle[2]));
sort3 SORT5(.in0(stage1[1]), .in1(stage1[4]), .in2(stage1[7]), .out0(out1), .out1(middle[1]), .out2(out7));
sort3 SORT6(.in0(stage1[2]), .in1(stage1[5]), .in2(stage1[8]), .out0(middle[0]), .out1(out5), .out2(out8));

sort3 SORT7(.in0(middle[0]), .in1(middle[1]), .in2(middle[2]), .out0(out6), .out1(out4), .out2(out2));

endmodule