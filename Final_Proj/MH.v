//synopsys translate_off
`include "DW_minmax.v"
`include "DW_addsub_dx.v"
//synopsys translate_on
module MH(
	// input signals
	clk,
	clk2,
	rst_n,
	in_valid,
	pic_data,
	se_data,
	op_valid,
	op,
	// output signals
	out_valid,
	out_data
	);
//======================================
//          I/O PORTS
//======================================
input         		clk;
input				clk2;
input         		rst_n;
input         		in_valid;
input [31:0]   		pic_data;
input [7:0]			se_data;
input				op_valid;
input [2:0]			op;

output reg    		out_valid;
output reg [31:0]	out_data;

//======================================
//      PARAMETERS & VARIABLES
//======================================
parameter IDLE            = 4'd0;
parameter INPUT           = 4'd1;
parameter EROS            = 4'd2;
parameter DILA            = 4'd3;
parameter HIST_A          = 4'd4;
parameter HIST_B		  = 4'd5;
parameter OPENING_A		  = 4'd6;
parameter OPENING_B		  = 4'd7;
parameter OPENING_C		  = 4'd8;
parameter CLOSING_A       = 4'd9;
parameter CLOSING_B		  = 4'd10;
parameter CLOSING_C		  = 4'd11;
parameter OUT			  = 4'd12;
//======================================
//      	REGS & WIRES
//======================================
reg [3:0]  	c_state;
reg [3:0]  	n_state;

reg [2:0]  	operation;
reg [127:0] se_data_reg;
reg reg_in_valid;
reg addsub_mode;

reg [7:0]  cnt;
reg [7:0]  compute_cnt;

reg [7:0] kernel1 [3:0];
reg [7:0] kernel2 [3:0];
reg [7:0] kernel3 [3:0];
reg [7:0] kernel4 [3:0];

reg  [31:0] line_buf [25:0];
wire [7:0]  line_operand[11:0];

wire [7:0] sum0 [15:0];
wire [7:0] sum1 [15:0];
wire [7:0] sum2 [15:0];
wire [7:0] sum3 [15:0];

wire [15:0] co1_0;
wire [15:0] co1_1;
wire [15:0] co1_2;
wire [15:0] co1_3;

wire [15:0] co2_0;
wire [15:0] co2_1;
wire [15:0] co2_2;
wire [15:0] co2_3;

wire [127:0] ED_group [3:0];
wire [7:0]   minmax[3:0];
wire [3:0]   index [3:0];

reg  [31:0] mem_data;
reg  [7:0]  mem_addr;
wire [31:0] mem_Q;
reg	 mem_WEN;

reg  [255:0] cdf_count [3:0];
reg  [10:0]  cdf_table [255:0];
reg  [10:0]  hist_min;
wire [7:0]   temp_min;
wire [1:0]   hist_index;
reg  [18:0]  temp_dividend[3:0];
reg  [10:0]  temp_divisor;
wire [7:0]   temp_ans[3:0];
//======================================
//      	FSM Block
//======================================
always@(posedge clk or negedge rst_n) begin
	if(~rst_n) c_state <= IDLE;
	else c_state <= n_state;
end
always@(*) begin
	case(c_state)
		IDLE: 	n_state = (in_valid)? 	INPUT : IDLE;
		INPUT:	begin
			if(!in_valid) begin
				case(operation)
					3'b010:  n_state = EROS;
					3'b011:  n_state = DILA;
					3'b000:  n_state = HIST_A;
					3'b110:  n_state = OPENING_A;
					3'b111:  n_state = CLOSING_A;
					default: n_state = c_state;
				endcase
			end
			else n_state = c_state;
		end
		EROS:   n_state = (cnt == 26)? OUT : EROS;
		DILA:   n_state = (cnt == 26)? OUT : DILA;
		HIST_A: n_state = HIST_B;
		HIST_B: n_state = OUT;
		OPENING_A: n_state = (compute_cnt == 255)?  OPENING_B : OPENING_A;
		OPENING_B: n_state = (cnt == 255)? 			OPENING_C : OPENING_B;
		OPENING_C: n_state = (cnt == 27)?  			IDLE 	  : OPENING_C;
		CLOSING_A: n_state = (compute_cnt == 255)?  CLOSING_B : CLOSING_A;
		CLOSING_B: n_state = (compute_cnt == 229)?  CLOSING_C : CLOSING_B;
		CLOSING_C: n_state = (cnt == 27)?  			IDLE 	  : CLOSING_C;
		OUT : n_state = (cnt == 255)? 				IDLE      : OUT;
		default: n_state = c_state;
	endcase
end
//======================================
//      	Counter Block
//======================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) cnt <= 0;
	else begin
		case(c_state) 
			INPUT: cnt <= cnt+1;
			EROS, DILA: begin
				if(cnt == 26) cnt <= 0;
				else cnt <= cnt+1;
			end
			OPENING_A, CLOSING_A: begin
				if(cnt == 24) cnt <= 0;
				else cnt <= cnt+1;
			end
			OPENING_B, OPENING_C, CLOSING_B, CLOSING_C: begin
				cnt <= cnt + 1;
			end
			OUT: begin
				if(operation == 3'b000) cnt <= cnt + 1;
				else cnt <= (mem_addr == 0)? 0 : cnt + 1;
			end
			default: cnt <= 0;
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) compute_cnt <= 0;
	else begin
		case(c_state) 
			INPUT: begin
				if(cnt>24) compute_cnt <= compute_cnt+1;
				else compute_cnt <= compute_cnt;
			end
			EROS, DILA, OPENING_A, CLOSING_A, OPENING_C, CLOSING_C: begin
				compute_cnt <= compute_cnt+1;
			end
			OPENING_B: begin
				if(cnt>27) compute_cnt <= compute_cnt+1;
				else compute_cnt <= compute_cnt;
			end
			CLOSING_B: begin
				if(cnt>27) compute_cnt <= compute_cnt+1;
				else if(compute_cnt != 0) compute_cnt <= compute_cnt+1;
				else compute_cnt <= compute_cnt;
			end
			IDLE: begin
				compute_cnt <= 0;
			end
			default: compute_cnt <= compute_cnt;
		endcase
	end
end
//======================================
//      	INPUT Block
//======================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) operation <= 1;
	else begin
		if(n_state == INPUT) operation <= (op_valid)? op : operation;
		else if(c_state == IDLE) operation <= 1;
		else operation <= operation;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) se_data_reg <= 0;
	else begin
		if(n_state == INPUT) begin
			if(cnt < 15) se_data_reg <= {se_data_reg[119:0], se_data};
			else se_data_reg <= se_data_reg;
		end
		else se_data_reg <= se_data_reg;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_in_valid <= 0;
	else reg_in_valid <= in_valid;
end
//======================================
//      	MEM Block
//======================================
//------------pic addr--------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) mem_addr <= 0;
	else begin
		if(c_state == INPUT) begin
			case(operation)
				3'b010, 3'b011: begin
					if(cnt>25) mem_addr <= mem_addr + 1;
					else mem_addr <= 0;
				end
				3'b110, 3'b111: begin
					if(cnt>25) mem_addr <= mem_addr + 1;
					else mem_addr <= 0;
				end				
				default: mem_addr <= mem_addr + 1;
			endcase
		end
		else if(c_state == IDLE) mem_addr <= 0;
		else mem_addr <= mem_addr + 1;
	end
end
//------------pic data--------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) mem_data <= 0;
	else begin
		case(c_state) 
			INPUT: begin
				case(operation)
					3'b010, 3'b011, 3'b110, 3'b111: begin
						if(cnt>24) mem_data <= {minmax[0], minmax[1], minmax[2], minmax[3]};
						else mem_data <= (in_valid)? pic_data : 0;
					end
					3'b000: begin
						if(in_valid) mem_data <= pic_data;
						else mem_data <= (in_valid)? pic_data : 0;
					end
					default: mem_data <= (in_valid)? pic_data : 0;
				endcase
			end
			EROS, DILA, OPENING_A, CLOSING_A: begin
				mem_data <= {minmax[0], minmax[1], minmax[2], minmax[3]};
			end
			IDLE: begin
				if(in_valid) mem_data <= pic_data;
				else mem_data <= 0;
			end
			default: mem_data <= 0;
		endcase
	end
end
//------------pic WEN--------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) mem_WEN <= 1;
	else begin
		case(c_state) 
			INPUT: begin
				if(operation == 3'b010 && cnt > 24) mem_WEN <= 0;
				else if(operation == 3'b011 && cnt > 24) mem_WEN <= 0;
				else if(operation == 3'b000 && in_valid) mem_WEN <= 0;
				else if(operation == 3'b110) mem_WEN <= 0;
				else if(operation == 3'b111) mem_WEN <= 0;
				else mem_WEN <= (in_valid)? 0 : 1;
			end
			EROS, DILA: begin
				if(cnt<25) mem_WEN <= 0;
				else mem_WEN <= 1;
			end
			IDLE: begin
				if(in_valid) mem_WEN <= 0;
				else mem_WEN <= 1;
			end
			OPENING_A, CLOSING_A: mem_WEN <= 0;
			default: mem_WEN <= 1;
		endcase
	end
end
sram_256_32_4 PIC1 (.Q(mem_Q), .CLK(clk), .CEN(1'b0), .WEN(mem_WEN), .A(mem_addr), .D(mem_data), .OEN(1'b0));
//======================================
//       	line buffer Block
//======================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) line_buf[0] <= 0;
	else begin
		if(n_state == INPUT) line_buf[0] <= pic_data;
		else if(n_state == EROS) line_buf[0] <= 0;
		else if(n_state == DILA) line_buf[0] <= 0;
		else if(n_state == OPENING_A) line_buf[0] <= 0;
		else if(n_state == OPENING_B) line_buf[0] <= mem_Q;
		else if(n_state == OPENING_C) line_buf[0] <= 0;
		else if(n_state == CLOSING_A) line_buf[0] <= 0;
		else if(c_state == CLOSING_B) line_buf[0] <= mem_Q;
		else if(n_state == CLOSING_C) line_buf[0] <= 0;
		else line_buf[0] <= line_buf[0];
	end
end
genvar k;
generate 
	for (k = 1 ; k < 26; k = k + 1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) line_buf[k] <= 0;
			else begin
				if(c_state == INPUT) line_buf[k] <= line_buf[k-1];
				else if(c_state == EROS) line_buf[k] <= line_buf[k-1];
				else if(c_state == DILA) line_buf[k] <= line_buf[k-1];
				else if(n_state == OPENING_A) line_buf[k] <= line_buf[k-1];
				else if(n_state == OPENING_B) line_buf[k] <= line_buf[k-1];
				else if(n_state == OPENING_C) line_buf[k] <= line_buf[k-1];
				else if(n_state == CLOSING_A) line_buf[k] <= line_buf[k-1];
				else if(n_state == CLOSING_B) line_buf[k] <= line_buf[k-1];
				else if(n_state == CLOSING_C) line_buf[k] <= line_buf[k-1];
			end
		end
	end
endgenerate
//======================================
//      	Kernel Block
//======================================
genvar i;
generate 
	for (i = 0 ; i < 4; i = i + 1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) begin
				kernel1[i] <= 0;
				kernel2[i] <= 0;
				kernel3[i] <= 0;
				kernel4[i] <= 0;
			end
			else begin
				if(c_state == INPUT) begin
					if(operation == 3'b010 || operation == 3'b110) begin
						kernel4[i] <= se_data_reg[8*(4-i)-1    : 8*(4-i)-8];
						kernel3[i] <= se_data_reg[8*(4-i)+32-1 : 8*(4-i)+32-8];
						kernel2[i] <= se_data_reg[8*(4-i)+64-1 : 8*(4-i)+64-8];
						kernel1[i] <= se_data_reg[8*(4-i)+96-1 : 8*(4-i)+96-8];
					end
					else if(operation == 3'b011 || operation == 3'b111) begin
						kernel4[i] <= se_data_reg[8*(i+1)+96-1 : 8*(i+1)-8+96];
						kernel3[i] <= se_data_reg[8*(i+1)+64-1 : 8*(i+1)-8+64];
						kernel2[i] <= se_data_reg[8*(i+1)+32-1 : 8*(i+1)-8+32];
						kernel1[i] <= se_data_reg[8*(i+1)-1    : 8*(i+1)-8];
					end
					else begin
						kernel4[i] <= kernel4[i];
						kernel3[i] <= kernel3[i];
						kernel2[i] <= kernel2[i];
						kernel1[i] <= kernel1[i];
					end
				end
				else if(c_state == OPENING_A) begin
					if(cnt != 24) begin
						kernel4[i] <= se_data_reg[8*(4-i)-1    : 8*(4-i)-8];
						kernel3[i] <= se_data_reg[8*(4-i)+32-1 : 8*(4-i)+32-8];
						kernel2[i] <= se_data_reg[8*(4-i)+64-1 : 8*(4-i)+64-8];
						kernel1[i] <= se_data_reg[8*(4-i)+96-1 : 8*(4-i)+96-8];
					end
					else begin
						kernel4[i] <= se_data_reg[8*(i+1)+96-1 : 8*(i+1)-8+96];
						kernel3[i] <= se_data_reg[8*(i+1)+64-1 : 8*(i+1)-8+64];
						kernel2[i] <= se_data_reg[8*(i+1)+32-1 : 8*(i+1)-8+32];
						kernel1[i] <= se_data_reg[8*(i+1)-1    : 8*(i+1)-8];
					end
				end
				else if(c_state == OPENING_B || c_state == OPENING_C) begin
					kernel4[i] <= se_data_reg[8*(i+1)+96-1 : 8*(i+1)-8+96];
					kernel3[i] <= se_data_reg[8*(i+1)+64-1 : 8*(i+1)-8+64];
					kernel2[i] <= se_data_reg[8*(i+1)+32-1 : 8*(i+1)-8+32];
					kernel1[i] <= se_data_reg[8*(i+1)-1    : 8*(i+1)-8];
				end
				else if(c_state == CLOSING_A) begin
					if(cnt != 24) begin
						kernel4[i] <= se_data_reg[8*(i+1)+96-1 : 8*(i+1)-8+96];
						kernel3[i] <= se_data_reg[8*(i+1)+64-1 : 8*(i+1)-8+64];
						kernel2[i] <= se_data_reg[8*(i+1)+32-1 : 8*(i+1)-8+32];
						kernel1[i] <= se_data_reg[8*(i+1)-1    : 8*(i+1)-8];
					end
					else begin
						kernel4[i] <= se_data_reg[8*(4-i)-1    : 8*(4-i)-8];
						kernel3[i] <= se_data_reg[8*(4-i)+32-1 : 8*(4-i)+32-8];
						kernel2[i] <= se_data_reg[8*(4-i)+64-1 : 8*(4-i)+64-8];
						kernel1[i] <= se_data_reg[8*(4-i)+96-1 : 8*(4-i)+96-8];
					end
				end
				else if(c_state == CLOSING_B || c_state == CLOSING_C) begin
					kernel4[i] <= se_data_reg[8*(4-i)-1    : 8*(4-i)-8];
					kernel3[i] <= se_data_reg[8*(4-i)+32-1 : 8*(4-i)+32-8];
					kernel2[i] <= se_data_reg[8*(4-i)+64-1 : 8*(4-i)+64-8];
					kernel1[i] <= se_data_reg[8*(4-i)+96-1 : 8*(4-i)+96-8];
				end
			end
			
		end
	end
endgenerate
//======================================
//      ADD SUB Block(EROS, DILA)
//======================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) addsub_mode <= 0;
	else begin
		if(operation == 3'b010) addsub_mode <= 1;
		else if(operation == 3'b011) addsub_mode <= 0;
		else if(operation == 3'b000) addsub_mode <= 1;
		else if(operation == 3'b110) begin
			if(n_state == OPENING_B) addsub_mode <= 0;
			else if(n_state == OPENING_C) addsub_mode <= 0;
			else addsub_mode <= 1;
		end
		else if(operation == 3'b111) begin
			if(n_state == CLOSING_B) addsub_mode <= 1;
			else if(n_state == CLOSING_C) addsub_mode <= 1;
			else addsub_mode <= 0;
		end
		else addsub_mode <= addsub_mode;
	end
end

assign line_operand[0]  = (compute_cnt % 8 == 7)? 0 : line_buf[24][7:0];
assign line_operand[1]  = (compute_cnt % 8 == 7)? 0 : line_buf[24][15:8];
assign line_operand[2]  = (compute_cnt % 8 == 7)? 0 : line_buf[24][23:16];
assign line_operand[3]  = (compute_cnt % 8 == 7)? 0 : line_buf[16][7:0];
assign line_operand[4]  = (compute_cnt % 8 == 7)? 0 : line_buf[16][15:8];
assign line_operand[5]  = (compute_cnt % 8 == 7)? 0 : line_buf[16][23:16];
assign line_operand[6]  = (compute_cnt % 8 == 7)? 0 : line_buf[8][7:0];
assign line_operand[7]  = (compute_cnt % 8 == 7)? 0 : line_buf[8][15:8];
assign line_operand[8]  = (compute_cnt % 8 == 7)? 0 : line_buf[8][23:16];
assign line_operand[9]  = (compute_cnt % 8 == 7)? 0 : line_buf[0][7:0];
assign line_operand[10] = (compute_cnt % 8 == 7)? 0 : line_buf[0][15:8];
assign line_operand[11] = (compute_cnt % 8 == 7)? 0 : line_buf[0][23:16];

//1st PE
DW_addsub_dx #(8,2) PE1_0  (.a(line_buf[25][31:24]), .b(kernel1[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[0] ), .co1(co1_0[0] ), .co2(co2_0[0] ));
DW_addsub_dx #(8,2) PE1_1  (.a(line_operand[0]),     .b(kernel1[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[1] ), .co1(co1_0[1] ), .co2(co2_0[1] ));
DW_addsub_dx #(8,2) PE1_2  (.a(line_operand[1]),     .b(kernel1[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[2] ), .co1(co1_0[2] ), .co2(co2_0[2] ));
DW_addsub_dx #(8,2) PE1_3  (.a(line_operand[2]),     .b(kernel1[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[3] ), .co1(co1_0[3] ), .co2(co2_0[3] ));
DW_addsub_dx #(8,2) PE1_4  (.a(line_buf[17][31:24]), .b(kernel2[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[4] ), .co1(co1_0[4] ), .co2(co2_0[4] ));
DW_addsub_dx #(8,2) PE1_5  (.a(line_operand[3]),     .b(kernel2[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[5] ), .co1(co1_0[5] ), .co2(co2_0[5] ));
DW_addsub_dx #(8,2) PE1_6  (.a(line_operand[4]),     .b(kernel2[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[6] ), .co1(co1_0[6] ), .co2(co2_0[6] ));
DW_addsub_dx #(8,2) PE1_7  (.a(line_operand[5]),     .b(kernel2[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[7] ), .co1(co1_0[7] ), .co2(co2_0[7] ));
DW_addsub_dx #(8,2) PE1_8  (.a(line_buf[9][31:24]),  .b(kernel3[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[8] ), .co1(co1_0[8] ), .co2(co2_0[8] ));
DW_addsub_dx #(8,2) PE1_9  (.a(line_operand[6]),     .b(kernel3[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[9] ), .co1(co1_0[9] ), .co2(co2_0[9] ));
DW_addsub_dx #(8,2) PE1_10 (.a(line_operand[7]),     .b(kernel3[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[10]), .co1(co1_0[10]), .co2(co2_0[10]));
DW_addsub_dx #(8,2) PE1_11 (.a(line_operand[8]),     .b(kernel3[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[11]), .co1(co1_0[11]), .co2(co2_0[11]));
DW_addsub_dx #(8,2) PE1_12 (.a(line_buf[1][31:24]),  .b(kernel4[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[12]), .co1(co1_0[12]), .co2(co2_0[12]));
DW_addsub_dx #(8,2) PE1_13 (.a(line_operand[9]),     .b(kernel4[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[13]), .co1(co1_0[13]), .co2(co2_0[13]));
DW_addsub_dx #(8,2) PE1_14 (.a(line_operand[10]),    .b(kernel4[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[14]), .co1(co1_0[14]), .co2(co2_0[14]));
DW_addsub_dx #(8,2) PE1_15 (.a(line_operand[11]),    .b(kernel4[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum0[15]), .co1(co1_0[15]), .co2(co2_0[15]));
// 2nd PE                                            
DW_addsub_dx #(8,2) PE2_0  (.a(line_buf[25][23:16]), .b(kernel1[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[0] ), .co1(co1_1[0] ), .co2(co2_1[0] ));
DW_addsub_dx #(8,2) PE2_1  (.a(line_buf[25][31:24]), .b(kernel1[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[1] ), .co1(co1_1[1] ), .co2(co2_1[1] ));
DW_addsub_dx #(8,2) PE2_2  (.a(line_operand[0]),     .b(kernel1[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[2] ), .co1(co1_1[2] ), .co2(co2_1[2] ));
DW_addsub_dx #(8,2) PE2_3  (.a(line_operand[1]),     .b(kernel1[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[3] ), .co1(co1_1[3] ), .co2(co2_1[3] ));
DW_addsub_dx #(8,2) PE2_4  (.a(line_buf[17][23:16]), .b(kernel2[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[4] ), .co1(co1_1[4] ), .co2(co2_1[4] ));
DW_addsub_dx #(8,2) PE2_5  (.a(line_buf[17][31:24]), .b(kernel2[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[5] ), .co1(co1_1[5] ), .co2(co2_1[5] ));
DW_addsub_dx #(8,2) PE2_6  (.a(line_operand[3]),     .b(kernel2[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[6] ), .co1(co1_1[6] ), .co2(co2_1[6] ));
DW_addsub_dx #(8,2) PE2_7  (.a(line_operand[4]),     .b(kernel2[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[7] ), .co1(co1_1[7] ), .co2(co2_1[7] ));
DW_addsub_dx #(8,2) PE2_8  (.a(line_buf[9][23:16]),  .b(kernel3[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[8] ), .co1(co1_1[8] ), .co2(co2_1[8] ));
DW_addsub_dx #(8,2) PE2_9  (.a(line_buf[9][31:24]),  .b(kernel3[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[9] ), .co1(co1_1[9] ), .co2(co2_1[9] ));
DW_addsub_dx #(8,2) PE2_10 (.a(line_operand[6]),     .b(kernel3[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[10]), .co1(co1_1[10]), .co2(co2_1[10]));
DW_addsub_dx #(8,2) PE2_11 (.a(line_operand[7]),     .b(kernel3[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[11]), .co1(co1_1[11]), .co2(co2_1[11]));
DW_addsub_dx #(8,2) PE2_12 (.a(line_buf[1][23:16]),  .b(kernel4[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[12]), .co1(co1_1[12]), .co2(co2_1[12]));
DW_addsub_dx #(8,2) PE2_13 (.a(line_buf[1][31:24]),  .b(kernel4[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[13]), .co1(co1_1[13]), .co2(co2_1[13]));
DW_addsub_dx #(8,2) PE2_14 (.a(line_operand[9]),     .b(kernel4[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[14]), .co1(co1_1[14]), .co2(co2_1[14]));
DW_addsub_dx #(8,2) PE2_15 (.a(line_operand[10]),    .b(kernel4[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum1[15]), .co1(co1_1[15]), .co2(co2_1[15]));
// 3rd PE                                            
DW_addsub_dx #(8,2) PE3_0  (.a(line_buf[25][15:8]),  .b(kernel1[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[0] ), .co1(co1_2[0] ), .co2(co2_2[0] ));
DW_addsub_dx #(8,2) PE3_1  (.a(line_buf[25][23:16]), .b(kernel1[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[1] ), .co1(co1_2[1] ), .co2(co2_2[1] ));
DW_addsub_dx #(8,2) PE3_2  (.a(line_buf[25][31:24]), .b(kernel1[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[2] ), .co1(co1_2[2] ), .co2(co2_2[2] ));
DW_addsub_dx #(8,2) PE3_3  (.a(line_operand[0]),     .b(kernel1[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[3] ), .co1(co1_2[3] ), .co2(co2_2[3] ));
DW_addsub_dx #(8,2) PE3_4  (.a(line_buf[17][15:8]),  .b(kernel2[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[4] ), .co1(co1_2[4] ), .co2(co2_2[4] ));
DW_addsub_dx #(8,2) PE3_5  (.a(line_buf[17][23:16]), .b(kernel2[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[5] ), .co1(co1_2[5] ), .co2(co2_2[5] ));
DW_addsub_dx #(8,2) PE3_6  (.a(line_buf[17][31:24]), .b(kernel2[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[6] ), .co1(co1_2[6] ), .co2(co2_2[6] ));
DW_addsub_dx #(8,2) PE3_7  (.a(line_operand[3]),     .b(kernel2[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[7] ), .co1(co1_2[7] ), .co2(co2_2[7] ));
DW_addsub_dx #(8,2) PE3_8  (.a(line_buf[9][15:8]),   .b(kernel3[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[8] ), .co1(co1_2[8] ), .co2(co2_2[8] ));
DW_addsub_dx #(8,2) PE3_9  (.a(line_buf[9][23:16]),  .b(kernel3[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[9] ), .co1(co1_2[9] ), .co2(co2_2[9] ));
DW_addsub_dx #(8,2) PE3_10 (.a(line_buf[9][31:24]),  .b(kernel3[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[10]), .co1(co1_2[10]), .co2(co2_2[10]));
DW_addsub_dx #(8,2) PE3_11 (.a(line_operand[6]),     .b(kernel3[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[11]), .co1(co1_2[11]), .co2(co2_2[11]));
DW_addsub_dx #(8,2) PE3_12 (.a(line_buf[1][15:8]),   .b(kernel4[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[12]), .co1(co1_2[12]), .co2(co2_2[12]));
DW_addsub_dx #(8,2) PE3_13 (.a(line_buf[1][23:16]),  .b(kernel4[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[13]), .co1(co1_2[13]), .co2(co2_2[13]));
DW_addsub_dx #(8,2) PE3_14 (.a(line_buf[1][31:24]),  .b(kernel4[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[14]), .co1(co1_2[14]), .co2(co2_2[14]));
DW_addsub_dx #(8,2) PE3_15 (.a(line_operand[9]),     .b(kernel4[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum2[15]), .co1(co1_2[15]), .co2(co2_2[15]));
// 1st PE
                                        
DW_addsub_dx #(8,2) PE4_0  (.a(line_buf[25][7:0]),   .b(kernel1[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[0] ), .co1(co1_3[0] ), .co2(co2_3[0] ));
DW_addsub_dx #(8,2) PE4_1  (.a(line_buf[25][15:8]),  .b(kernel1[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[1] ), .co1(co1_3[1] ), .co2(co2_3[1] ));
DW_addsub_dx #(8,2) PE4_2  (.a(line_buf[25][23:16]), .b(kernel1[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[2] ), .co1(co1_3[2] ), .co2(co2_3[2] ));
DW_addsub_dx #(8,2) PE4_3  (.a(line_buf[25][31:24]), .b(kernel1[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[3] ), .co1(co1_3[3] ), .co2(co2_3[3] ));
DW_addsub_dx #(8,2) PE4_4  (.a(line_buf[17][7:0]),   .b(kernel2[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[4] ), .co1(co1_3[4] ), .co2(co2_3[4] ));
DW_addsub_dx #(8,2) PE4_5  (.a(line_buf[17][15:8]),  .b(kernel2[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[5] ), .co1(co1_3[5] ), .co2(co2_3[5] ));
DW_addsub_dx #(8,2) PE4_6  (.a(line_buf[17][23:16]), .b(kernel2[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[6] ), .co1(co1_3[6] ), .co2(co2_3[6] ));
DW_addsub_dx #(8,2) PE4_7  (.a(line_buf[17][31:24]), .b(kernel2[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[7] ), .co1(co1_3[7] ), .co2(co2_3[7] ));
DW_addsub_dx #(8,2) PE4_8  (.a(line_buf[9][7:0]),    .b(kernel3[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[8] ), .co1(co1_3[8] ), .co2(co2_3[8] ));
DW_addsub_dx #(8,2) PE4_9  (.a(line_buf[9][15:8]),   .b(kernel3[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[9] ), .co1(co1_3[9] ), .co2(co2_3[9] ));
DW_addsub_dx #(8,2) PE4_10 (.a(line_buf[9][23:16]),  .b(kernel3[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[10]), .co1(co1_3[10]), .co2(co2_3[10]));
DW_addsub_dx #(8,2) PE4_11 (.a(line_buf[9][31:24]),  .b(kernel3[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[11]), .co1(co1_3[11]), .co2(co2_3[11]));
DW_addsub_dx #(8,2) PE4_12 (.a(line_buf[1][7:0]),    .b(kernel4[0]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[12]), .co1(co1_3[12]), .co2(co2_3[12]));
DW_addsub_dx #(8,2) PE4_13 (.a(line_buf[1][15:8]),   .b(kernel4[1]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[13]), .co1(co1_3[13]), .co2(co2_3[13]));
DW_addsub_dx #(8,2) PE4_14 (.a(line_buf[1][23:16]),  .b(kernel4[2]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[14]), .co1(co1_3[14]), .co2(co2_3[14]));
DW_addsub_dx #(8,2) PE4_15 (.a(line_buf[1][31:24]),  .b(kernel4[3]), .ci1(1'b0), .ci2(1'b0), .addsub(addsub_mode), .tc(1'b0), .sat(1'b1), .avg(1'b0), .dplx(1'b0), .sum(sum3[15]), .co1(co1_3[15]), .co2(co2_3[15]));

//======================================
//      	CDF Block(HIST)
//======================================
genvar a, b;
generate
	for(a=0;a<4;a=a+1) begin
		for(b=0;b<256;b=b+1) begin
			always@(*) begin
				if(pic_data[a*8+7:a*8] <= b) cdf_count[a][b] = 1;
				else cdf_count[a][b] = 0;
			end
		end
	end
endgenerate
genvar j;
generate
	for(j=0; j<256; j=j+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) cdf_table[j] <= 0;
			else begin
				if(n_state == INPUT) begin
					cdf_table[j] <= cdf_table[j] + cdf_count[3][j] + cdf_count[2][j] + cdf_count[1][j] + cdf_count[0][j];
				end
				else if(c_state == IDLE) cdf_table[j] <= 0;
				else cdf_table[j] <= cdf_table[j];
			end		
		end	
	end
endgenerate
DW_minmax #(8, 4) hist_minmax (.a(line_buf[0]), .tc(1'b0), .min_max(1'b0), .value(temp_min), .index(hist_index));
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) hist_min <= 0;
	else begin
		if(c_state == IDLE) hist_min <= 255;
		else if(c_state == INPUT) begin
			if(reg_in_valid) hist_min <= (hist_min > temp_min)? temp_min : hist_min;
			else hist_min <= hist_min;
		end
		else if(c_state == HIST_A) begin
			hist_min <= cdf_table[hist_min];
		end
		else hist_min <= hist_min;
	end
end
//------------Hist dividend--------------------------------
genvar u;
generate
	for(u=0; u<4; u=u+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) temp_dividend[u] <= 0;
			else begin
				if(c_state == HIST_B || c_state == OUT) begin
					temp_dividend[u] <= ((cdf_table[mem_Q[8*(u+1)-1: 8*u]]-hist_min)<<8)-(cdf_table[mem_Q[8*(u+1)-1: 8*u]]-hist_min);
				end
			end
		end
	end
endgenerate
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) temp_divisor <= 1;
	else begin
		if(c_state == HIST_B || c_state == OUT) temp_divisor <= 1024-hist_min;
		else temp_divisor <= temp_divisor;
	end
end
generate
	for(u=0;u<4;u=u+1) begin
		assign temp_ans[u] = temp_dividend[u]/temp_divisor;
	end
endgenerate
//======================================
//      	MIN & Max Block
//======================================

assign ED_group[0] = {sum0[0],  sum0[1],  sum0[2],
				      sum0[3],  sum0[4],  sum0[5],
				      sum0[6],  sum0[7],  sum0[8],
				      sum0[9],  sum0[10], sum0[11],
				      sum0[12], sum0[13], sum0[14],
				      sum0[15]};
assign ED_group[1] = {sum1[0],  sum1[1],  sum1[2],
				      sum1[3],  sum1[4],  sum1[5],
				      sum1[6],  sum1[7],  sum1[8],
				      sum1[9],  sum1[10], sum1[11],
				      sum1[12], sum1[13], sum1[14],
				      sum1[15]};
assign ED_group[2] = {sum2[0],  sum2[1],  sum2[2],
				      sum2[3],  sum2[4],  sum2[5],
				      sum2[6],  sum2[7],  sum2[8],
				      sum2[9],  sum2[10], sum2[11],
				      sum2[12], sum2[13], sum2[14],
				      sum2[15]};
assign ED_group[3] = {sum3[0],  sum3[1],  sum3[2],
				      sum3[3],  sum3[4],  sum3[5],
				      sum3[6],  sum3[7],  sum3[8],
				      sum3[9],  sum3[10], sum3[11],
				      sum3[12], sum3[13], sum3[14],
				      sum3[15]};
	
DW_minmax #(8, 16) minmax0 (.a(ED_group[0]), .tc(1'b0), .min_max(!addsub_mode), .value(minmax[0]), .index(index[0]));
DW_minmax #(8, 16) minmax1 (.a(ED_group[1]), .tc(1'b0), .min_max(!addsub_mode), .value(minmax[1]), .index(index[1]));
DW_minmax #(8, 16) minmax2 (.a(ED_group[2]), .tc(1'b0), .min_max(!addsub_mode), .value(minmax[2]), .index(index[2]));
DW_minmax #(8, 16) minmax3 (.a(ED_group[3]), .tc(1'b0), .min_max(!addsub_mode), .value(minmax[3]), .index(index[3]));

//======================================
//      	OUTPUT Block
//======================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
	else begin
		case(c_state) 
			OPENING_C, CLOSING_C, OUT: out_valid <= 1;
			OPENING_B, CLOSING_B: begin
				if(compute_cnt == 0) out_valid <= (cnt == 28)? 1:0;
				else out_valid <= 1;
			end
			default: out_valid <= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_data <= 0;
	else begin
		case(c_state)
			OPENING_B, CLOSING_B: begin
				if(compute_cnt == 0) out_data <= (cnt == 28)? {minmax[0], minmax[1], minmax[2], minmax[3]} : 0;
				else out_data <= {minmax[0], minmax[1], minmax[2], minmax[3]};
			end
			OPENING_C, CLOSING_C: begin
				out_data <= {minmax[0], minmax[1], minmax[2], minmax[3]};
			end
			OUT: begin
				if(operation == 3'b010) out_data <= mem_Q;
				else if(operation == 3'b011) out_data <= mem_Q;
				else if(operation == 3'b000) out_data <= {temp_ans[3], temp_ans[2], temp_ans[1], temp_ans[0]};
				else out_data <= 0;
			end
			default: out_data <= 0;
		endcase
	end
end
endmodule