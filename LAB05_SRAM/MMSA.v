module MMSA(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    i_mat_idx,
    w_mat_idx,
	
// output signals
    out_valid,
    out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input        clk, rst_n, in_valid, in_valid2;
input [15:0] matrix;
input [1:0]  matrix_size;
input [3:0]  i_mat_idx, w_mat_idx;

output reg       	     out_valid;
output reg signed [39:0] out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter STATE_IDLE   = 2'b00;
parameter STATE_INPUT  = 2'b01;
parameter STATE_INDEX  = 2'b10;
parameter STATE_CALCU  = 2'b11;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg  [1:0]  c_state;
reg  [1:0]  n_state;
reg  [15:0] IM_WEN;
reg  [15:0] WM_WEN;
reg  [7:0]  IM_addr;
reg  [7:0]  WM_addr;
wire [15:0] IM_output [15:0];
wire [15:0] WM_output [15:0];

reg  [15:0] input_data;
reg  		reg_in_valid;
reg  [6:0]  counter_mod;
reg  [3:0]  WEN_mod;

reg  [12:0] input_counter;
reg  [13:0] counter;
reg  [5:0]  calcu_counter;
reg  [1:0]  size;
reg  [4:0]  output_counter;
reg [15:0] reg_weight [15:0];
reg [15:0] reg_input [15:0];
reg [15:0] flag_w;

reg [15:0] input_A   [15:0];
reg [15:0] delay_A1  ;
reg [15:0] delay_A2  [1:0];
reg [15:0] delay_A3  [2:0];
reg [15:0] delay_A4  [3:0];
reg [15:0] delay_A5  [4:0];
reg [15:0] delay_A6  [5:0];
reg [15:0] delay_A7  [6:0];
reg [15:0] delay_A8  [7:0];
reg [15:0] delay_A9  [8:0];
reg [15:0] delay_A10 [9:0];
reg [15:0] delay_A11 [10:0];
reg [15:0] delay_A12 [11:0];
reg [15:0] delay_A13 [12:0];
reg [15:0] delay_A14 [13:0];
reg [15:0] delay_A15 [14:0];

wire [39:0] c0_0, c0_1, c0_2, c0_3, c0_4, c0_5, c0_6, c0_7, c0_8, c0_9, c0_10, c0_11, c0_12, c0_13, c0_14, c0_15;
wire [39:0] c1_0, c1_1, c1_2, c1_3, c1_4, c1_5, c1_6, c1_7, c1_8, c1_9, c1_10, c1_11, c1_12, c1_13, c1_14, c1_15; 
wire [39:0] c2_0, c2_1, c2_2, c2_3, c2_4, c2_5, c2_6, c2_7, c2_8, c2_9, c2_10, c2_11, c2_12, c2_13, c2_14, c2_15; 
wire [39:0] c3_0, c3_1, c3_2, c3_3, c3_4, c3_5, c3_6, c3_7, c3_8, c3_9, c3_10, c3_11, c3_12, c3_13, c3_14, c3_15; 
wire [39:0] c4_0, c4_1, c4_2, c4_3, c4_4, c4_5, c4_6, c4_7, c4_8, c4_9, c4_10, c4_11, c4_12, c4_13, c4_14, c4_15; 
wire [39:0] c5_0, c5_1, c5_2, c5_3, c5_4, c5_5, c5_6, c5_7, c5_8, c5_9, c5_10, c5_11, c5_12, c5_13, c5_14, c5_15; 
wire [39:0] c6_0, c6_1, c6_2, c6_3, c6_4, c6_5, c6_6, c6_7, c6_8, c6_9, c6_10, c6_11, c6_12, c6_13, c6_14, c6_15; 
wire [39:0] c7_0, c7_1, c7_2, c7_3, c7_4, c7_5, c7_6, c7_7, c7_8, c7_9, c7_10, c7_11, c7_12, c7_13, c7_14, c7_15; 
wire [39:0] c8_0, c8_1, c8_2, c8_3, c8_4, c8_5, c8_6, c8_7, c8_8, c8_9, c8_10, c8_11, c8_12, c8_13, c8_14, c8_15; 
wire [39:0] c9_0, c9_1, c9_2, c9_3, c9_4, c9_5, c9_6, c9_7, c9_8, c9_9, c9_10, c9_11, c9_12, c9_13, c9_14, c9_15; 
wire [39:0] c10_0, c10_1, c10_2, c10_3, c10_4, c10_5, c10_6, c10_7, c10_8, c10_9, c10_10, c10_11, c10_12, c10_13, c10_14, c10_15; 
wire [39:0] c11_0, c11_1, c11_2, c11_3, c11_4, c11_5, c11_6, c11_7, c11_8, c11_9, c11_10, c11_11, c11_12, c11_13, c11_14, c11_15; 
wire [39:0] c12_0, c12_1, c12_2, c12_3, c12_4, c12_5, c12_6, c12_7, c12_8, c12_9, c12_10, c12_11, c12_12, c12_13, c12_14, c12_15; 
wire [39:0] c13_0, c13_1, c13_2, c13_3, c13_4, c13_5, c13_6, c13_7, c13_8, c13_9, c13_10, c13_11, c13_12, c13_13, c13_14, c13_15; 
wire [39:0] c14_0, c14_1, c14_2, c14_3, c14_4, c14_5, c14_6, c14_7, c14_8, c14_9, c14_10, c14_11, c14_12, c14_13, c14_14, c14_15; 
wire [39:0] c15_0, c15_1, c15_2, c15_3, c15_4, c15_5, c15_6, c15_7, c15_8, c15_9, c15_10, c15_11, c15_12, c15_13, c15_14, c15_15; 
wire [15:0] d0_0, d0_1, d0_2, d0_3, d0_4, d0_5, d0_6, d0_7, d0_8, d0_9, d0_10, d0_11, d0_12, d0_13, d0_14, d0_15; 
wire [15:0] d1_0, d1_1, d1_2, d1_3, d1_4, d1_5, d1_6, d1_7, d1_8, d1_9, d1_10, d1_11, d1_12, d1_13, d1_14, d1_15; 
wire [15:0] d2_0, d2_1, d2_2, d2_3, d2_4, d2_5, d2_6, d2_7, d2_8, d2_9, d2_10, d2_11, d2_12, d2_13, d2_14, d2_15; 
wire [15:0] d3_0, d3_1, d3_2, d3_3, d3_4, d3_5, d3_6, d3_7, d3_8, d3_9, d3_10, d3_11, d3_12, d3_13, d3_14, d3_15; 
wire [15:0] d4_0, d4_1, d4_2, d4_3, d4_4, d4_5, d4_6, d4_7, d4_8, d4_9, d4_10, d4_11, d4_12, d4_13, d4_14, d4_15; 
wire [15:0] d5_0, d5_1, d5_2, d5_3, d5_4, d5_5, d5_6, d5_7, d5_8, d5_9, d5_10, d5_11, d5_12, d5_13, d5_14, d5_15; 
wire [15:0] d6_0, d6_1, d6_2, d6_3, d6_4, d6_5, d6_6, d6_7, d6_8, d6_9, d6_10, d6_11, d6_12, d6_13, d6_14, d6_15; 
wire [15:0] d7_0, d7_1, d7_2, d7_3, d7_4, d7_5, d7_6, d7_7, d7_8, d7_9, d7_10, d7_11, d7_12, d7_13, d7_14, d7_15; 
wire [15:0] d8_0, d8_1, d8_2, d8_3, d8_4, d8_5, d8_6, d8_7, d8_8, d8_9, d8_10, d8_11, d8_12, d8_13, d8_14, d8_15; 
wire [15:0] d9_0, d9_1, d9_2, d9_3, d9_4, d9_5, d9_6, d9_7, d9_8, d9_9, d9_10, d9_11, d9_12, d9_13, d9_14, d9_15; 
wire [15:0] d10_0, d10_1, d10_2, d10_3, d10_4, d10_5, d10_6, d10_7, d10_8, d10_9, d10_10, d10_11, d10_12, d10_13, d10_14, d10_15; 
wire [15:0] d11_0, d11_1, d11_2, d11_3, d11_4, d11_5, d11_6, d11_7, d11_8, d11_9, d11_10, d11_11, d11_12, d11_13, d11_14, d11_15; 
wire [15:0] d12_0, d12_1, d12_2, d12_3, d12_4, d12_5, d12_6, d12_7, d12_8, d12_9, d12_10, d12_11, d12_12, d12_13, d12_14, d12_15; 
wire [15:0] d13_0, d13_1, d13_2, d13_3, d13_4, d13_5, d13_6, d13_7, d13_8, d13_9, d13_10, d13_11, d13_12, d13_13, d13_14, d13_15; 
wire [15:0] d14_0, d14_1, d14_2, d14_3, d14_4, d14_5, d14_6, d14_7, d14_8, d14_9, d14_10, d14_11, d14_12, d14_13, d14_14, d14_15; 
wire [15:0] d15_0, d15_1, d15_2, d15_3, d15_4, d15_5, d15_6, d15_7, d15_8, d15_9, d15_10, d15_11, d15_12, d15_13, d15_14, d15_15; 
//---------------------------------------------------------------------
//   State block
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) c_state <= STATE_IDLE;
	else c_state <= n_state;
end
always@(*) begin
	case(c_state)
		STATE_IDLE: begin
			if(in_valid) n_state = STATE_INPUT;
			else n_state = STATE_IDLE;
		end
		STATE_INPUT: begin
			if(((size==2'b00&&counter==14'd128)||(size==2'b01&&counter==14'd512)||(size==2'b10&&counter==14'd2048)||(size==2'b11&&counter==14'd8192))) n_state = STATE_INDEX;
			else n_state = STATE_INPUT;
		end
		STATE_INDEX: begin
			n_state = STATE_CALCU;
		end
		STATE_CALCU: begin
			if(in_valid2) n_state = STATE_INDEX;
			else if(output_counter == 16&&((size==2'b00&&calcu_counter==7)||(size==2'b01&&calcu_counter==13)||(size==2'b10&&calcu_counter==25)||(size==2'b11&&calcu_counter==49))) begin
				n_state = STATE_IDLE;
			end
			else n_state = STATE_CALCU;
		end
	endcase
end
//---------------------------------------------------------------------
//   INPUT Block
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) size <= 0;
	else begin
		if(c_state == STATE_IDLE) begin
			if(input_counter == 0) size <= matrix_size;
			else size <= size;
		end
		else size <= size;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_in_valid <=0;
	else reg_in_valid <= in_valid;
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_data <= 0;
	else begin
		if(in_valid) input_data <= matrix;
		else input_data <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_counter <= 0;
	else begin
		if(c_state == STATE_INPUT) begin
			case(size)
				2'b00: begin 
					if(counter == 14'd63) input_counter <= 0;
					else input_counter <= input_counter+1;
				end
				2'b01: begin
					if(counter == 14'd255) input_counter <= 0;
					else input_counter <= input_counter+1;
				end
				2'b10: begin
					if(counter == 14'd1023) input_counter <= 0;
					else input_counter <= input_counter+1;
				end
				2'b11: begin
					if(counter == 14'd4095) input_counter <= 0;
					else input_counter <= input_counter+1;
				end
			endcase
			
		end
		else input_counter <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) counter <= 0;
	else begin
		if(c_state == STATE_INPUT) counter <= counter+1;
		else counter <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) calcu_counter <= 0;
	else begin
		if(n_state == STATE_CALCU) begin
			if(in_valid2) calcu_counter <= 0;
			else calcu_counter <= calcu_counter +1 ;
		end
		else calcu_counter <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) output_counter <= 1;
	else begin
		if(c_state == STATE_CALCU ) begin
			if(in_valid2) output_counter <= output_counter +1;
			else output_counter <= output_counter;
		end
		else if(c_state == STATE_IDLE) output_counter <= 1;
		else output_counter <= output_counter;
	end
end
always@(*) begin
	if(c_state == STATE_INPUT) begin
		case(size)
			2'b00: WEN_mod = input_counter%2;
			2'b01: WEN_mod = input_counter%4;
			2'b10: WEN_mod = input_counter%8;
			2'b11: WEN_mod = input_counter%16;
		endcase
	end
	else WEN_mod = 0;
end
always@(*) begin
	if(c_state == STATE_INPUT) begin
		case(size) 
			2'b00: counter_mod = input_counter % 4; 
			2'b01: counter_mod = input_counter % 16;
			2'b10: counter_mod = input_counter % 64;
			2'b11: counter_mod = input_counter % 256;
		endcase
	end
	else counter_mod = 0;
end

//---------------------------------------------------------------------
//   DELAY DESIGN
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[0] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[0] <= reg_input[0];
		else input_A[0] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[1] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[1] <= delay_A1;
		else input_A[1] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[2] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[2] <= delay_A2[0];
		else input_A[2] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[3] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[3] <= delay_A3[0];
		else input_A[3] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[4] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[4] <= delay_A4[0];
		else input_A[4] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[5] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[5] <= delay_A5[0];
		else input_A[5] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[6] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[6] <= delay_A6[0];
		else input_A[6] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[7] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[7] <= delay_A7[0];
		else input_A[7] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[8] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[8] <= delay_A8[0];
		else input_A[8] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[9] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[9] <= delay_A9[0];
		else input_A[9] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[10] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[10] <= delay_A10[0];
		else input_A[10] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[11] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[11] <= delay_A11[0];
		else input_A[11] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[12] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[12] <= delay_A12[0];
		else input_A[12] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[13] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[13] <= delay_A13[0];
		else input_A[13] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[14] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[14] <= delay_A14[0];
		else input_A[14] <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_A[15] <= 0;
	else begin
		if(c_state == STATE_CALCU) input_A[15] <= delay_A15[0];
		else input_A[15] <= 0;
	end
end

genvar a;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) delay_A1 <= 0;
	else begin
		delay_A1 <= reg_input[1];
	end
end
generate 
	for (a=0;a<2;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A2[a] <= 0;
			else begin
				if(a==1) delay_A2[a] <= reg_input[2];
				else delay_A2[a] <= delay_A2[a+1];
			end
		end
	end
endgenerate
generate 
	for (a=0;a<3;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A3[a] <= 0;
			else begin
				if(a==2) delay_A3[a] <= reg_input[3];
				else delay_A3[a] <= delay_A3[a+1];
			end
		end
	end
endgenerate
generate
	for(a=0;a<4;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A4[a] <= 0;
			else begin
				if(a==3) delay_A4[a] <= reg_input[4];
				else delay_A4[a] <= delay_A4[a+1];
			end
		end
	end
endgenerate
generate
	for(a=0;a<5;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A5[a] <= 0;
			else begin
				if(a==4) delay_A5[a] <= reg_input[5];
				else delay_A5[a] <= delay_A5[a+1];
			end
		end
	end
endgenerate
generate
	for(a=0;a<6;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A6[a] <= 0;
			else begin
				if(a==5) delay_A6[a] <= reg_input[6];
				else delay_A6[a] <= delay_A6[a+1];
			end
		end
	end
endgenerate
generate
	for(a=0;a<7;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A7[a] <= 0;
			else begin
				if(a==6) delay_A7[a] <= reg_input[7];
				else delay_A7[a] <= delay_A7[a+1];
			end
		end
	end
endgenerate
generate
	for(a=0;a<8;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A8[a] <= 0;
			else begin
				if(a==7) delay_A8[a] <= reg_input[8];
				else delay_A8[a] <= delay_A8[a+1];
			end
		end
	end
endgenerate
generate
	for(a=0;a<9;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A9[a] <= 0;
			else begin
				if(a==8) delay_A9[a] <= reg_input[9];
				else delay_A9[a] <= delay_A9[a+1];
			end
		end
	end
endgenerate
generate
	for(a=0;a<10;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A10[a] <= 0;
			else begin
				if(a==9) delay_A10[a] <= reg_input[10];
				else delay_A10[a] <= delay_A10[a+1];
			end
		end
	end
endgenerate
generate
	for(a=0;a<11;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A11[a] <= 0;
			else begin
				if(a==10) delay_A11[a] <= reg_input[11];
				else delay_A11[a] <= delay_A11[a+1];
			end
		end
	end
endgenerate
generate
	for(a=0;a<12;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A12[a] <= 0;
			else begin
				if(a==11) delay_A12[a] <= reg_input[12];
				else delay_A12[a] <= delay_A12[a+1];
			end
		end
	end
endgenerate
generate
	for(a=0;a<13;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A13[a] <= 0;
			else begin
				if(a==12) delay_A13[a] <= reg_input[13];
				else delay_A13[a] <= delay_A13[a+1];
			end
		end
	end
endgenerate
generate
	for(a=0;a<14;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A14[a] <= 0;
			else begin
				if(a==13) delay_A14[a] <= reg_input[14];
				else delay_A14[a] <= delay_A14[a+1];
			end
		end
	end
endgenerate
generate
	for(a=0;a<15;a=a+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) delay_A15[a] <= 0;
			else begin
				if(a==14) delay_A15[a] <= reg_input[15];
				else delay_A15[a] <= delay_A15[a+1];
			end
		end
	end
endgenerate

//---------------------------------------------------------------------
//   PE Block
//---------------------------------------------------------------------
//row 1
PE0 PE0_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(input_A[0]), .IN_W(reg_weight[0]), .OUT_C(c0_0), .OUT_D(d0_0));
PE0 PE0_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_0), .IN_W(reg_weight[1]), .OUT_C(c0_1), .OUT_D(d0_1));
PE0 PE0_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_1), .IN_W(reg_weight[2]), .OUT_C(c0_2), .OUT_D(d0_2));
PE0 PE0_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_2), .IN_W(reg_weight[3]), .OUT_C(c0_3), .OUT_D(d0_3));
PE0 PE0_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_3), .IN_W(reg_weight[4]), .OUT_C(c0_4), .OUT_D(d0_4));
PE0 PE0_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_4), .IN_W(reg_weight[5]), .OUT_C(c0_5), .OUT_D(d0_5));
PE0 PE0_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_5), .IN_W(reg_weight[6]), .OUT_C(c0_6), .OUT_D(d0_6));
PE0 PE0_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_6), .IN_W(reg_weight[7]), .OUT_C(c0_7), .OUT_D(d0_7));
PE0 PE0_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_7), .IN_W(reg_weight[8]), .OUT_C(c0_8), .OUT_D(d0_8));
PE0 PE0_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_8), .IN_W(reg_weight[9]), .OUT_C(c0_9), .OUT_D(d0_9));
PE0 PE0_10(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_9), .IN_W(reg_weight[10]), .OUT_C(c0_10), .OUT_D(d0_10));
PE0 PE0_11(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_10), .IN_W(reg_weight[11]), .OUT_C(c0_11), .OUT_D(d0_11));
PE0 PE0_12(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_11), .IN_W(reg_weight[12]), .OUT_C(c0_12), .OUT_D(d0_12));
PE0 PE0_13(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_12), .IN_W(reg_weight[13]), .OUT_C(c0_13), .OUT_D(d0_13));
PE0 PE0_14(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_13), .IN_W(reg_weight[14]), .OUT_C(c0_14), .OUT_D(d0_14));
PE0 PE0_15(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[0]), .IN_A(d0_14), .IN_W(reg_weight[15]), .OUT_C(c0_15), .OUT_D(d0_15));
//row 2
PE PE1_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(input_A[1]), .IN_B(c0_0), .IN_W(reg_weight[0]), .OUT_C(c1_0), .OUT_D(d1_0));
PE PE1_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_0), .IN_B(c0_1), .IN_W(reg_weight[1]), .OUT_C(c1_1), .OUT_D(d1_1));
PE PE1_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_1), .IN_B(c0_2), .IN_W(reg_weight[2]), .OUT_C(c1_2), .OUT_D(d1_2));
PE PE1_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_2), .IN_B(c0_3), .IN_W(reg_weight[3]), .OUT_C(c1_3), .OUT_D(d1_3));
PE PE1_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_3), .IN_B(c0_4), .IN_W(reg_weight[4]), .OUT_C(c1_4), .OUT_D(d1_4));
PE PE1_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_4), .IN_B(c0_5), .IN_W(reg_weight[5]), .OUT_C(c1_5), .OUT_D(d1_5));
PE PE1_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_5), .IN_B(c0_6), .IN_W(reg_weight[6]), .OUT_C(c1_6), .OUT_D(d1_6));
PE PE1_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_6), .IN_B(c0_7), .IN_W(reg_weight[7]), .OUT_C(c1_7), .OUT_D(d1_7));
PE PE1_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_7), .IN_B(c0_8), .IN_W(reg_weight[8]), .OUT_C(c1_8), .OUT_D(d1_8));
PE PE1_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_8), .IN_B(c0_9), .IN_W(reg_weight[9]), .OUT_C(c1_9), .OUT_D(d1_9));
PE PE1_10(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_9), .IN_B(c0_10), .IN_W(reg_weight[10]), .OUT_C(c1_10), .OUT_D(d1_10));
PE PE1_11(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_10), .IN_B(c0_11), .IN_W(reg_weight[11]), .OUT_C(c1_11), .OUT_D(d1_11));
PE PE1_12(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_11), .IN_B(c0_12), .IN_W(reg_weight[12]), .OUT_C(c1_12), .OUT_D(d1_12));
PE PE1_13(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_12), .IN_B(c0_13), .IN_W(reg_weight[13]), .OUT_C(c1_13), .OUT_D(d1_13));
PE PE1_14(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_13), .IN_B(c0_14), .IN_W(reg_weight[14]), .OUT_C(c1_14), .OUT_D(d1_14));
PE PE1_15(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_14), .IN_B(c0_15), .IN_W(reg_weight[15]), .OUT_C(c1_15), .OUT_D(d1_15));
//row 3
PE PE2_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(input_A[2]), .IN_B(c1_0), .IN_W(reg_weight[0]), .OUT_C(c2_0), .OUT_D(d2_0));
PE PE2_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_0), .IN_B(c1_1), .IN_W(reg_weight[1]), .OUT_C(c2_1), .OUT_D(d2_1));
PE PE2_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_1), .IN_B(c1_2), .IN_W(reg_weight[2]), .OUT_C(c2_2), .OUT_D(d2_2));
PE PE2_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_2), .IN_B(c1_3), .IN_W(reg_weight[3]), .OUT_C(c2_3), .OUT_D(d2_3));
PE PE2_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_3), .IN_B(c1_4), .IN_W(reg_weight[4]), .OUT_C(c2_4), .OUT_D(d2_4));
PE PE2_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_4), .IN_B(c1_5), .IN_W(reg_weight[5]), .OUT_C(c2_5), .OUT_D(d2_5));
PE PE2_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_5), .IN_B(c1_6), .IN_W(reg_weight[6]), .OUT_C(c2_6), .OUT_D(d2_6));
PE PE2_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_6), .IN_B(c1_7), .IN_W(reg_weight[7]), .OUT_C(c2_7), .OUT_D(d2_7));
PE PE2_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_7), .IN_B(c1_8), .IN_W(reg_weight[8]), .OUT_C(c2_8), .OUT_D(d2_8));
PE PE2_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_8), .IN_B(c1_9), .IN_W(reg_weight[9]), .OUT_C(c2_9), .OUT_D(d2_9));
PE PE2_10(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_9), .IN_B(c1_10), .IN_W(reg_weight[10]), .OUT_C(c2_10), .OUT_D(d2_10));
PE PE2_11(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_10), .IN_B(c1_11), .IN_W(reg_weight[11]), .OUT_C(c2_11), .OUT_D(d2_11));
PE PE2_12(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_11), .IN_B(c1_12), .IN_W(reg_weight[12]), .OUT_C(c2_12), .OUT_D(d2_12));
PE PE2_13(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_12), .IN_B(c1_13), .IN_W(reg_weight[13]), .OUT_C(c2_13), .OUT_D(d2_13));
PE PE2_14(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_13), .IN_B(c1_14), .IN_W(reg_weight[14]), .OUT_C(c2_14), .OUT_D(d2_14));
PE PE2_15(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_14), .IN_B(c1_15), .IN_W(reg_weight[15]), .OUT_C(c2_15), .OUT_D(d2_15));
//row 4
PE PE3_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(input_A[3]), .IN_B(c2_0), .IN_W(reg_weight[0]), .OUT_C(c3_0), .OUT_D(d3_0));
PE PE3_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_0), .IN_B(c2_1), .IN_W(reg_weight[1]), .OUT_C(c3_1), .OUT_D(d3_1));
PE PE3_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_1), .IN_B(c2_2), .IN_W(reg_weight[2]), .OUT_C(c3_2), .OUT_D(d3_2));
PE PE3_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_2), .IN_B(c2_3), .IN_W(reg_weight[3]), .OUT_C(c3_3), .OUT_D(d3_3));
PE PE3_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_3), .IN_B(c2_4), .IN_W(reg_weight[4]), .OUT_C(c3_4), .OUT_D(d3_4));
PE PE3_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_4), .IN_B(c2_5), .IN_W(reg_weight[5]), .OUT_C(c3_5), .OUT_D(d3_5));
PE PE3_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_5), .IN_B(c2_6), .IN_W(reg_weight[6]), .OUT_C(c3_6), .OUT_D(d3_6));
PE PE3_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_6), .IN_B(c2_7), .IN_W(reg_weight[7]), .OUT_C(c3_7), .OUT_D(d3_7));
PE PE3_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_7), .IN_B(c2_8), .IN_W(reg_weight[8]), .OUT_C(c3_8), .OUT_D(d3_8));
PE PE3_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_8), .IN_B(c2_9), .IN_W(reg_weight[9]), .OUT_C(c3_9), .OUT_D(d3_9));
PE PE3_10(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_9), .IN_B(c2_10), .IN_W(reg_weight[10]), .OUT_C(c3_10), .OUT_D(d3_10));
PE PE3_11(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_10), .IN_B(c2_11), .IN_W(reg_weight[11]), .OUT_C(c3_11), .OUT_D(d3_11));
PE PE3_12(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_11), .IN_B(c2_12), .IN_W(reg_weight[12]), .OUT_C(c3_12), .OUT_D(d3_12));
PE PE3_13(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_12), .IN_B(c2_13), .IN_W(reg_weight[13]), .OUT_C(c3_13), .OUT_D(d3_13));
PE PE3_14(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_13), .IN_B(c2_14), .IN_W(reg_weight[14]), .OUT_C(c3_14), .OUT_D(d3_14));
PE PE3_15(.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_14), .IN_B(c2_15), .IN_W(reg_weight[15]), .OUT_C(c3_15), .OUT_D(d3_15));
//row 5
PE PE4_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(input_A[4]), .IN_B(c3_0), .IN_W(reg_weight[0]), .OUT_C(c4_0), .OUT_D(d4_0));
PE PE4_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_0), .IN_B(c3_1), .IN_W(reg_weight[1]), .OUT_C(c4_1), .OUT_D(d4_1));
PE PE4_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_1), .IN_B(c3_2), .IN_W(reg_weight[2]), .OUT_C(c4_2), .OUT_D(d4_2));
PE PE4_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_2), .IN_B(c3_3), .IN_W(reg_weight[3]), .OUT_C(c4_3), .OUT_D(d4_3));
PE PE4_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_3), .IN_B(c3_4), .IN_W(reg_weight[4]), .OUT_C(c4_4), .OUT_D(d4_4));
PE PE4_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_4), .IN_B(c3_5), .IN_W(reg_weight[5]), .OUT_C(c4_5), .OUT_D(d4_5));
PE PE4_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_5), .IN_B(c3_6), .IN_W(reg_weight[6]), .OUT_C(c4_6), .OUT_D(d4_6));
PE PE4_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_6), .IN_B(c3_7), .IN_W(reg_weight[7]), .OUT_C(c4_7), .OUT_D(d4_7));
PE PE4_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_7), .IN_B(c3_8), .IN_W(reg_weight[8]), .OUT_C(c4_8), .OUT_D(d4_8));
PE PE4_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_8), .IN_B(c3_9), .IN_W(reg_weight[9]), .OUT_C(c4_9), .OUT_D(d4_9));
PE PE4_10 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_9), .IN_B(c3_10), .IN_W(reg_weight[10]), .OUT_C(c4_10), .OUT_D(d4_10));
PE PE4_11 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_10), .IN_B(c3_11), .IN_W(reg_weight[11]), .OUT_C(c4_11), .OUT_D(d4_11));
PE PE4_12 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_11), .IN_B(c3_12), .IN_W(reg_weight[12]), .OUT_C(c4_12), .OUT_D(d4_12));
PE PE4_13 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_12), .IN_B(c3_13), .IN_W(reg_weight[13]), .OUT_C(c4_13), .OUT_D(d4_13));
PE PE4_14 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_13), .IN_B(c3_14), .IN_W(reg_weight[14]), .OUT_C(c4_14), .OUT_D(d4_14));
PE PE4_15 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_14), .IN_B(c3_15), .IN_W(reg_weight[15]), .OUT_C(c4_15), .OUT_D(d4_15));
// row 6
PE PE5_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(input_A[5]), .IN_B(c4_0), .IN_W(reg_weight[0]), .OUT_C(c5_0), .OUT_D(d5_0));
PE PE5_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_0), .IN_B(c4_1), .IN_W(reg_weight[1]), .OUT_C(c5_1), .OUT_D(d5_1));
PE PE5_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_1), .IN_B(c4_2), .IN_W(reg_weight[2]), .OUT_C(c5_2), .OUT_D(d5_2));
PE PE5_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_2), .IN_B(c4_3), .IN_W(reg_weight[3]), .OUT_C(c5_3), .OUT_D(d5_3));
PE PE5_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_3), .IN_B(c4_4), .IN_W(reg_weight[4]), .OUT_C(c5_4), .OUT_D(d5_4));
PE PE5_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_4), .IN_B(c4_5), .IN_W(reg_weight[5]), .OUT_C(c5_5), .OUT_D(d5_5));
PE PE5_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_5), .IN_B(c4_6), .IN_W(reg_weight[6]), .OUT_C(c5_6), .OUT_D(d5_6));
PE PE5_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_6), .IN_B(c4_7), .IN_W(reg_weight[7]), .OUT_C(c5_7), .OUT_D(d5_7));
PE PE5_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_7), .IN_B(c4_8), .IN_W(reg_weight[8]), .OUT_C(c5_8), .OUT_D(d5_8));
PE PE5_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_8), .IN_B(c4_9), .IN_W(reg_weight[9]), .OUT_C(c5_9), .OUT_D(d5_9));
PE PE5_10 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_9), .IN_B(c4_10), .IN_W(reg_weight[10]), .OUT_C(c5_10), .OUT_D(d5_10));
PE PE5_11 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_10), .IN_B(c4_11), .IN_W(reg_weight[11]), .OUT_C(c5_11), .OUT_D(d5_11));
PE PE5_12 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_11), .IN_B(c4_12), .IN_W(reg_weight[12]), .OUT_C(c5_12), .OUT_D(d5_12));
PE PE5_13 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_12), .IN_B(c4_13), .IN_W(reg_weight[13]), .OUT_C(c5_13), .OUT_D(d5_13));
PE PE5_14 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_13), .IN_B(c4_14), .IN_W(reg_weight[14]), .OUT_C(c5_14), .OUT_D(d5_14));
PE PE5_15 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_14), .IN_B(c4_15), .IN_W(reg_weight[15]), .OUT_C(c5_15), .OUT_D(d5_15));
// row 7
PE PE6_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(input_A[6]), .IN_B(c5_0), .IN_W(reg_weight[0]), .OUT_C(c6_0), .OUT_D(d6_0));
PE PE6_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_0), .IN_B(c5_1), .IN_W(reg_weight[1]), .OUT_C(c6_1), .OUT_D(d6_1));
PE PE6_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_1), .IN_B(c5_2), .IN_W(reg_weight[2]), .OUT_C(c6_2), .OUT_D(d6_2));
PE PE6_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_2), .IN_B(c5_3), .IN_W(reg_weight[3]), .OUT_C(c6_3), .OUT_D(d6_3));
PE PE6_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_3), .IN_B(c5_4), .IN_W(reg_weight[4]), .OUT_C(c6_4), .OUT_D(d6_4));
PE PE6_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_4), .IN_B(c5_5), .IN_W(reg_weight[5]), .OUT_C(c6_5), .OUT_D(d6_5));
PE PE6_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_5), .IN_B(c5_6), .IN_W(reg_weight[6]), .OUT_C(c6_6), .OUT_D(d6_6));
PE PE6_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_6), .IN_B(c5_7), .IN_W(reg_weight[7]), .OUT_C(c6_7), .OUT_D(d6_7));
PE PE6_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_7), .IN_B(c5_8), .IN_W(reg_weight[8]), .OUT_C(c6_8), .OUT_D(d6_8));
PE PE6_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_8), .IN_B(c5_9), .IN_W(reg_weight[9]), .OUT_C(c6_9), .OUT_D(d6_9));
PE PE6_10 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_9), .IN_B(c5_10), .IN_W(reg_weight[10]), .OUT_C(c6_10), .OUT_D(d6_10));
PE PE6_11 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_10), .IN_B(c5_11), .IN_W(reg_weight[11]), .OUT_C(c6_11), .OUT_D(d6_11));
PE PE6_12 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_11), .IN_B(c5_12), .IN_W(reg_weight[12]), .OUT_C(c6_12), .OUT_D(d6_12));
PE PE6_13 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_12), .IN_B(c5_13), .IN_W(reg_weight[13]), .OUT_C(c6_13), .OUT_D(d6_13));
PE PE6_14 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_13), .IN_B(c5_14), .IN_W(reg_weight[14]), .OUT_C(c6_14), .OUT_D(d6_14));
PE PE6_15 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_14), .IN_B(c5_15), .IN_W(reg_weight[15]), .OUT_C(c6_15), .OUT_D(d6_15));
// row 8
PE PE7_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(input_A[7]), .IN_B(c6_0), .IN_W(reg_weight[0]), .OUT_C(c7_0), .OUT_D(d7_0));
PE PE7_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_0), .IN_B(c6_1), .IN_W(reg_weight[1]), .OUT_C(c7_1), .OUT_D(d7_1));
PE PE7_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_1), .IN_B(c6_2), .IN_W(reg_weight[2]), .OUT_C(c7_2), .OUT_D(d7_2));
PE PE7_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_2), .IN_B(c6_3), .IN_W(reg_weight[3]), .OUT_C(c7_3), .OUT_D(d7_3));
PE PE7_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_3), .IN_B(c6_4), .IN_W(reg_weight[4]), .OUT_C(c7_4), .OUT_D(d7_4));
PE PE7_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_4), .IN_B(c6_5), .IN_W(reg_weight[5]), .OUT_C(c7_5), .OUT_D(d7_5));
PE PE7_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_5), .IN_B(c6_6), .IN_W(reg_weight[6]), .OUT_C(c7_6), .OUT_D(d7_6));
PE PE7_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_6), .IN_B(c6_7), .IN_W(reg_weight[7]), .OUT_C(c7_7), .OUT_D(d7_7));
PE PE7_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_7), .IN_B(c6_8), .IN_W(reg_weight[8]), .OUT_C(c7_8), .OUT_D(d7_8));
PE PE7_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_8), .IN_B(c6_9), .IN_W(reg_weight[9]), .OUT_C(c7_9), .OUT_D(d7_9));
PE PE7_10 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_9), .IN_B(c6_10), .IN_W(reg_weight[10]), .OUT_C(c7_10), .OUT_D(d7_10));
PE PE7_11 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_10), .IN_B(c6_11), .IN_W(reg_weight[11]), .OUT_C(c7_11), .OUT_D(d7_11));
PE PE7_12 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_11), .IN_B(c6_12), .IN_W(reg_weight[12]), .OUT_C(c7_12), .OUT_D(d7_12));
PE PE7_13 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_12), .IN_B(c6_13), .IN_W(reg_weight[13]), .OUT_C(c7_13), .OUT_D(d7_13));
PE PE7_14 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_13), .IN_B(c6_14), .IN_W(reg_weight[14]), .OUT_C(c7_14), .OUT_D(d7_14));
PE PE7_15 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_14), .IN_B(c6_15), .IN_W(reg_weight[15]), .OUT_C(c7_15), .OUT_D(d7_15));
// row 9
PE PE8_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(input_A[8]), .IN_B(c7_0), .IN_W(reg_weight[0]), .OUT_C(c8_0), .OUT_D(d8_0));
PE PE8_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_0), .IN_B(c7_1), .IN_W(reg_weight[1]), .OUT_C(c8_1), .OUT_D(d8_1));
PE PE8_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_1), .IN_B(c7_2), .IN_W(reg_weight[2]), .OUT_C(c8_2), .OUT_D(d8_2));
PE PE8_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_2), .IN_B(c7_3), .IN_W(reg_weight[3]), .OUT_C(c8_3), .OUT_D(d8_3));
PE PE8_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_3), .IN_B(c7_4), .IN_W(reg_weight[4]), .OUT_C(c8_4), .OUT_D(d8_4));
PE PE8_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_4), .IN_B(c7_5), .IN_W(reg_weight[5]), .OUT_C(c8_5), .OUT_D(d8_5));
PE PE8_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_5), .IN_B(c7_6), .IN_W(reg_weight[6]), .OUT_C(c8_6), .OUT_D(d8_6));
PE PE8_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_6), .IN_B(c7_7), .IN_W(reg_weight[7]), .OUT_C(c8_7), .OUT_D(d8_7));
PE PE8_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_7), .IN_B(c7_8), .IN_W(reg_weight[8]), .OUT_C(c8_8), .OUT_D(d8_8));
PE PE8_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_8), .IN_B(c7_9), .IN_W(reg_weight[9]), .OUT_C(c8_9), .OUT_D(d8_9));
PE PE8_10 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_9), .IN_B(c7_10), .IN_W(reg_weight[10]), .OUT_C(c8_10), .OUT_D(d8_10));
PE PE8_11 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_10), .IN_B(c7_11), .IN_W(reg_weight[11]), .OUT_C(c8_11), .OUT_D(d8_11));
PE PE8_12 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_11), .IN_B(c7_12), .IN_W(reg_weight[12]), .OUT_C(c8_12), .OUT_D(d8_12));
PE PE8_13 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_12), .IN_B(c7_13), .IN_W(reg_weight[13]), .OUT_C(c8_13), .OUT_D(d8_13));
PE PE8_14 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_13), .IN_B(c7_14), .IN_W(reg_weight[14]), .OUT_C(c8_14), .OUT_D(d8_14));
PE PE8_15 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[8]), .IN_A(d8_14), .IN_B(c7_15), .IN_W(reg_weight[15]), .OUT_C(c8_15), .OUT_D(d8_15));
// row 10
PE PE9_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(input_A[9]), .IN_B(c8_0), .IN_W(reg_weight[0]), .OUT_C(c9_0), .OUT_D(d9_0));
PE PE9_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_0), .IN_B(c8_1), .IN_W(reg_weight[1]), .OUT_C(c9_1), .OUT_D(d9_1));
PE PE9_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_1), .IN_B(c8_2), .IN_W(reg_weight[2]), .OUT_C(c9_2), .OUT_D(d9_2));
PE PE9_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_2), .IN_B(c8_3), .IN_W(reg_weight[3]), .OUT_C(c9_3), .OUT_D(d9_3));
PE PE9_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_3), .IN_B(c8_4), .IN_W(reg_weight[4]), .OUT_C(c9_4), .OUT_D(d9_4));
PE PE9_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_4), .IN_B(c8_5), .IN_W(reg_weight[5]), .OUT_C(c9_5), .OUT_D(d9_5));
PE PE9_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_5), .IN_B(c8_6), .IN_W(reg_weight[6]), .OUT_C(c9_6), .OUT_D(d9_6));
PE PE9_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_6), .IN_B(c8_7), .IN_W(reg_weight[7]), .OUT_C(c9_7), .OUT_D(d9_7));
PE PE9_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_7), .IN_B(c8_8), .IN_W(reg_weight[8]), .OUT_C(c9_8), .OUT_D(d9_8));
PE PE9_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_8), .IN_B(c8_9), .IN_W(reg_weight[9]), .OUT_C(c9_9), .OUT_D(d9_9));
PE PE9_10 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_9), .IN_B(c8_10), .IN_W(reg_weight[10]), .OUT_C(c9_10), .OUT_D(d9_10));
PE PE9_11 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_10), .IN_B(c8_11), .IN_W(reg_weight[11]), .OUT_C(c9_11), .OUT_D(d9_11));
PE PE9_12 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_11), .IN_B(c8_12), .IN_W(reg_weight[12]), .OUT_C(c9_12), .OUT_D(d9_12));
PE PE9_13 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_12), .IN_B(c8_13), .IN_W(reg_weight[13]), .OUT_C(c9_13), .OUT_D(d9_13));
PE PE9_14 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_13), .IN_B(c8_14), .IN_W(reg_weight[14]), .OUT_C(c9_14), .OUT_D(d9_14));
PE PE9_15 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[9]), .IN_A(d9_14), .IN_B(c8_15), .IN_W(reg_weight[15]), .OUT_C(c9_15), .OUT_D(d9_15));
// row 11
PE PE10_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(input_A[10]), .IN_B(c9_0), .IN_W(reg_weight[0]), .OUT_C(c10_0), .OUT_D(d10_0));
PE PE10_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_0), .IN_B(c9_1), .IN_W(reg_weight[1]), .OUT_C(c10_1), .OUT_D(d10_1));
PE PE10_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_1), .IN_B(c9_2), .IN_W(reg_weight[2]), .OUT_C(c10_2), .OUT_D(d10_2));
PE PE10_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_2), .IN_B(c9_3), .IN_W(reg_weight[3]), .OUT_C(c10_3), .OUT_D(d10_3));
PE PE10_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_3), .IN_B(c9_4), .IN_W(reg_weight[4]), .OUT_C(c10_4), .OUT_D(d10_4));
PE PE10_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_4), .IN_B(c9_5), .IN_W(reg_weight[5]), .OUT_C(c10_5), .OUT_D(d10_5));
PE PE10_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_5), .IN_B(c9_6), .IN_W(reg_weight[6]), .OUT_C(c10_6), .OUT_D(d10_6));
PE PE10_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_6), .IN_B(c9_7), .IN_W(reg_weight[7]), .OUT_C(c10_7), .OUT_D(d10_7));
PE PE10_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_7), .IN_B(c9_8), .IN_W(reg_weight[8]), .OUT_C(c10_8), .OUT_D(d10_8));
PE PE10_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_8), .IN_B(c9_9), .IN_W(reg_weight[9]), .OUT_C(c10_9), .OUT_D(d10_9));
PE PE10_10 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_9), .IN_B(c9_10), .IN_W(reg_weight[10]), .OUT_C(c10_10), .OUT_D(d10_10));
PE PE10_11 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_10), .IN_B(c9_11), .IN_W(reg_weight[11]), .OUT_C(c10_11), .OUT_D(d10_11));
PE PE10_12 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_11), .IN_B(c9_12), .IN_W(reg_weight[12]), .OUT_C(c10_12), .OUT_D(d10_12));
PE PE10_13 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_12), .IN_B(c9_13), .IN_W(reg_weight[13]), .OUT_C(c10_13), .OUT_D(d10_13));
PE PE10_14 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_13), .IN_B(c9_14), .IN_W(reg_weight[14]), .OUT_C(c10_14), .OUT_D(d10_14));
PE PE10_15 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[10]), .IN_A(d10_14), .IN_B(c9_15), .IN_W(reg_weight[15]), .OUT_C(c10_15), .OUT_D(d10_15));
// row 12
PE PE11_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(input_A[11]), .IN_B(c10_0), .IN_W(reg_weight[0]), .OUT_C(c11_0), .OUT_D(d11_0));
PE PE11_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_0), .IN_B(c10_1), .IN_W(reg_weight[1]), .OUT_C(c11_1), .OUT_D(d11_1));
PE PE11_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_1), .IN_B(c10_2), .IN_W(reg_weight[2]), .OUT_C(c11_2), .OUT_D(d11_2));
PE PE11_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_2), .IN_B(c10_3), .IN_W(reg_weight[3]), .OUT_C(c11_3), .OUT_D(d11_3));
PE PE11_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_3), .IN_B(c10_4), .IN_W(reg_weight[4]), .OUT_C(c11_4), .OUT_D(d11_4));
PE PE11_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_4), .IN_B(c10_5), .IN_W(reg_weight[5]), .OUT_C(c11_5), .OUT_D(d11_5));
PE PE11_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_5), .IN_B(c10_6), .IN_W(reg_weight[6]), .OUT_C(c11_6), .OUT_D(d11_6));
PE PE11_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_6), .IN_B(c10_7), .IN_W(reg_weight[7]), .OUT_C(c11_7), .OUT_D(d11_7));
PE PE11_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_7), .IN_B(c10_8), .IN_W(reg_weight[8]), .OUT_C(c11_8), .OUT_D(d11_8));
PE PE11_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_8), .IN_B(c10_9), .IN_W(reg_weight[9]), .OUT_C(c11_9), .OUT_D(d11_9));
PE PE11_10 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_9), .IN_B(c10_10), .IN_W(reg_weight[10]), .OUT_C(c11_10), .OUT_D(d11_10));
PE PE11_11 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_10), .IN_B(c10_11), .IN_W(reg_weight[11]), .OUT_C(c11_11), .OUT_D(d11_11));
PE PE11_12 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_11), .IN_B(c10_12), .IN_W(reg_weight[12]), .OUT_C(c11_12), .OUT_D(d11_12));
PE PE11_13 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_12), .IN_B(c10_13), .IN_W(reg_weight[13]), .OUT_C(c11_13), .OUT_D(d11_13));
PE PE11_14 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_13), .IN_B(c10_14), .IN_W(reg_weight[14]), .OUT_C(c11_14), .OUT_D(d11_14));
PE PE11_15 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[11]), .IN_A(d11_14), .IN_B(c10_15), .IN_W(reg_weight[15]), .OUT_C(c11_15), .OUT_D(d11_15));
// row 13
PE PE12_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(input_A[12]), .IN_B(c11_0), .IN_W(reg_weight[0]), .OUT_C(c12_0), .OUT_D(d12_0));
PE PE12_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_0), .IN_B(c11_1), .IN_W(reg_weight[1]), .OUT_C(c12_1), .OUT_D(d12_1));
PE PE12_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_1), .IN_B(c11_2), .IN_W(reg_weight[2]), .OUT_C(c12_2), .OUT_D(d12_2));
PE PE12_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_2), .IN_B(c11_3), .IN_W(reg_weight[3]), .OUT_C(c12_3), .OUT_D(d12_3));
PE PE12_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_3), .IN_B(c11_4), .IN_W(reg_weight[4]), .OUT_C(c12_4), .OUT_D(d12_4));
PE PE12_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_4), .IN_B(c11_5), .IN_W(reg_weight[5]), .OUT_C(c12_5), .OUT_D(d12_5));
PE PE12_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_5), .IN_B(c11_6), .IN_W(reg_weight[6]), .OUT_C(c12_6), .OUT_D(d12_6));
PE PE12_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_6), .IN_B(c11_7), .IN_W(reg_weight[7]), .OUT_C(c12_7), .OUT_D(d12_7));
PE PE12_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_7), .IN_B(c11_8), .IN_W(reg_weight[8]), .OUT_C(c12_8), .OUT_D(d12_8));
PE PE12_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_8), .IN_B(c11_9), .IN_W(reg_weight[9]), .OUT_C(c12_9), .OUT_D(d12_9));
PE PE12_10 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_9), .IN_B(c11_10), .IN_W(reg_weight[10]), .OUT_C(c12_10), .OUT_D(d12_10));
PE PE12_11 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_10), .IN_B(c11_11), .IN_W(reg_weight[11]), .OUT_C(c12_11), .OUT_D(d12_11));
PE PE12_12 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_11), .IN_B(c11_12), .IN_W(reg_weight[12]), .OUT_C(c12_12), .OUT_D(d12_12));
PE PE12_13 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_12), .IN_B(c11_13), .IN_W(reg_weight[13]), .OUT_C(c12_13), .OUT_D(d12_13));
PE PE12_14 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_13), .IN_B(c11_14), .IN_W(reg_weight[14]), .OUT_C(c12_14), .OUT_D(d12_14));
PE PE12_15 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[12]), .IN_A(d12_14), .IN_B(c11_15), .IN_W(reg_weight[15]), .OUT_C(c12_15), .OUT_D(d12_15));
// row 14
PE PE13_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(input_A[13]), .IN_B(c12_0), .IN_W(reg_weight[0]), .OUT_C(c13_0), .OUT_D(d13_0));
PE PE13_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_0), .IN_B(c12_1), .IN_W(reg_weight[1]), .OUT_C(c13_1), .OUT_D(d13_1));
PE PE13_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_1), .IN_B(c12_2), .IN_W(reg_weight[2]), .OUT_C(c13_2), .OUT_D(d13_2));
PE PE13_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_2), .IN_B(c12_3), .IN_W(reg_weight[3]), .OUT_C(c13_3), .OUT_D(d13_3));
PE PE13_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_3), .IN_B(c12_4), .IN_W(reg_weight[4]), .OUT_C(c13_4), .OUT_D(d13_4));
PE PE13_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_4), .IN_B(c12_5), .IN_W(reg_weight[5]), .OUT_C(c13_5), .OUT_D(d13_5));
PE PE13_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_5), .IN_B(c12_6), .IN_W(reg_weight[6]), .OUT_C(c13_6), .OUT_D(d13_6));
PE PE13_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_6), .IN_B(c12_7), .IN_W(reg_weight[7]), .OUT_C(c13_7), .OUT_D(d13_7));
PE PE13_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_7), .IN_B(c12_8), .IN_W(reg_weight[8]), .OUT_C(c13_8), .OUT_D(d13_8));
PE PE13_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_8), .IN_B(c12_9), .IN_W(reg_weight[9]), .OUT_C(c13_9), .OUT_D(d13_9));
PE PE13_10 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_9), .IN_B(c12_10), .IN_W(reg_weight[10]), .OUT_C(c13_10), .OUT_D(d13_10));
PE PE13_11 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_10), .IN_B(c12_11), .IN_W(reg_weight[11]), .OUT_C(c13_11), .OUT_D(d13_11));
PE PE13_12 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_11), .IN_B(c12_12), .IN_W(reg_weight[12]), .OUT_C(c13_12), .OUT_D(d13_12));
PE PE13_13 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_12), .IN_B(c12_13), .IN_W(reg_weight[13]), .OUT_C(c13_13), .OUT_D(d13_13));
PE PE13_14 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_13), .IN_B(c12_14), .IN_W(reg_weight[14]), .OUT_C(c13_14), .OUT_D(d13_14));
PE PE13_15 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[13]), .IN_A(d13_14), .IN_B(c12_15), .IN_W(reg_weight[15]), .OUT_C(c13_15), .OUT_D(d13_15));
// row 15
PE PE14_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(input_A[14]), .IN_B(c13_0), .IN_W(reg_weight[0]), .OUT_C(c14_0), .OUT_D(d14_0));
PE PE14_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_0), .IN_B(c13_1), .IN_W(reg_weight[1]), .OUT_C(c14_1), .OUT_D(d14_1));
PE PE14_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_1), .IN_B(c13_2), .IN_W(reg_weight[2]), .OUT_C(c14_2), .OUT_D(d14_2));
PE PE14_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_2), .IN_B(c13_3), .IN_W(reg_weight[3]), .OUT_C(c14_3), .OUT_D(d14_3));
PE PE14_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_3), .IN_B(c13_4), .IN_W(reg_weight[4]), .OUT_C(c14_4), .OUT_D(d14_4));
PE PE14_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_4), .IN_B(c13_5), .IN_W(reg_weight[5]), .OUT_C(c14_5), .OUT_D(d14_5));
PE PE14_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_5), .IN_B(c13_6), .IN_W(reg_weight[6]), .OUT_C(c14_6), .OUT_D(d14_6));
PE PE14_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_6), .IN_B(c13_7), .IN_W(reg_weight[7]), .OUT_C(c14_7), .OUT_D(d14_7));
PE PE14_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_7), .IN_B(c13_8), .IN_W(reg_weight[8]), .OUT_C(c14_8), .OUT_D(d14_8));
PE PE14_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_8), .IN_B(c13_9), .IN_W(reg_weight[9]), .OUT_C(c14_9), .OUT_D(d14_9));
PE PE14_10 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_9), .IN_B(c13_10), .IN_W(reg_weight[10]), .OUT_C(c14_10), .OUT_D(d14_10));
PE PE14_11 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_10), .IN_B(c13_11), .IN_W(reg_weight[11]), .OUT_C(c14_11), .OUT_D(d14_11));
PE PE14_12 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_11), .IN_B(c13_12), .IN_W(reg_weight[12]), .OUT_C(c14_12), .OUT_D(d14_12));
PE PE14_13 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_12), .IN_B(c13_13), .IN_W(reg_weight[13]), .OUT_C(c14_13), .OUT_D(d14_13));
PE PE14_14 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_13), .IN_B(c13_14), .IN_W(reg_weight[14]), .OUT_C(c14_14), .OUT_D(d14_14));
PE PE14_15 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[14]), .IN_A(d14_14), .IN_B(c13_15), .IN_W(reg_weight[15]), .OUT_C(c14_15), .OUT_D(d14_15));
// row 16
PE PE15_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(input_A[15]), .IN_B(c14_0), .IN_W(reg_weight[0]), .OUT_C(c15_0), .OUT_D(d15_0));
PE PE15_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_0), .IN_B(c14_1), .IN_W(reg_weight[1]), .OUT_C(c15_1), .OUT_D(d15_1));
PE PE15_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_1), .IN_B(c14_2), .IN_W(reg_weight[2]), .OUT_C(c15_2), .OUT_D(d15_2));
PE PE15_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_2), .IN_B(c14_3), .IN_W(reg_weight[3]), .OUT_C(c15_3), .OUT_D(d15_3));
PE PE15_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_3), .IN_B(c14_4), .IN_W(reg_weight[4]), .OUT_C(c15_4), .OUT_D(d15_4));
PE PE15_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_4), .IN_B(c14_5), .IN_W(reg_weight[5]), .OUT_C(c15_5), .OUT_D(d15_5));
PE PE15_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_5), .IN_B(c14_6), .IN_W(reg_weight[6]), .OUT_C(c15_6), .OUT_D(d15_6));
PE PE15_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_6), .IN_B(c14_7), .IN_W(reg_weight[7]), .OUT_C(c15_7), .OUT_D(d15_7));
PE PE15_8 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_7), .IN_B(c14_8), .IN_W(reg_weight[8]), .OUT_C(c15_8), .OUT_D(d15_8));
PE PE15_9 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_8), .IN_B(c14_9), .IN_W(reg_weight[9]), .OUT_C(c15_9), .OUT_D(d15_9));
PE PE15_10 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_9), .IN_B(c14_10), .IN_W(reg_weight[10]), .OUT_C(c15_10), .OUT_D(d15_10));
PE PE15_11 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_10), .IN_B(c14_11), .IN_W(reg_weight[11]), .OUT_C(c15_11), .OUT_D(d15_11));
PE PE15_12 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_11), .IN_B(c14_12), .IN_W(reg_weight[12]), .OUT_C(c15_12), .OUT_D(d15_12));
PE PE15_13 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_12), .IN_B(c14_13), .IN_W(reg_weight[13]), .OUT_C(c15_13), .OUT_D(d15_13));
PE PE15_14 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_13), .IN_B(c14_14), .IN_W(reg_weight[14]), .OUT_C(c15_14), .OUT_D(d15_14));
PE PE15_15 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[15]), .IN_A(d15_14), .IN_B(c14_15), .IN_W(reg_weight[15]), .OUT_C(c15_15), .OUT_D(d15_15));

//---------------------------------------------------------------------
//   SRAM DESIGN
//---------------------------------------------------------------------
SRAM_256_16_4 Input_Mem0   (.Q(IM_output[0]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[0]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem1   (.Q(IM_output[1]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[1]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem2   (.Q(IM_output[2]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[2]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem3   (.Q(IM_output[3]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[3]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem4   (.Q(IM_output[4]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[4]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem5   (.Q(IM_output[5]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[5]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem6   (.Q(IM_output[6]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[6]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem7   (.Q(IM_output[7]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[7]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem8   (.Q(IM_output[8]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[8]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem9   (.Q(IM_output[9]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[9]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem10  (.Q(IM_output[10]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[10]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem11  (.Q(IM_output[11]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[11]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem12  (.Q(IM_output[12]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[12]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem13  (.Q(IM_output[13]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[13]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem14  (.Q(IM_output[14]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[14]), .A(IM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Input_Mem15  (.Q(IM_output[15]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[15]), .A(IM_addr), .D(input_data), .OEN(1'b0));


SRAM_256_16_4 Weight_Mem0  (.Q(WM_output[0]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[0]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem1  (.Q(WM_output[1]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[1]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem2  (.Q(WM_output[2]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[2]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem3  (.Q(WM_output[3]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[3]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem4  (.Q(WM_output[4]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[4]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem5  (.Q(WM_output[5]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[5]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem6  (.Q(WM_output[6]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[6]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem7  (.Q(WM_output[7]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[7]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem8  (.Q(WM_output[8]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[8]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem9  (.Q(WM_output[9]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[9]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem10 (.Q(WM_output[10]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[10]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem11 (.Q(WM_output[11]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[11]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem12 (.Q(WM_output[12]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[12]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem13 (.Q(WM_output[13]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[13]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem14 (.Q(WM_output[14]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[14]), .A(WM_addr), .D(input_data), .OEN(1'b0));
SRAM_256_16_4 Weight_Mem15 (.Q(WM_output[15]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[15]), .A(WM_addr), .D(input_data), .OEN(1'b0));
genvar j;
generate
	for(j=0;j<16;j=j+1) begin
		always@(*) begin
			if(!rst_n) IM_WEN[j] = 1;
			else begin
				if(in_valid) begin
					if(size == 2'b00&&counter<64) begin
						if(WEN_mod == j) IM_WEN[j] = 0;
						else IM_WEN[j] = 1;
					end
					else if(size == 2'b01&&counter<256) begin
						if(WEN_mod == j) IM_WEN[j] = 0;
						else IM_WEN[j] = 1;
					end
					else if(size == 2'b10&&counter<1024) begin
						if(WEN_mod == j) IM_WEN[j] = 0;
						else IM_WEN[j] = 1;
					end
					else if(size == 2'b11&&counter<4096) begin
						if(WEN_mod == j) IM_WEN[j] = 0;
						else IM_WEN[j] = 1;
					end
					else IM_WEN[j] = 1;
				end
				else IM_WEN[j] = 1;
			end
		end
	end
endgenerate
genvar i;
generate
	for(i=0;i<16;i=i+1) begin
		always@(*) begin
			if(!rst_n) WM_WEN[i] = 1;
			else begin
				if(in_valid||reg_in_valid) begin	
					if(size == 2'b00&&counter>63) begin
						if(WEN_mod == i) WM_WEN[i] = 0;
						else WM_WEN[i] = 1;
					end
					else if(size == 2'b01&&counter>255) begin
						if(WEN_mod == i) WM_WEN[i] = 0;
						else WM_WEN[i] = 1;
					end
					else if(size == 2'b10&&counter>1023) begin
						if(WEN_mod == i) WM_WEN[i] = 0;
						else WM_WEN[i] = 1;
					end
					else if(size==2'b11&&counter>4095) begin
						if(WEN_mod == i) WM_WEN[i] = 0;
						else WM_WEN[i] = 1;
					end
					else WM_WEN[i] = 1;
				end
				else WM_WEN[i] = 1;
			end
		end
	end
endgenerate

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) IM_addr <= 8'd0;
	else begin
		if(in_valid) begin
			case(size)
				2'd0: begin
					if(input_counter == 0) IM_addr <= 0;
					else if(counter_mod == 1) IM_addr <= IM_addr+1;
					else if(counter_mod == 3) IM_addr <= IM_addr+15;
					else IM_addr <= IM_addr;
				end
				2'd1: begin
					if(input_counter == 0) IM_addr <= 0;
					else if(counter_mod == 15) IM_addr <= IM_addr+13;
					else if(counter_mod%4 == 3) IM_addr <= IM_addr+1;
					else IM_addr <= IM_addr;
				end
				2'd2: begin
					if(input_counter == 0) IM_addr <= 0;
					else if(counter_mod == 63) IM_addr <= IM_addr+9;
					else if(counter_mod%8 == 7) IM_addr <= IM_addr+1;
					else if(counter_mod == 63) IM_addr <= IM_addr+9;
					else IM_addr <= IM_addr;
				end
				2'd3: begin
					if(input_counter == 0) IM_addr <= 0;
					else if(counter_mod == 255) IM_addr <= IM_addr;
					else if(counter_mod%16 == 15) IM_addr <= IM_addr+1;
					else IM_addr <= IM_addr;
				end
			endcase
		end
		else if(n_state == STATE_INDEX) begin
			case(i_mat_idx)
				4'd0:  IM_addr <= 8'd0;
				4'd1:  IM_addr <= 8'd16;
				4'd2:  IM_addr <= 8'd32;
				4'd3:  IM_addr <= 8'd48;
				4'd4:  IM_addr <= 8'd64;
				4'd5:  IM_addr <= 8'd80;
				4'd6:  IM_addr <= 8'd96;
				4'd7:  IM_addr <= 8'd112;
				4'd8:  IM_addr <= 8'd128;
				4'd9:  IM_addr <= 8'd144;
				4'd10: IM_addr <= 8'd160;
				4'd11: IM_addr <= 8'd176;
				4'd12: IM_addr <= 8'd192;
				4'd13: IM_addr <= 8'd208;
				4'd14: IM_addr <= 8'd224;
				4'd15: IM_addr <= 8'd240;
			endcase
		end
		else if(n_state == STATE_CALCU) IM_addr <= IM_addr+1;
		else if(c_state == STATE_IDLE) IM_addr <= 0;
		else IM_addr <= IM_addr;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) WM_addr <= 8'd0;
	else begin
		if(in_valid) begin
			case(size)
				2'd0: begin
					if(input_counter == 0) WM_addr <= 0;
					else if(counter_mod == 1) WM_addr <= WM_addr+1;
					else if(counter_mod == 3) WM_addr <= WM_addr+15;
					else WM_addr <= WM_addr;
				end
				2'd1: begin
					if(input_counter == 0) WM_addr <= 0;
					else if(counter_mod == 15) WM_addr <= WM_addr+13;
					else if(counter_mod %4== 3) WM_addr <= WM_addr+1;
					else WM_addr <= WM_addr;
				end
				2'd2: begin
					if(input_counter == 0) WM_addr <= 0;
					else if(counter_mod == 63) WM_addr <= WM_addr+9;
					else if(counter_mod%8 == 7) WM_addr <= WM_addr+1;
					else WM_addr <= WM_addr;
				end
				2'd3: begin
					if(input_counter == 0 && counter_mod == 0) WM_addr <= 0;
					else if(counter_mod == 255) WM_addr <= WM_addr;
					else if(counter_mod%16 == 15) WM_addr <= WM_addr+1;
					else WM_addr <= WM_addr;
				end
			endcase
		end
		else if(n_state == STATE_INDEX) begin
			case(w_mat_idx)
				4'd0:  WM_addr <= 8'd0;
				4'd1:  WM_addr <= 8'd16;
				4'd2:  WM_addr <= 8'd32;
				4'd3:  WM_addr <= 8'd48;
				4'd4:  WM_addr <= 8'd64;
				4'd5:  WM_addr <= 8'd80;
				4'd6:  WM_addr <= 8'd96;
				4'd7:  WM_addr <= 8'd112;
				4'd8:  WM_addr <= 8'd128;
				4'd9:  WM_addr <= 8'd144;
				4'd10: WM_addr <= 8'd160;
				4'd11: WM_addr <= 8'd176;
				4'd12: WM_addr <= 8'd192;
				4'd13: WM_addr <= 8'd208;
				4'd14: WM_addr <= 8'd224;
				4'd15: WM_addr <= 8'd240;
			endcase
		end
		else if(n_state == STATE_CALCU) WM_addr <= WM_addr+1;
		else if(c_state == STATE_IDLE) WM_addr <= 0;
		else WM_addr <= WM_addr;
	end
end
genvar k;
generate
	for(k=0;k<16;k=k+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) reg_weight[k] <= 0;
			else begin
				if(c_state == STATE_CALCU) begin
					case(size)
						2'b00: begin
							if(k<2) reg_weight[k] <= (calcu_counter>2)?0:(calcu_counter!=0)?WM_output[k]:0;
							else reg_weight[k] <= 0;
						end
						2'b01: begin
							if(k<4) reg_weight[k] <= (calcu_counter>4)?0:(calcu_counter!=0)?WM_output[k]:0;
							else reg_weight[k] <= 0;
						end
						2'b10: begin
							if(k<8) reg_weight[k] <= (calcu_counter>8)?0:(calcu_counter!=0)?WM_output[k]:0;
							else reg_weight[k] <= 0;
						end
						2'b11: begin
							if(k<16) reg_weight[k] <= (calcu_counter>16)?0:(calcu_counter!=0)?WM_output[k]:0;
							else reg_weight[k] <= 0;
						end
					endcase
				end
				else reg_weight[k] <= 0;
			end
		end
	end
endgenerate
genvar m;
generate
	for(m=0;m<16;m=m+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) reg_input[m] <= 0;
			else begin
				if(c_state == STATE_CALCU) begin
					case(size)
						2'b00: begin
							if(m<2) reg_input[m] <= (calcu_counter>2)?0:(calcu_counter!=0)?IM_output[m]:0;
							else reg_input[m] <= 0;
						end
						2'b01: begin
							if(m<4) reg_input[m] <= (calcu_counter>4)?0:(calcu_counter!=0)?IM_output[m]:0;
							else reg_input[m] <= 0;
						end
						2'b10: begin
							if(m<8) reg_input[m] <= (calcu_counter>8)?0:(calcu_counter!=0)?IM_output[m]:0;
							else reg_input[m] <= 0;
						end
						2'b11: begin
							if(m<16) reg_input[m] <= (calcu_counter>16)?0:(calcu_counter!=0)?IM_output[m]:0;
							else reg_input[m] <= 0;
						end
					endcase
				end
				else reg_input[m] <= 0;
			end
		end
	end
endgenerate
generate 
	for(i=0;i<16;i=i+1) begin
		always@(*) begin
			if(c_state == STATE_CALCU) begin
				if(calcu_counter==(i+2)) flag_w[i] = 1;
				else flag_w[i] = 0;
			end
			else flag_w[i] = 0;
		end
	end
endgenerate


//---------------------------------------------------------------------
//   Output block
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
	else begin
		if(size==2'b00&&(calcu_counter>4&&calcu_counter<8)) out_valid <= 1;
		else if(size==2'b01&&(calcu_counter>6&&calcu_counter<14)) out_valid <= 1;
		else if(size==2'b11&&(calcu_counter>18&&calcu_counter<50)) out_valid <= 1;
		else if(size==2'b10&&(calcu_counter>10&&calcu_counter<26)) out_valid <= 1;
		else out_valid <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_value <= 0;
	else begin
		if(size==2'b00&&(calcu_counter>4&&calcu_counter<8)) begin
			out_value <= c1_0+c1_1;
		end
		else if(size==2'b01&&(calcu_counter>6&&calcu_counter<14)) begin
			out_value <= c3_0+c3_1+c3_2+c3_3;
		end
		else if(size==2'b11&&(calcu_counter>18&&calcu_counter<50)) begin
			out_value <= c15_0+c15_1+c15_2+c15_3+c15_4+c15_5+c15_6+c15_7+c15_8+c15_9+c15_10+c15_11+c15_12+c15_13+c15_14+c15_15;
		end
		else if(size==2'b10&&(calcu_counter>10&&calcu_counter<26)) begin
			out_value <= c7_0+c7_1+c7_2+c7_3+c7_4+c7_5+c7_6+c7_7;
		end
		else out_value<= 0;
	end
end
endmodule

module PE(
//input signal
clk, rst_n, 
//use in_valid2 to reset the output
flag_reset, flag_w,
IN_A, IN_B, IN_W,
//output signal
OUT_C, OUT_D);
input wire clk, rst_n, flag_reset, flag_w;
input wire signed [15:0] IN_A, IN_W;
input wire signed [39:0] IN_B;
output reg signed [15:0] OUT_D; //pass the input signal
output reg signed [39:0] OUT_C; // store the output
reg [15:0] w;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) w<=0;
	else if(flag_reset) w<=0;
	else if(flag_w) w<=IN_W;
	else w<=w;
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) OUT_D <= 0;
	else if(flag_reset) OUT_D <= 0;
	else OUT_D <= $signed(IN_A);
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) OUT_C <= 0;
	else if(flag_reset) OUT_C <= 0;
	else OUT_C <= $signed(IN_B)+$signed(IN_A)*$signed(w);
end
endmodule
module PE0(
//input signal
clk, rst_n, 
//use in_valid2 to reset the output
flag_reset, flag_w,
IN_A, IN_W,
//output signal
OUT_C, OUT_D);
input wire clk, rst_n, flag_reset, flag_w;
input wire signed [15:0] IN_A, IN_W;
output reg signed [15:0] OUT_D; //pass the input signal
output reg signed [39:0] OUT_C; // store the output
reg [15:0] w;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) w<=0;
	else if(flag_reset) w<=0;
	else if(flag_w) w<=IN_W;
	else w<=w;
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) OUT_D <= 0;
	else if(flag_reset) OUT_D <= 0;
	else OUT_D <= $signed(IN_A);
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) OUT_C <= 0;
	else if(flag_reset) OUT_C <= 0;
	else OUT_C <= $signed(IN_A)*$signed(w);
end
endmodule