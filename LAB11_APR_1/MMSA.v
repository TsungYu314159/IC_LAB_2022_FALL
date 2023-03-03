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
input 		 matrix;
input [1:0]  matrix_size;
input        i_mat_idx, w_mat_idx;

output reg       	     out_valid;
output reg signed [39:0] out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter STATE_IDLE   = 3'b000;
parameter STATE_INPUT  = 3'b001;
parameter STATE_INDEX  = 3'b010;
parameter STATE_CALCU  = 3'b011;
parameter STATE_WAIT   = 3'b100;
parameter STATE_INDEX2 = 3'b101;
parameter STATE_INDEX3 = 3'b110;
parameter STATE_OUT    = 3'b111;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg  [2:0]  c_state;
reg  [2:0]  n_state;
reg  [7:0]  IM_WEN;
reg  [7:0]  WM_WEN;
reg  [6:0]  IM_addr;
reg  [6:0]  WM_addr;
wire [15:0] IM_output [7:0];
wire [15:0] WM_output [7:0];

reg  	    input_data;
reg  [15:0] matrix_reg;
reg  		reg_in_valid;
reg  [3:0]  cnt;
reg  [14:0] element_cnt;
reg  [5:0]  WEN;
reg         i_mat_idx_reg, w_mat_idx_reg;
reg 		in_valid2_reg;
reg  [3:0]  i_mat_index, w_mat_index;


reg  [10:0] calcu_counter;
reg  [1:0]  size;
reg  [4:0]  output_counter;
reg  [15:0] reg_weight [7:0];
reg  [15:0] reg_input [7:0];
reg  [15:0] flag_w;
wire [5:0]  num;
reg signed [39:0] sum;
reg signed [39:0] sum_reg[14:0];
reg  [5:0] num_reg[14:0];
reg  [9:0] cycle;
reg  [5:0] sum_i_cnt;
reg  [2:0] num_i_cnt;
reg  [3:0]  sum_i;
reg  [3:0]  num_i;
reg flag1;
reg flag2;
reg  [5:0] index;


reg [15:0] input_A   [7:0];
reg [15:0] delay_A1  ;
reg [15:0] delay_A2  [1:0];
reg [15:0] delay_A3  [2:0];
reg [15:0] delay_A4  [3:0];
reg [15:0] delay_A5  [4:0];
reg [15:0] delay_A6  [5:0];
reg [15:0] delay_A7  [6:0];


wire [39:0] c0_0, c0_1, c0_2, c0_3, c0_4, c0_5, c0_6, c0_7;
wire [39:0] c1_0, c1_1, c1_2, c1_3, c1_4, c1_5, c1_6, c1_7; 
wire [39:0] c2_0, c2_1, c2_2, c2_3, c2_4, c2_5, c2_6, c2_7; 
wire [39:0] c3_0, c3_1, c3_2, c3_3, c3_4, c3_5, c3_6, c3_7; 
wire [39:0] c4_0, c4_1, c4_2, c4_3, c4_4, c4_5, c4_6, c4_7; 
wire [39:0] c5_0, c5_1, c5_2, c5_3, c5_4, c5_5, c5_6, c5_7; 
wire [39:0] c6_0, c6_1, c6_2, c6_3, c6_4, c6_5, c6_6, c6_7; 
wire [39:0] c7_0, c7_1, c7_2, c7_3, c7_4, c7_5, c7_6, c7_7; 

wire [15:0] d0_0, d0_1, d0_2, d0_3, d0_4, d0_5, d0_6, d0_7; 
wire [15:0] d1_0, d1_1, d1_2, d1_3, d1_4, d1_5, d1_6, d1_7; 
wire [15:0] d2_0, d2_1, d2_2, d2_3, d2_4, d2_5, d2_6, d2_7; 
wire [15:0] d3_0, d3_1, d3_2, d3_3, d3_4, d3_5, d3_6, d3_7; 
wire [15:0] d4_0, d4_1, d4_2, d4_3, d4_4, d4_5, d4_6, d4_7; 
wire [15:0] d5_0, d5_1, d5_2, d5_3, d5_4, d5_5, d5_6, d5_7; 
wire [15:0] d6_0, d6_1, d6_2, d6_3, d6_4, d6_5, d6_6, d6_7; 
wire [15:0] d7_0, d7_1, d7_2, d7_3, d7_4, d7_5, d7_6, d7_7; 

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
			if((size==2'b00&&element_cnt==15'd2048)||(size==2'b01&&element_cnt==15'd8192)||(size==2'b10&&element_cnt==15'd32767)) n_state = STATE_WAIT;
			else n_state = STATE_INPUT;
		end
		STATE_WAIT: begin
			if(in_valid2) n_state = STATE_INDEX2;
			else n_state = c_state;
		end
		STATE_INDEX: begin
			n_state = STATE_CALCU;
		end
		STATE_INDEX2: begin
			if(!in_valid2) n_state = STATE_INDEX3;
			else n_state = c_state;
		end
		STATE_INDEX3: begin
			n_state = STATE_INDEX;
		end
		STATE_CALCU: begin
			if(in_valid2) n_state = STATE_INDEX;
			else if((size==2'b00&&calcu_counter==8)||(size==2'b01&&calcu_counter==14)||(size==2'b10&&calcu_counter==26)) begin
				n_state = STATE_OUT;
			end
			else n_state = STATE_CALCU;
		end
		STATE_OUT: begin
			if((size == 2'b00 && calcu_counter == (9+cycle)) || (size == 2'b01 && calcu_counter == (15+cycle)) || (size == 2'b10 && calcu_counter == (27+cycle))) begin
				if(output_counter == 17) n_state = STATE_IDLE;
				else n_state = STATE_WAIT;
			end
			else n_state = c_state;
		end
		default: n_state = c_state;
	endcase
end
//---------------------------------------------------------------------
//   INPUT Block
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) size <= 0;
	else begin
		if(c_state == STATE_IDLE) begin
			if(in_valid) size <= matrix_size;
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
	if(!rst_n) cnt <= 0;
	else begin
		if(reg_in_valid) cnt <= cnt + 1;
		else cnt <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) element_cnt <= 0;
	else begin
		if(reg_in_valid) element_cnt <= element_cnt + 1;
		else element_cnt <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) matrix_reg <= 0;
	else begin
		if(reg_in_valid) begin
			if(cnt == 0) matrix_reg <= {15'd0, input_data};
			else matrix_reg <= {matrix_reg[14:0], input_data};
		end
		else matrix_reg <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) i_mat_idx_reg <= 0;
	else begin
		if(in_valid2) i_mat_idx_reg <= i_mat_idx;
		else i_mat_idx_reg <= i_mat_idx_reg;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) w_mat_idx_reg <= 0;
	else begin
		if(in_valid2) w_mat_idx_reg <= w_mat_idx;
		else w_mat_idx_reg <= w_mat_idx_reg;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) in_valid2_reg <= 0;
	else begin
		in_valid2_reg <= in_valid2;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) i_mat_index <= 0;
	else begin
		if(in_valid2_reg) i_mat_index <= {i_mat_index[2:0], i_mat_idx_reg};
		else i_mat_index <= i_mat_index;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) w_mat_index <= 0;
	else begin
		if(in_valid2_reg) w_mat_index <= {w_mat_index[2:0], w_mat_idx_reg};
		else w_mat_index <= w_mat_index;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) calcu_counter <= 0;
	else begin
		if(n_state == STATE_CALCU) begin
			if(in_valid2) calcu_counter <= 0;
			else calcu_counter <= calcu_counter +1 ;
		end
		else if(n_state == STATE_OUT) begin
			calcu_counter <= calcu_counter +1;
		end
		else calcu_counter <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) output_counter <= 1;
	else begin
		if(c_state == STATE_INDEX2) begin
			if(n_state == STATE_INDEX3) output_counter <= output_counter +1;
			else output_counter <= output_counter;
		end
		else if(c_state == STATE_IDLE) output_counter <= 1;
		else output_counter <= output_counter;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) WEN <= 0;
	else begin
		if(c_state == STATE_INPUT) begin
			case(size)
				2'b00: begin
					if(cnt == 15) begin
						if(WEN == 1) WEN <= 0;
						else WEN <= WEN + 1;
					end
				end
				2'b01: begin
					if(cnt == 15) begin
						if(WEN == 3) WEN <= 0;
						else WEN <= WEN + 1;
					end
				end
				2'b10: begin
					if(cnt == 15) begin
						if(WEN == 7) WEN <= 0;
						else WEN <= WEN + 1;
					end
				end
				default: WEN <= WEN;
			endcase
		end
		else WEN <= 0;
	end
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

//row 2
PE PE1_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(input_A[1]), .IN_B(c0_0), .IN_W(reg_weight[0]), .OUT_C(c1_0), .OUT_D(d1_0));
PE PE1_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_0), .IN_B(c0_1), .IN_W(reg_weight[1]), .OUT_C(c1_1), .OUT_D(d1_1));
PE PE1_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_1), .IN_B(c0_2), .IN_W(reg_weight[2]), .OUT_C(c1_2), .OUT_D(d1_2));
PE PE1_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_2), .IN_B(c0_3), .IN_W(reg_weight[3]), .OUT_C(c1_3), .OUT_D(d1_3));
PE PE1_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_3), .IN_B(c0_4), .IN_W(reg_weight[4]), .OUT_C(c1_4), .OUT_D(d1_4));
PE PE1_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_4), .IN_B(c0_5), .IN_W(reg_weight[5]), .OUT_C(c1_5), .OUT_D(d1_5));
PE PE1_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_5), .IN_B(c0_6), .IN_W(reg_weight[6]), .OUT_C(c1_6), .OUT_D(d1_6));
PE PE1_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[1]), .IN_A(d1_6), .IN_B(c0_7), .IN_W(reg_weight[7]), .OUT_C(c1_7), .OUT_D(d1_7));

//row 3
PE PE2_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(input_A[2]), .IN_B(c1_0), .IN_W(reg_weight[0]), .OUT_C(c2_0), .OUT_D(d2_0));
PE PE2_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_0), .IN_B(c1_1), .IN_W(reg_weight[1]), .OUT_C(c2_1), .OUT_D(d2_1));
PE PE2_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_1), .IN_B(c1_2), .IN_W(reg_weight[2]), .OUT_C(c2_2), .OUT_D(d2_2));
PE PE2_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_2), .IN_B(c1_3), .IN_W(reg_weight[3]), .OUT_C(c2_3), .OUT_D(d2_3));
PE PE2_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_3), .IN_B(c1_4), .IN_W(reg_weight[4]), .OUT_C(c2_4), .OUT_D(d2_4));
PE PE2_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_4), .IN_B(c1_5), .IN_W(reg_weight[5]), .OUT_C(c2_5), .OUT_D(d2_5));
PE PE2_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_5), .IN_B(c1_6), .IN_W(reg_weight[6]), .OUT_C(c2_6), .OUT_D(d2_6));
PE PE2_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[2]), .IN_A(d2_6), .IN_B(c1_7), .IN_W(reg_weight[7]), .OUT_C(c2_7), .OUT_D(d2_7));

//row 4
PE PE3_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(input_A[3]), .IN_B(c2_0), .IN_W(reg_weight[0]), .OUT_C(c3_0), .OUT_D(d3_0));
PE PE3_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_0), .IN_B(c2_1), .IN_W(reg_weight[1]), .OUT_C(c3_1), .OUT_D(d3_1));
PE PE3_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_1), .IN_B(c2_2), .IN_W(reg_weight[2]), .OUT_C(c3_2), .OUT_D(d3_2));
PE PE3_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_2), .IN_B(c2_3), .IN_W(reg_weight[3]), .OUT_C(c3_3), .OUT_D(d3_3));
PE PE3_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_3), .IN_B(c2_4), .IN_W(reg_weight[4]), .OUT_C(c3_4), .OUT_D(d3_4));
PE PE3_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_4), .IN_B(c2_5), .IN_W(reg_weight[5]), .OUT_C(c3_5), .OUT_D(d3_5));
PE PE3_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_5), .IN_B(c2_6), .IN_W(reg_weight[6]), .OUT_C(c3_6), .OUT_D(d3_6));
PE PE3_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[3]), .IN_A(d3_6), .IN_B(c2_7), .IN_W(reg_weight[7]), .OUT_C(c3_7), .OUT_D(d3_7));

//row 5
PE PE4_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(input_A[4]), .IN_B(c3_0), .IN_W(reg_weight[0]), .OUT_C(c4_0), .OUT_D(d4_0));
PE PE4_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_0), .IN_B(c3_1), .IN_W(reg_weight[1]), .OUT_C(c4_1), .OUT_D(d4_1));
PE PE4_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_1), .IN_B(c3_2), .IN_W(reg_weight[2]), .OUT_C(c4_2), .OUT_D(d4_2));
PE PE4_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_2), .IN_B(c3_3), .IN_W(reg_weight[3]), .OUT_C(c4_3), .OUT_D(d4_3));
PE PE4_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_3), .IN_B(c3_4), .IN_W(reg_weight[4]), .OUT_C(c4_4), .OUT_D(d4_4));
PE PE4_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_4), .IN_B(c3_5), .IN_W(reg_weight[5]), .OUT_C(c4_5), .OUT_D(d4_5));
PE PE4_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_5), .IN_B(c3_6), .IN_W(reg_weight[6]), .OUT_C(c4_6), .OUT_D(d4_6));
PE PE4_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[4]), .IN_A(d4_6), .IN_B(c3_7), .IN_W(reg_weight[7]), .OUT_C(c4_7), .OUT_D(d4_7));

// row 6
PE PE5_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(input_A[5]), .IN_B(c4_0), .IN_W(reg_weight[0]), .OUT_C(c5_0), .OUT_D(d5_0));
PE PE5_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_0), .IN_B(c4_1), .IN_W(reg_weight[1]), .OUT_C(c5_1), .OUT_D(d5_1));
PE PE5_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_1), .IN_B(c4_2), .IN_W(reg_weight[2]), .OUT_C(c5_2), .OUT_D(d5_2));
PE PE5_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_2), .IN_B(c4_3), .IN_W(reg_weight[3]), .OUT_C(c5_3), .OUT_D(d5_3));
PE PE5_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_3), .IN_B(c4_4), .IN_W(reg_weight[4]), .OUT_C(c5_4), .OUT_D(d5_4));
PE PE5_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_4), .IN_B(c4_5), .IN_W(reg_weight[5]), .OUT_C(c5_5), .OUT_D(d5_5));
PE PE5_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_5), .IN_B(c4_6), .IN_W(reg_weight[6]), .OUT_C(c5_6), .OUT_D(d5_6));
PE PE5_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[5]), .IN_A(d5_6), .IN_B(c4_7), .IN_W(reg_weight[7]), .OUT_C(c5_7), .OUT_D(d5_7));

// row 7
PE PE6_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(input_A[6]), .IN_B(c5_0), .IN_W(reg_weight[0]), .OUT_C(c6_0), .OUT_D(d6_0));
PE PE6_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_0), .IN_B(c5_1), .IN_W(reg_weight[1]), .OUT_C(c6_1), .OUT_D(d6_1));
PE PE6_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_1), .IN_B(c5_2), .IN_W(reg_weight[2]), .OUT_C(c6_2), .OUT_D(d6_2));
PE PE6_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_2), .IN_B(c5_3), .IN_W(reg_weight[3]), .OUT_C(c6_3), .OUT_D(d6_3));
PE PE6_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_3), .IN_B(c5_4), .IN_W(reg_weight[4]), .OUT_C(c6_4), .OUT_D(d6_4));
PE PE6_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_4), .IN_B(c5_5), .IN_W(reg_weight[5]), .OUT_C(c6_5), .OUT_D(d6_5));
PE PE6_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_5), .IN_B(c5_6), .IN_W(reg_weight[6]), .OUT_C(c6_6), .OUT_D(d6_6));
PE PE6_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[6]), .IN_A(d6_6), .IN_B(c5_7), .IN_W(reg_weight[7]), .OUT_C(c6_7), .OUT_D(d6_7));

// row 8
PE PE7_0 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(input_A[7]), .IN_B(c6_0), .IN_W(reg_weight[0]), .OUT_C(c7_0), .OUT_D(d7_0));
PE PE7_1 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_0), .IN_B(c6_1), .IN_W(reg_weight[1]), .OUT_C(c7_1), .OUT_D(d7_1));
PE PE7_2 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_1), .IN_B(c6_2), .IN_W(reg_weight[2]), .OUT_C(c7_2), .OUT_D(d7_2));
PE PE7_3 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_2), .IN_B(c6_3), .IN_W(reg_weight[3]), .OUT_C(c7_3), .OUT_D(d7_3));
PE PE7_4 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_3), .IN_B(c6_4), .IN_W(reg_weight[4]), .OUT_C(c7_4), .OUT_D(d7_4));
PE PE7_5 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_4), .IN_B(c6_5), .IN_W(reg_weight[5]), .OUT_C(c7_5), .OUT_D(d7_5));
PE PE7_6 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_5), .IN_B(c6_6), .IN_W(reg_weight[6]), .OUT_C(c7_6), .OUT_D(d7_6));
PE PE7_7 (.clk(clk), .rst_n(rst_n), .flag_reset(in_valid2), .flag_w(flag_w[7]), .IN_A(d7_6), .IN_B(c6_7), .IN_W(reg_weight[7]), .OUT_C(c7_7), .OUT_D(d7_7));


//---------------------------------------------------------------------
//   SRAM DESIGN
//---------------------------------------------------------------------
mem_128_16_4 Input_Mem0   (.Q(IM_output[0]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[0]), .A(IM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Input_Mem1   (.Q(IM_output[1]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[1]), .A(IM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Input_Mem2   (.Q(IM_output[2]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[2]), .A(IM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Input_Mem3   (.Q(IM_output[3]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[3]), .A(IM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Input_Mem4   (.Q(IM_output[4]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[4]), .A(IM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Input_Mem5   (.Q(IM_output[5]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[5]), .A(IM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Input_Mem6   (.Q(IM_output[6]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[6]), .A(IM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Input_Mem7   (.Q(IM_output[7]), .CLK(clk), .CEN(1'b0), .WEN(IM_WEN[7]), .A(IM_addr), .D(matrix_reg), .OEN(1'b0));

mem_128_16_4 Weight_Mem0  (.Q(WM_output[0]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[0]), .A(WM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Weight_Mem1  (.Q(WM_output[1]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[1]), .A(WM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Weight_Mem2  (.Q(WM_output[2]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[2]), .A(WM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Weight_Mem3  (.Q(WM_output[3]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[3]), .A(WM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Weight_Mem4  (.Q(WM_output[4]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[4]), .A(WM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Weight_Mem5  (.Q(WM_output[5]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[5]), .A(WM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Weight_Mem6  (.Q(WM_output[6]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[6]), .A(WM_addr), .D(matrix_reg), .OEN(1'b0));
mem_128_16_4 Weight_Mem7  (.Q(WM_output[7]), .CLK(clk), .CEN(1'b0), .WEN(WM_WEN[7]), .A(WM_addr), .D(matrix_reg), .OEN(1'b0));


genvar j;
generate
	for(j=0;j<8;j=j+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) IM_WEN[j] <= 1;
			else begin
				if(element_cnt>0) begin
					if(size == 2'b00&&element_cnt<1024) begin
						if(WEN == j && cnt == 15) IM_WEN[j] <= 0;
						else IM_WEN[j] <= 1;
					end
					else if(size == 2'b01&&element_cnt<4096) begin
						if(WEN == j && cnt == 15) IM_WEN[j] <= 0;
						else IM_WEN[j] <= 1;
					end
					else if(size == 2'b10&&element_cnt<16384) begin
						if(WEN == j && cnt == 15) IM_WEN[j] <= 0;
						else IM_WEN[j] <= 1;
					end
					else IM_WEN[j] <= 1;
				end
				else IM_WEN[j] <= 1;
			end
		end
	end
endgenerate
genvar i;
generate
	for(i=0;i<8;i=i+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) WM_WEN[i] <= 1;
			else begin
				if(reg_in_valid) begin	
					if(size == 2'b00&&element_cnt>1024) begin
						if(WEN == i && cnt == 15) WM_WEN[i] <= 0;
						else WM_WEN[i] <= 1;
					end
					else if(size == 2'b01&&element_cnt>4096) begin
						if(WEN == i && cnt == 15) WM_WEN[i] <= 0;
						else WM_WEN[i] <= 1;
					end
					else if(size == 2'b10&&element_cnt>16384) begin
						if(WEN == i && cnt == 15) WM_WEN[i] <= 0;
						else WM_WEN[i] <= 1;
					end
					else WM_WEN[i] <= 1;
				end
				else WM_WEN[i] <= 1;
			end
		end
	end
endgenerate

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) IM_addr <= 7'd0;
	else begin
		if(reg_in_valid) begin
			case(size)
				2'd0: begin
					if(element_cnt == 0) IM_addr <= 0;
					else if(element_cnt%64 == 0) IM_addr <= IM_addr+7;
					else if(element_cnt%32 == 0) IM_addr <= IM_addr+1;
					else IM_addr <= IM_addr;
				end
				2'd1: begin
					if(element_cnt == 0) IM_addr <= 0;
					else if(element_cnt%256 == 0) IM_addr <= IM_addr+5;
					else if(element_cnt%64 == 0) IM_addr  <= IM_addr+1;
					else IM_addr <= IM_addr;
				end
				2'd2: begin
					if(element_cnt == 0) IM_addr <= 0;
					else if(element_cnt%128 == 0) IM_addr <= IM_addr+1;
					else IM_addr <= IM_addr;
				end
			endcase
		end
		else if(c_state == STATE_INDEX3) begin
			case(i_mat_index)
				4'd0:  IM_addr <= 7'd0;
				4'd1:  IM_addr <= 7'd8;
				4'd2:  IM_addr <= 7'd16;
				4'd3:  IM_addr <= 7'd24;
				4'd4:  IM_addr <= 7'd32;
				4'd5:  IM_addr <= 7'd40;
				4'd6:  IM_addr <= 7'd48;
				4'd7:  IM_addr <= 7'd56;
				4'd8:  IM_addr <= 7'd64;
				4'd9:  IM_addr <= 7'd72;
				4'd10: IM_addr <= 7'd80;
				4'd11: IM_addr <= 7'd88;
				4'd12: IM_addr <= 7'd96;
				4'd13: IM_addr <= 7'd104;
				4'd14: IM_addr <= 7'd112;
				4'd15: IM_addr <= 7'd120;
			endcase
		end
		else if(n_state == STATE_CALCU) IM_addr <= IM_addr+1;
		else if(c_state == STATE_IDLE) IM_addr <= 0;
		else IM_addr <= IM_addr;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) WM_addr <= 7'd0;
	else begin
		if(reg_in_valid) begin
			case(size)
				2'd0: begin
					if(element_cnt == 1024) WM_addr <= 0;
					else if(element_cnt %64 == 0) WM_addr <= WM_addr+7;
					else if(element_cnt %32 == 0) WM_addr <= WM_addr+1;
					else WM_addr <= WM_addr;
				end
				2'd1: begin
					if(element_cnt == 4096) WM_addr <= 0;
					else if(element_cnt %256 == 0) WM_addr <= WM_addr+5;
					else if(element_cnt %64 == 0)  WM_addr <= WM_addr+1;
					else WM_addr <= WM_addr;
				end
				2'd2: begin
					if(element_cnt == 16384) WM_addr <= 0;
					else if(element_cnt%128 == 0) WM_addr <= WM_addr+1;
					else WM_addr <= WM_addr;
				end
			endcase
		end
		else if(c_state == STATE_INDEX3) begin
			case(w_mat_index)
				4'd0:  WM_addr <= 7'd0;
				4'd1:  WM_addr <= 7'd8;
				4'd2:  WM_addr <= 7'd16;
				4'd3:  WM_addr <= 7'd24;
				4'd4:  WM_addr <= 7'd32;
				4'd5:  WM_addr <= 7'd40;
				4'd6:  WM_addr <= 7'd48;
				4'd7:  WM_addr <= 7'd56;
				4'd8:  WM_addr <= 7'd64;
				4'd9:  WM_addr <= 7'd72;
				4'd10: WM_addr <= 7'd80;
				4'd11: WM_addr <= 7'd88;
				4'd12: WM_addr <= 7'd96;
				4'd13: WM_addr <= 7'd104;
				4'd14: WM_addr <= 7'd112;
				4'd15: WM_addr <= 7'd120;
			endcase
		end
		else if(n_state == STATE_CALCU) WM_addr <= WM_addr+1;
		else if(c_state == STATE_IDLE) WM_addr <= 0;
		else WM_addr <= WM_addr;
	end
end
genvar k;
generate
	for(k=0;k<8;k=k+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) reg_weight[k] <= 0;
			else begin
				if(c_state == STATE_CALCU) begin
					case(size)
						2'b00: begin
							if(k<2) reg_weight[k] <= (calcu_counter>2)?0:WM_output[k];
							else reg_weight[k] <= 0;
						end
						2'b01: begin
							if(k<4) reg_weight[k] <= (calcu_counter>4)?0:WM_output[k];
							else reg_weight[k] <= 0;
						end
						2'b10: begin
							if(k<8) reg_weight[k] <= (calcu_counter>8)?0:WM_output[k];
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
	for(m=0;m<8;m=m+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) reg_input[m] <= 0;
			else begin
				if(c_state == STATE_CALCU) begin
					case(size)
						2'b00: begin
							if(m<2) reg_input[m] <= (calcu_counter>2)?0:IM_output[m];
							else reg_input[m] <= 0;
						end
						2'b01: begin
							if(m<4) reg_input[m] <= (calcu_counter>4)?0:IM_output[m];
							else reg_input[m] <= 0;
						end
						2'b10: begin
							if(m<8) reg_input[m] <= (calcu_counter>8)?0:IM_output[m];
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
		if(c_state == STATE_OUT) begin
			if(size == 2'b10) out_valid <= (calcu_counter>27)? 1 : 0;  //1
			else if(size == 2'b01) out_valid <= (calcu_counter>15)? 1: 0;
			else out_valid <= (calcu_counter>9)? 1:0;
		end
		else out_valid <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_value <= 0;
	else begin
		if(c_state == STATE_OUT) begin
			if(size == 2'b00) begin
				if(calcu_counter < 10) out_value <= 0;
				else if(flag2) out_value <= num_reg[sum_i][num_i_cnt];
				else out_value <= sum_reg[sum_i][sum_i_cnt];
			end
			else if(size == 2'b01) begin
				if(calcu_counter < 16) out_value <= 0;
				else if(flag2) out_value <= num_reg[sum_i][num_i_cnt];
				else out_value <= sum_reg[sum_i][sum_i_cnt];
			end
			else begin
				if(calcu_counter < 28) out_value <= 0;
				else if(flag2) out_value <= num_reg[sum_i][num_i_cnt];
				else out_value <= sum_reg[sum_i][sum_i_cnt];
			end
		end
		else out_value <= 0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) sum_i <= 0;
	else begin
		if(c_state == STATE_OUT) begin
			if(size == 2'b10) begin
				if(calcu_counter < 29) sum_i <= 0; //14;
				else if(num_i_cnt == 0) begin
					if(sum_i_cnt == 0) sum_i <= sum_i + 1;//- 1;
					else sum_i <= sum_i;
				end
			end
			else if(size == 2'b01) begin
				if(calcu_counter <17) sum_i <= 0; //6;
				else if(num_i_cnt == 0) begin
					if(sum_i_cnt == 0) sum_i <= sum_i + 1;//- 1;
					else sum_i <= sum_i;
				end
			end
			else begin
				if(calcu_counter <11) sum_i <= 0; //2;
				else if(num_i_cnt == 0) begin
					if(sum_i_cnt == 0) sum_i <= sum_i + 1;//- 1;
					else sum_i <= sum_i;
				end
			end
		end
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) num_i_cnt <= 0;
	else begin
		if(c_state == STATE_OUT) begin
			if(size == 2'b10) begin
				if(calcu_counter == 27) num_i_cnt <= 5;
				else if(calcu_counter > 27) begin
					if(sum_i_cnt == 0 ) begin
						if(num_i_cnt == 0) num_i_cnt <= 5;
						else num_i_cnt <= num_i_cnt - 1;
					end
					else if(num_i_cnt == 0) num_i_cnt <= num_i_cnt;
					else num_i_cnt <= num_i_cnt - 1;
				end
			end
			else if(size == 2'b01) begin
				if(calcu_counter == 15) num_i_cnt <= 5;
				else if(calcu_counter > 15) begin
					if(sum_i_cnt == 0 ) begin
						if(num_i_cnt == 0) num_i_cnt <= 5;
						else num_i_cnt <= num_i_cnt - 1;
					end
					else if(num_i_cnt == 0) num_i_cnt <= num_i_cnt;
					else num_i_cnt <= num_i_cnt - 1;
				end
			end
			else begin
				if(calcu_counter == 9) num_i_cnt <= 5;
				else if(calcu_counter > 9) begin
					if(sum_i_cnt == 0 ) begin
						if(num_i_cnt == 0) num_i_cnt <= 5;
						else num_i_cnt <= num_i_cnt - 1;
					end
					else if(num_i_cnt == 0) num_i_cnt <= num_i_cnt;
					else num_i_cnt <= num_i_cnt - 1;
				end
			end
		end
	
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) sum_i_cnt <= 0;
	else begin
		if(c_state == STATE_OUT) begin
			if(size == 2'b10) begin
				if(calcu_counter == 27) sum_i_cnt <= 63;
				else if(calcu_counter > 27) begin
					if(num_i_cnt == 0) begin
						if(flag1) sum_i_cnt <= num_reg[sum_i]-1;
						else sum_i_cnt <= sum_i_cnt - 1;
					end
					else sum_i_cnt <= sum_i_cnt;
				end
			end
			else if(size == 2'b01) begin
				if(calcu_counter == 15) sum_i_cnt <= 63;
				else if(calcu_counter > 15) begin
					if(num_i_cnt == 0) begin
						if(flag1) sum_i_cnt <= num_reg[sum_i]-1;
						else sum_i_cnt <= sum_i_cnt - 1;
					end
					else sum_i_cnt <= sum_i_cnt;
				end
			end
			else begin
				if(calcu_counter == 9) sum_i_cnt <= 63;
				else if(calcu_counter > 9) begin
					if(num_i_cnt == 0) begin
						if(flag1) sum_i_cnt <= num_reg[sum_i]-1;
						else sum_i_cnt <= sum_i_cnt - 1;
					end
					else sum_i_cnt <= sum_i_cnt;
				end
			end
		end
	
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) flag1 <= 0;
	else begin
		if(c_state == STATE_OUT) begin
			if(num_i_cnt == 1) flag1 <= 1;
			else flag1 <= 0;
		end
	end
end
always@(*) begin
	if(c_state == STATE_OUT) begin
		if(num_i_cnt > 0 || flag1) flag2 = 1;
		else flag2 = 0;
	end
	else flag2 = 0;
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) cycle <= 0;
	else begin
		if(c_state == STATE_CALCU) begin
			case(size)
				2'b00: begin
					if(calcu_counter == 6) cycle <= num + 18;
					else cycle <= cycle + num;
				end
				2'b01: begin
					if(calcu_counter == 8) cycle <= num + 42;
					else cycle <= cycle + num;
				end
				default: begin
					if(calcu_counter == 12) cycle <= num + 90;
					else cycle <= cycle + num;
				end			
			endcase		
		end
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) sum <= 0;
	else begin
		if(size==2'b00&&(calcu_counter>4&&calcu_counter<8)) begin
			sum <= c1_0+c1_1;
		end
		else if(size==2'b01&&(calcu_counter>6&&calcu_counter<14)) begin
			sum <= c3_0+c3_1+c3_2+c3_3;
		end
		else if(size==2'b10&&(calcu_counter>10&&calcu_counter<26)) begin
			sum <= c7_0+c7_1+c7_2+c7_3+c7_4+c7_5+c7_6+c7_7;
		end
		else sum<= 0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) sum_reg[0] <= 0;
	else begin
		if(size==2'b00&&(calcu_counter==6)) begin
			sum_reg[0] <= sum;
		end
		else if(size==2'b01&&(calcu_counter==8)) begin
			sum_reg[0] <= sum;
		end
		else if(size==2'b10&&(calcu_counter==12)) begin
			sum_reg[0] <= sum;
		end
		else if(c_state == STATE_IDLE) sum_reg[0]<= 0;
		else sum_reg[0]<= sum_reg[0];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) sum_reg[1] <= 0;
	else begin
		if(size==2'b00&&(calcu_counter==7)) begin
			sum_reg[1] <= sum;
		end
		else if(size==2'b01&&(calcu_counter==9)) begin
			sum_reg[1] <= sum;
		end
		else if(size==2'b10&&(calcu_counter==13)) begin
			sum_reg[1] <= sum;
		end
		else if(c_state == STATE_IDLE) sum_reg[1]<= 0;
		else sum_reg[1]<= sum_reg[1];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) sum_reg[2] <= 0;
	else begin
		if(size==2'b00&&(calcu_counter==8)) begin
			sum_reg[2] <= sum;
		end
		else if(size==2'b01&&(calcu_counter==10)) begin
			sum_reg[2] <= sum;
		end
		else if(size==2'b10&&(calcu_counter==14)) begin
			sum_reg[2] <= sum;
		end
		else if(c_state == STATE_IDLE) sum_reg[2]<= 0;
		else sum_reg[2]<= sum_reg[2];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) sum_reg[3] <= 0;
	else begin
		if(size==2'b01&&(calcu_counter==11)) begin
			sum_reg[3] <= sum;
		end
		else if(size==2'b10&&(calcu_counter==15)) begin
			sum_reg[3] <= sum;
		end
		else if(c_state == STATE_IDLE) sum_reg[3]<= 0;
		else sum_reg[3]<= sum_reg[3];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) sum_reg[4] <= 0;
	else begin
		if(size==2'b01&&(calcu_counter==12)) begin
			sum_reg[4] <= sum;
		end
		else if(size==2'b10&&(calcu_counter==16)) begin
			sum_reg[4] <= sum;
		end
		else if(c_state == STATE_IDLE) sum_reg[4]<= 0;
		else sum_reg[4]<= sum_reg[4];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) sum_reg[5] <= 0;
	else begin
		if(size==2'b01&&(calcu_counter==13)) begin
			sum_reg[5] <= sum;
		end
		else if(size==2'b10&&(calcu_counter==17)) begin
			sum_reg[5] <= sum;
		end
		else if(c_state == STATE_IDLE) sum_reg[5]<= 0;
		else sum_reg[5]<= sum_reg[5];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) sum_reg[6] <= 0;
	else begin
		if(size==2'b01&&(calcu_counter==14)) begin
			sum_reg[6] <= sum;
		end
		else if(size==2'b10&&(calcu_counter==18)) begin
			sum_reg[6] <= sum;
		end
		else if(c_state == STATE_IDLE) sum_reg[6]<= 0;
		else sum_reg[6]<= sum_reg[6];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) sum_reg[7] <= 0;
	else begin
		if(size==2'b10&&(calcu_counter==19)) begin
			sum_reg[7] <= sum;
		end
		else if(c_state == STATE_IDLE) sum_reg[7]<= 0;
		else sum_reg[7]<= sum_reg[7];
	end
end
genvar n;
generate
	for(n=8;n<15;n=n+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) sum_reg[n] <= 0;
			else begin
				if(size==2'b10&&(calcu_counter==(12+n))) begin
					sum_reg[n] <= sum;
				end
				else if(size == 2'b00 || size == 2'b01) sum_reg[n]<= 0;
				else if(c_state == STATE_IDLE) sum_reg[n]<= 0;
				else sum_reg[n]<= sum_reg[n];
			end
		end
	end
endgenerate
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) num_reg[0] <= 0;
	else begin
		if(size==2'b00&&(calcu_counter==6)) begin
			num_reg[0] <= num;
		end
		else if(size==2'b01&&(calcu_counter==8)) begin
			num_reg[0] <= num;
		end
		else if(size==2'b10&&(calcu_counter==12)) begin
			num_reg[0] <= num;
		end
		else if(c_state == STATE_IDLE) num_reg[0]<= 0;
		else num_reg[0]<= num_reg[0];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) num_reg[1] <= 0;
	else begin
		if(size==2'b00&&(calcu_counter==7)) begin
			num_reg[1] <= num;
		end
		else if(size==2'b01&&(calcu_counter==9)) begin
			num_reg[1] <= num;
		end
		else if(size==2'b10&&(calcu_counter==13)) begin
			num_reg[1] <= num;
		end
		else if(c_state == STATE_IDLE) num_reg[1]<= 0;
		else num_reg[1]<= num_reg[1];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) num_reg[2] <= 0;
	else begin
		if(size==2'b00&&(calcu_counter==8)) begin
			num_reg[2] <= num;
		end
		else if(size==2'b01&&(calcu_counter==10)) begin
			num_reg[2] <= num;
		end
		else if(size==2'b10&&(calcu_counter==14)) begin
			num_reg[2] <= num;
		end
		else if(c_state == STATE_IDLE) num_reg[2]<= 0;
		else num_reg[2]<= num_reg[2];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) num_reg[3] <= 0;
	else begin
		if(size==2'b01&&(calcu_counter==11)) begin
			num_reg[3] <= num;
		end
		else if(size==2'b10&&(calcu_counter==15)) begin
			num_reg[3] <= num;
		end
		else if(c_state == STATE_IDLE) num_reg[3]<= 0;
		else num_reg[3]<= num_reg[3];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) num_reg[4] <= 0;
	else begin
		if(size==2'b01&&(calcu_counter==12)) begin
			num_reg[4] <= num;
		end
		else if(size==2'b10&&(calcu_counter==16)) begin
			num_reg[4] <= num;
		end
		else if(c_state == STATE_IDLE) num_reg[4]<= 0;
		else num_reg[4]<= num_reg[4];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) num_reg[5] <= 0;
	else begin
		if(size==2'b01&&(calcu_counter==13)) begin
			num_reg[5] <= num;
		end
		else if(size==2'b10&&(calcu_counter==17)) begin
			num_reg[5] <= num;
		end
		else if(c_state == STATE_IDLE) num_reg[5]<= 0;
		else num_reg[5]<= num_reg[5];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) num_reg[6] <= 0;
	else begin
		if(size==2'b01&&(calcu_counter==14)) begin
			num_reg[6] <= num;
		end
		else if(size==2'b10&&(calcu_counter==18)) begin
			num_reg[6] <= num;
		end
		else if(c_state == STATE_IDLE) num_reg[6]<= 0;
		else num_reg[6]<= num_reg[6];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) num_reg[7] <= 0;
	else begin
		if(size==2'b10&&(calcu_counter==19)) begin
			num_reg[7] <= num;
		end
		else if(c_state == STATE_IDLE) num_reg[7]<= 0;
		else num_reg[7]<= num_reg[7];
	end
end
generate
	for(n=8;n<15;n=n+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) num_reg[n] <= 0;
			else begin
				if(size==2'b10&&(calcu_counter==(12+n))) begin
					num_reg[n] <= num;
				end
				else if(size == 2'b00 || size == 2'b01) num_reg[n]<= 0;
				else if(c_state == STATE_IDLE) num_reg[n]<= 0;
				else num_reg[n]<= num_reg[n];
			end
		end
	end
endgenerate
select_bit_num S1(.signal(sum), .num(num));

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


module select_bit_num(
	// input port
	signal,
	//output port
	num
	);
	input      [39:0] signal;
	output reg [5:0]  num;
	
	always@(*) begin
		if     (signal[39] | signal[38] | signal[37] | signal[36] | signal[35]) begin
			case(signal[39:35]) 
				5'b00000  : num = 35;
				5'b00001  : num = 36;
				5'b00010  : num = 37;
				5'b00011  : num = 37;
				5'b00100  : num = 38;
				5'b00101  : num = 38;
				5'b00110  : num = 38;
				5'b00111  : num = 38;
				5'b01000  : num = 39;
				5'b01001  : num = 39;
				5'b01010  : num = 39;
				5'b01011  : num = 39;
				5'b01100  : num = 39;
				5'b01101  : num = 39;
				5'b01110  : num = 39;
				5'b01111  : num = 39;
				default   : num = 40;
			endcase
		end
		else if(signal[34] | signal[33] | signal[32] | signal[31] | signal[30]) begin
			case(signal[34:30]) 
				5'b00000  : num = 30;
				5'b00001  : num = 31;
				5'b00010  : num = 32;
				5'b00011  : num = 32;
				5'b00100  : num = 33;
				5'b00101  : num = 33;
				5'b00110  : num = 33;
				5'b00111  : num = 33;
				5'b01000  : num = 34;
				5'b01001  : num = 34;
				5'b01010  : num = 34;
				5'b01011  : num = 34;
				5'b01100  : num = 34;
				5'b01101  : num = 34;
				5'b01110  : num = 34;
				5'b01111  : num = 34;
				default   : num = 35;
			endcase
		end
		else if(signal[29] | signal[28] | signal[27] | signal[26] | signal[25]) begin
			case(signal[29:25]) 
				5'b00000  : num = 25;
				5'b00001  : num = 26;
				5'b00010  : num = 27;
				5'b00011  : num = 27;
				5'b00100  : num = 28;
				5'b00101  : num = 28;
				5'b00110  : num = 28;
				5'b00111  : num = 28;
				5'b01000  : num = 29;
				5'b01001  : num = 29;
				5'b01010  : num = 29;
				5'b01011  : num = 29;
				5'b01100  : num = 29;
				5'b01101  : num = 29;
				5'b01110  : num = 29;
				5'b01111  : num = 29;
				default   : num = 30;
			endcase
		end
		else if(signal[24] | signal[23] | signal[22] | signal[21] | signal[20]) begin
			case(signal[24:20]) 
				5'b00000  : num = 20;
				5'b00001  : num = 21;
				5'b00010  : num = 22;
				5'b00011  : num = 22;
				5'b00100  : num = 23;
				5'b00101  : num = 23;
				5'b00110  : num = 23;
				5'b00111  : num = 23;
				5'b01000  : num = 24;
				5'b01001  : num = 24;
				5'b01010  : num = 24;
				5'b01011  : num = 24;
				5'b01100  : num = 24;
				5'b01101  : num = 24;
				5'b01110  : num = 24;
				5'b01111  : num = 24;
				default   : num = 25;
			endcase
		end
		else if(signal[19] | signal[18] | signal[17] | signal[16] | signal[15]) begin
			case(signal[19:15]) 
				5'b00000  : num = 15;
				5'b00001  : num = 16;
				5'b00010  : num = 17;
				5'b00011  : num = 17;
				5'b00100  : num = 18;
				5'b00101  : num = 18;
				5'b00110  : num = 18;
				5'b00111  : num = 18;
				5'b01000  : num = 19;
				5'b01001  : num = 19;
				5'b01010  : num = 19;
				5'b01011  : num = 19;
				5'b01100  : num = 19;
				5'b01101  : num = 19;
				5'b01110  : num = 19;
				5'b01111  : num = 19;
				default   : num = 20;
			endcase
		end
		else if(signal[14] | signal[13] | signal[12] | signal[11] | signal[10]) begin
			case(signal[14:10]) 
				5'b00000  : num = 10;
				5'b00001  : num = 11;
				5'b00010  : num = 12;
				5'b00011  : num = 12;
				5'b00100  : num = 13;
				5'b00101  : num = 13;
				5'b00110  : num = 13;
				5'b00111  : num = 13;
				5'b01000  : num = 14;
				5'b01001  : num = 14;
				5'b01010  : num = 14;
				5'b01011  : num = 14;
				5'b01100  : num = 14;
				5'b01101  : num = 14;
				5'b01110  : num = 14;
				5'b01111  : num = 14;
				default   : num = 15;
			endcase
		end
		else if(signal[9] | signal[8] | signal[7] | signal[6] | signal[5]) begin
			case(signal[9:5]) 
				5'b00000  : num = 5;
				5'b00001  : num = 6;
				5'b00010  : num = 7;
				5'b00011  : num = 7;
				5'b00100  : num = 8;
				5'b00101  : num = 8;
				5'b00110  : num = 8;
				5'b00111  : num = 8;
				5'b01000  : num = 9;
				5'b01001  : num = 9;
				5'b01010  : num = 9;
				5'b01011  : num = 9;
				5'b01100  : num = 9;
				5'b01101  : num = 9;
				5'b01110  : num = 9;
				5'b01111  : num = 9;
				default   : num = 10;
			endcase
		end
		else begin
			case(signal[4:0]) 
				5'b00000  : num = 1;
				5'b00001  : num = 1;
				5'b00010  : num = 2;
				5'b00011  : num = 2;
				5'b00100  : num = 3;
				5'b00101  : num = 3;
				5'b00110  : num = 3;
				5'b00111  : num = 3;
				5'b01000  : num = 4;
				5'b01001  : num = 4;
				5'b01010  : num = 4;
				5'b01011  : num = 4;
				5'b01100  : num = 4;
				5'b01101  : num = 4;
				5'b01110  : num = 4;
				5'b01111  : num = 4;
				default   : num = 5;
			endcase
		end
	end
endmodule