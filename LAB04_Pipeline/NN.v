module NN(
	// Input signals
	clk,
	rst_n,
	in_valid_u,
	in_valid_w,
	in_valid_v,
	in_valid_x,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 0;

// FSM state
parameter IDLE = 0;
parameter INPUT = 1;
parameter CALCU = 2;
parameter OUTPUT = 3;
parameter ONE = 32'b00111111100000000000000000000000;
parameter ZERO = 32'b00000000000000000000000000000000;
genvar j;
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid_u, in_valid_w, in_valid_v, in_valid_x;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
// state variable
reg [1:0] c_state;
reg [1:0] n_state;

//input
reg [inst_sig_width+inst_exp_width:0] reg_x [8:0];
reg [inst_sig_width+inst_exp_width:0] reg_u [8:0];
reg [inst_sig_width+inst_exp_width:0] reg_v [8:0];
reg [inst_sig_width+inst_exp_width:0] reg_w [8:0];

//IP variable
reg [inst_sig_width+inst_exp_width:0] reg_mult1, reg_mult2, reg_mult3;
reg [inst_sig_width+inst_exp_width:0] reg_mult_x1, reg_mult_x2, reg_mult_x3;
reg [inst_sig_width+inst_exp_width:0] reg_sigmoid [3:0];
wire [inst_sig_width+inst_exp_width:0] dot_out_1;

reg [inst_sig_width+inst_exp_width:0] reg_dot_out_1, reg_dot_out_2;
wire [inst_sig_width+inst_exp_width:0] add_out_1;
wire [inst_sig_width+inst_exp_width:0] exp_out_1;
reg [inst_sig_width+inst_exp_width:0] reg_U_x_1, reg_U_x_2;

reg [inst_sig_width+inst_exp_width:0] reg_exp_out_1;
wire [inst_sig_width+inst_exp_width:0] add_out_4;
wire [inst_sig_width+inst_exp_width:0] recip_out_1;

reg [inst_sig_width+inst_exp_width:0] reg_recip_out_1, reg_recip_out_2, reg_recip_out_3;

wire [inst_sig_width+inst_exp_width:0] dot_out_19;
reg [inst_sig_width+inst_exp_width:0] reg_mult_v1, reg_mult_v2, reg_mult_v3;

reg [inst_sig_width+inst_exp_width:0] reg_out_1;
reg [inst_sig_width+inst_exp_width:0] reg_out_2;
reg [inst_sig_width+inst_exp_width:0] reg_out_3;
reg [inst_sig_width+inst_exp_width:0] reg_out_4;
reg [inst_sig_width+inst_exp_width:0] reg_out_5;
reg [inst_sig_width+inst_exp_width:0] reg_out_6;
//reg [inst_sig_width+inst_exp_width:0] reg_out_7;
//reg [inst_sig_width+inst_exp_width:0] reg_out_8;
//reg [inst_sig_width+inst_exp_width:0] reg_out_9;
reg [3:0] input_counter;
reg [4:0] calcu_counter;


//---------------------------------------------------------------------
//   FSM Block
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) c_state <= IDLE;
	else c_state <= n_state;
end
always@(*) begin
	case(c_state)
		IDLE: begin
			if(in_valid_x) n_state = INPUT;
			else n_state = IDLE;
		end
		INPUT: begin
			if(input_counter == 8) n_state = CALCU;
			else n_state = INPUT;
		end
		CALCU: begin
			if(calcu_counter == 19) n_state = OUTPUT;
			else n_state = CALCU;
		end
		OUTPUT: begin
			n_state = IDLE;
		end
	endcase
end
//---------------------------------------------------------------------
//   Input Block
//---------------------------------------------------------------------
generate
	for(j=0;j<9;j=j+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) reg_x[j] <= 0;
			else begin
				if(in_valid_x) begin
					if(input_counter==j) reg_x[j] <= data_x;
					else reg_x[j] <= reg_x[j];
				end
				else if(c_state == IDLE) reg_x[j] <= 0;
				else reg_x[j] <= reg_x[j];
			end
		end
	end
endgenerate
generate
	for(j=0;j<9;j=j+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) reg_u[j] <= 0;
			else begin
				if(in_valid_x) begin
					if(input_counter==j) reg_u[j] <= weight_u;
					else reg_u[j] <= reg_u[j];
				end
				else if(c_state == IDLE) reg_u[j] <= 0;
				else reg_u[j] <= reg_u[j];
			end
		end
	end
endgenerate
generate
	for(j=0;j<9;j=j+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) reg_v[j] <= 0;
			else begin
				if(in_valid_x) begin
					if(input_counter==j) reg_v[j] <= weight_v;
					else reg_v[j] <= reg_v[j];
				end
				else if(c_state == IDLE) reg_v[j] <= 0;
				else reg_v[j] <= reg_v[j];
			end
		end
	end
endgenerate
generate
	for(j=0;j<9;j=j+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) reg_w[j] <= 0;
			else begin
				if(in_valid_x) begin
					if(input_counter==j) reg_w[j] <= weight_w;
					else reg_w[j] <= reg_w[j];
				end
				else if(c_state == IDLE) reg_w[j] <= 0;
				else reg_w[j] <= reg_w[j];
			end
		end
	end
endgenerate
//---------------------------------------------------------------------
//   Counter Block
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_counter <= 0;
	else begin
		if(n_state == INPUT) input_counter <= input_counter + 1;
		else input_counter <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) calcu_counter <= 0;
	else begin
		if(c_state == CALCU) calcu_counter <= calcu_counter + 1;
		else calcu_counter <= 0;
	end
end

//---------------------------------------------------------------------
//   Pipeline Block
//---------------------------------------------------------------------

//-----stage 1-----
// can use combinational circuit to reduce one cycle
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_mult1 <= 0;
	else begin
		if(c_state == INPUT) begin
			case(input_counter)
				4'd3: reg_mult1 <= reg_u[0];
				4'd6: reg_mult1 <= reg_u[3];
				default: reg_mult1 <= reg_mult1;
			endcase
		end
		else if (c_state == CALCU) begin
			case(calcu_counter)
				5'd0: reg_mult1 <= reg_u[6];
				5'd1: reg_mult1 <= reg_u[0];
				5'd2: reg_mult1 <= reg_u[3];
				5'd3: reg_mult1 <= reg_w[0];
				5'd4: reg_mult1 <= reg_w[3];
				5'd5: reg_mult1 <= reg_w[6];
				5'd6: reg_mult1 <= reg_u[6];
				5'd7: reg_mult1 <= reg_u[0];
				5'd8: reg_mult1 <= reg_u[3];
				5'd9: reg_mult1 <= reg_w[0];
				5'd10: reg_mult1 <= reg_w[3];
				5'd11: reg_mult1 <= reg_w[6];
				5'd12: reg_mult1 <= reg_u[6];
				default: reg_mult1 <= reg_mult1;
			endcase
		end
		else reg_mult1 <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_mult2 <= 0;
	else begin
		if(c_state == INPUT) begin
			case(input_counter)
				4'd3: reg_mult2 <= reg_u[1];
				4'd6: reg_mult2 <= reg_u[4];
				default: reg_mult2 <= reg_mult2;
			endcase
		end
		else if (c_state == CALCU) begin
			case(calcu_counter)
				5'd0: reg_mult2 <= reg_u[7];
				5'd1: reg_mult2 <= reg_u[1];
				5'd2: reg_mult2 <= reg_u[4];
				5'd3: reg_mult2 <= reg_w[1];
				5'd4: reg_mult2 <= reg_w[4];
				5'd5: reg_mult2 <= reg_w[7];
				5'd6: reg_mult2 <= reg_u[7];
				5'd7: reg_mult2 <= reg_u[1];
				5'd8: reg_mult2 <= reg_u[4];
				5'd9: reg_mult2 <= reg_w[1];
				5'd10: reg_mult2 <= reg_w[4];
				5'd11: reg_mult2 <= reg_w[7];
				5'd12: reg_mult2 <= reg_u[7];
				default: reg_mult2 <= reg_mult2;
			endcase
		end
		else reg_mult2 <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_mult3 <= 0;
	else begin
		if(c_state == INPUT) begin
			case(input_counter)
				4'd3: reg_mult3 <= reg_u[2];
				4'd6: reg_mult3 <= reg_u[5];
				default: reg_mult3 <= reg_mult3;
			endcase
		end
		else if (c_state == CALCU) begin
			case(calcu_counter)
				5'd0: reg_mult3 <= reg_u[8];
				5'd1: reg_mult3 <= reg_u[2];
				5'd2: reg_mult3 <= reg_u[5];
				5'd3: reg_mult3 <= reg_w[2];
				5'd4: reg_mult3 <= reg_w[5];
				5'd5: reg_mult3 <= reg_w[8];
				5'd6: reg_mult3 <= reg_u[8];
				5'd7: reg_mult3 <= reg_u[2];
				5'd8: reg_mult3 <= reg_u[5];
				5'd9: reg_mult3 <= reg_w[2];
				5'd10: reg_mult3 <= reg_w[5];
				5'd11: reg_mult3 <= reg_w[8];
				5'd12: reg_mult3 <= reg_u[8];
				default: reg_mult3 <= reg_mult3;
			endcase
		end
		else reg_mult3 <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_mult_x1 <= 0;
	else begin
		if(c_state == INPUT) begin
			case(input_counter) 
				4'd3: reg_mult_x1 <= reg_x[0];
				//4'd6: reg_mult_x1 <= reg_x[0];
				default: reg_mult_x1 <= reg_mult_x1;
			endcase
		end
		else if(c_state == CALCU) begin
			case(calcu_counter)
				5'd0: reg_mult_x1 <= reg_x[0];
				5'd1: reg_mult_x1 <= reg_x[3];
				//5'd2: reg_mult_x1 <= reg_x[3];
				5'd3: reg_mult_x1 <= reg_sigmoid[0];
				//5'd4: reg_mult_x1 <= reg_sigmoid[0];
				//5'd5: reg_mult_x1 <= reg_sigmoid[0];
				5'd6: reg_mult_x1 <= reg_x[3];
				5'd7: reg_mult_x1 <= reg_x[6];
				//5'd8: reg_mult_x1 <= reg_x[6];
				5'd9: reg_mult_x1 <= reg_sigmoid[2];
				//5'd10: reg_mult_x1 <= reg_sigmoid[3];
				//5'd11: reg_mult_x1 <= reg_sigmoid[3];
				5'd12: reg_mult_x1 <= reg_x[6];
				default: reg_mult_x1 <= reg_mult_x1;
			endcase
		end
		else reg_mult_x1 <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_mult_x2 <= 0;
	else begin
		if(c_state == INPUT) begin
			case(input_counter) 
				4'd3: reg_mult_x2 <= reg_x[1];
				//4'd6: reg_mult_x2 <= reg_x[1];
				default: reg_mult_x2 <= reg_mult_x2;
			endcase
		end
		else if(c_state == CALCU) begin
			case(calcu_counter)
				5'd0: reg_mult_x2 <= reg_x[1];
				5'd1: reg_mult_x2 <= reg_x[4];
				//5'd2: reg_mult_x2 <= reg_x[4];
				5'd3: reg_mult_x2 <= reg_sigmoid[1];
				//5'd4: reg_mult_x2 <= reg_sigmoid[1];
				//5'd5: reg_mult_x2 <= reg_sigmoid[1];
				5'd6: reg_mult_x2 <= reg_x[4];
				5'd7: reg_mult_x2 <= reg_x[7];
				//5'd8: reg_mult_x2 <= reg_x[7];
				5'd9: reg_mult_x2 <= reg_sigmoid[3];
				//5'd10: reg_mult_x2 <= reg_sigmoid[4];
				//5'd11: reg_mult_x2 <= reg_sigmoid[4];
				5'd12: reg_mult_x2 <= reg_x[7];
				default: reg_mult_x2 <= reg_mult_x2;
			endcase
		end
		else reg_mult_x2 <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_mult_x3 <= 0;
	else begin
		if(c_state == INPUT) begin
			case(input_counter) 
				4'd3: reg_mult_x3 <= reg_x[2];
				//4'd6: reg_mult_x3 <= reg_x[2];
				default: reg_mult_x3 <= reg_mult_x3;
			endcase
		end
		else if(c_state == CALCU) begin
			case(calcu_counter)
				5'd0: reg_mult_x3 <= reg_x[2];
				5'd1: reg_mult_x3 <= reg_x[5];
				//5'd2: reg_mult_x3 <= reg_x[5];
				5'd3: reg_mult_x3 <= recip_out_1;
				//5'd4: reg_mult_x3 <= reg_sigmoid[2];
				//5'd5: reg_mult_x3 <= reg_sigmoid[2];
				5'd6: reg_mult_x3 <= reg_x[5];
				5'd7: reg_mult_x3 <= reg_x[8];
				//5'd8: reg_mult_x3 <= reg_x[8];
				5'd9: reg_mult_x3 <= recip_out_1;
				//5'd10: reg_mult_x3 <= reg_sigmoid[5];
				//5'd11: reg_mult_x3 <= reg_sigmoid[5];
				5'd12: reg_mult_x3 <= reg_x[8];
				default: reg_mult_x3 <= reg_mult_x3;
			endcase
		end
		else reg_mult_x3 <= 0;
	end
end
// U*x and W*h
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U1(.a(reg_mult1), .b(reg_mult_x1), .c(reg_mult2), .d(reg_mult_x2), .e(reg_mult3), .f(reg_mult_x3), .rnd(3'b000), .z(dot_out_1));
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_U_x_1 <= 0;
	else begin
		if(c_state == CALCU) begin
			if(calcu_counter == 2) reg_U_x_1 <= dot_out_1;
			else if(calcu_counter == 8) reg_U_x_1 <= dot_out_1;
			else reg_U_x_1 <= reg_U_x_1;
		end
		else reg_U_x_1 <= reg_U_x_1;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_U_x_2 <= 0;
	else begin
		if(c_state == CALCU) begin
			if(calcu_counter == 3) reg_U_x_2 <= dot_out_1;
			else if(calcu_counter == 9) reg_U_x_2 <= dot_out_1;
			else reg_U_x_2 <= reg_U_x_2;
		end
		else reg_U_x_2 <= reg_U_x_2;
	end
end
//-----stage 2-----
// (U*x+W*h) do exponential e^(-x)
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_dot_out_1 <= 0;
	else begin
		if(c_state == INPUT) begin
			case(input_counter)
				4'd4: reg_dot_out_1 <= ZERO;
				//4'd7: reg_dot_out_1 <= ZERO;
				default: reg_dot_out_1 <= reg_dot_out_1;
			endcase
		end
		else if(c_state == CALCU) begin
			case(calcu_counter) 
				5'd1: reg_dot_out_1 <= ZERO;
				//5'd2: reg_dot_out_1 <= ZERO;
				//5'd3: reg_dot_out_1 <= ZERO;
				5'd4: reg_dot_out_1 <= dot_out_1;
				5'd5: reg_dot_out_1 <= dot_out_1;
				5'd6: reg_dot_out_1 <= dot_out_1; //store W3*h1
				5'd7: reg_dot_out_1 <= reg_dot_out_1;
				5'd8: reg_dot_out_1 <= ZERO;
				//5'd9: reg_dot_out_1 <= ZERO;
				5'd10: reg_dot_out_1 <= dot_out_1;
				5'd11: reg_dot_out_1 <= dot_out_1;
				5'd12: reg_dot_out_1 <= dot_out_1; //store W3*h2
				//5'd13: reg_dot_out_1 <= reg_dot_out_1;
				default: reg_dot_out_1 <= reg_dot_out_1;
			endcase
		end
		else reg_dot_out_1 <= reg_dot_out_1;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_dot_out_2 <= 0;
	else begin
		if(c_state == INPUT) begin
			case(input_counter)
				4'd4: reg_dot_out_2 <= dot_out_1;
				4'd7: reg_dot_out_2 <= dot_out_1;
				default: reg_dot_out_2 <= reg_dot_out_2;
			endcase
		end
		else if(c_state == CALCU) begin
			case(calcu_counter) 
				5'd1: reg_dot_out_2 <= dot_out_1;
				5'd2: reg_dot_out_2 <= ZERO;
				//5'd3: reg_dot_out_2 <= ZERO;
				5'd4: reg_dot_out_2 <= reg_U_x_1;
				5'd5: reg_dot_out_2 <= reg_U_x_2;
				5'd6: reg_dot_out_2 <= ZERO;
				5'd7: reg_dot_out_2 <= dot_out_1;
				5'd8: reg_dot_out_2 <= ZERO;
				//5'd9: reg_dot_out_2 <= ZERO;
				5'd10: reg_dot_out_2 <= reg_U_x_1;
				5'd11: reg_dot_out_2 <= reg_U_x_2;
				5'd12: reg_dot_out_2 <= ZERO;
				5'd13: reg_dot_out_2 <= dot_out_1;
				default: reg_dot_out_2 <= reg_dot_out_2;
			endcase
		end
		else reg_dot_out_2 <= reg_dot_out_2;
	end
end
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U7(.a(reg_dot_out_1), .b(reg_dot_out_2), .rnd(3'b000), .z(add_out_1));
// e^(-x)
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U10(.a({!add_out_1[31], add_out_1[30:0]}), .z(exp_out_1));

//-----stage 4------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_exp_out_1 <= 0;
	else reg_exp_out_1 <= exp_out_1;
end
// 1+e^(-x)
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U13(.a(ONE), .b(reg_exp_out_1), .rnd(3'b000), .z(add_out_4));

//h=1/(1+e^(-x))
//DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U16(.a(add_out_4), .rnd(3'b000), .z(recip_out_1));
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U16(.a(ONE), .b(add_out_4), .rnd(3'b000), .z(recip_out_1));
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_sigmoid[0] <= 0;
	else begin
		if(c_state == INPUT) begin
			if(input_counter == 6) reg_sigmoid[0] <= recip_out_1;
			else reg_sigmoid[0] <= reg_sigmoid[0];
		end
		else begin
			reg_sigmoid[0] <= reg_sigmoid[0];
		end
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_sigmoid[1] <= 0;
	else begin
		if(c_state == CALCU) begin
			if(calcu_counter == 0) reg_sigmoid[1] <= recip_out_1;
			else reg_sigmoid[1] <= reg_sigmoid[1];
		end
		else begin
			reg_sigmoid[1] <= reg_sigmoid[1];
		end
	end
end
//always@(posedge clk or negedge rst_n) begin
//	if(!rst_n) reg_sigmoid[2] <= 0;
//	else begin
//		if(c_state == CALCU) begin
//			if(calcu_counter == 3) reg_sigmoid[2] <= recip_out_1;
//			else reg_sigmoid[2] <= reg_sigmoid[2];
//		end
//		else begin
//			reg_sigmoid[2] <= reg_sigmoid[2];
//		end
//	end
//end
//change 3 to 2
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_sigmoid[2] <= 0;
	else begin
		if(c_state == CALCU) begin
			if(calcu_counter == 6) reg_sigmoid[2] <= recip_out_1;
			else reg_sigmoid[2] <= reg_sigmoid[2];
		end
		else begin
			reg_sigmoid[2] <= reg_sigmoid[2];
		end
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_sigmoid[3] <= 0;
	else begin
		if(c_state == CALCU) begin
			if(calcu_counter == 7) reg_sigmoid[3] <= recip_out_1;
			else reg_sigmoid[3] <= reg_sigmoid[3];
		end
		else begin
			reg_sigmoid[3] <= reg_sigmoid[3];
		end
	end
end
//always@(posedge clk or negedge rst_n) begin
//	if(!rst_n) reg_sigmoid[5] <= 0;
//	else begin
//		if(c_state == CALCU) begin
//			if(calcu_counter == 9) reg_sigmoid[5] <= recip_out_1;
//			else reg_sigmoid[5] <= reg_sigmoid[5];
//		end
//		else begin
//			reg_sigmoid[5] <= reg_sigmoid[5];
//		end
//	end
//end
//-----stage 5-----
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_recip_out_1 <= 0;
	else begin
		if(c_state == INPUT) begin
			case(input_counter) 
				4'd6: reg_recip_out_1 <= recip_out_1;
				default: reg_recip_out_1 <= reg_recip_out_1;
			endcase
		end
		else if(c_state == CALCU) begin
			case(calcu_counter)
				5'd6: reg_recip_out_1 <= recip_out_1;
				5'd12: reg_recip_out_1 <= recip_out_1;
				default: reg_recip_out_1 <= reg_recip_out_1;
			endcase
		end
		else reg_recip_out_1 <= reg_recip_out_1;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_recip_out_2 <= 0;
	else begin
		if(c_state == CALCU) begin
			case(calcu_counter)
				5'd0: reg_recip_out_2 <= recip_out_1;
				5'd7: reg_recip_out_2 <= recip_out_1;
				5'd13: reg_recip_out_2 <= recip_out_1;
				default: reg_recip_out_2 <= reg_recip_out_2;
			endcase
		end
		else reg_recip_out_2 <= reg_recip_out_2;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_recip_out_3 <= 0;
	else begin
		if(c_state == CALCU) begin
			case(calcu_counter)
				5'd3: reg_recip_out_3 <= recip_out_1;
				5'd9: reg_recip_out_3 <= recip_out_1;
				5'd15: reg_recip_out_3 <= recip_out_1;
				default: reg_recip_out_3 <= reg_recip_out_3;
			endcase
		end
		else reg_recip_out_3 <= reg_recip_out_3;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_mult_v1 <= 0;
	else begin
		if(c_state == CALCU) begin
			case(calcu_counter) 
				5'd3: reg_mult_v1 <= reg_v[0];
				5'd4: reg_mult_v1 <= reg_v[3];
				5'd5: reg_mult_v1 <= reg_v[6];
				5'd9: reg_mult_v1 <= reg_v[0];
				5'd10: reg_mult_v1 <= reg_v[3];
				5'd11: reg_mult_v1 <= reg_v[6];
				5'd15: reg_mult_v1 <= reg_v[0];
				5'd16: reg_mult_v1 <= reg_v[3];
				5'd17: reg_mult_v1 <= reg_v[6];
				default: reg_mult_v1 <= reg_mult_v1;
			endcase
		end
		else reg_mult_v1 <= reg_mult_v1;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_mult_v2 <= 0;
	else begin
		if(c_state == CALCU) begin
			case(calcu_counter) 
				5'd3: reg_mult_v2 <= reg_v[1];
				5'd4: reg_mult_v2 <= reg_v[4];
				5'd5: reg_mult_v2 <= reg_v[7];
				5'd9: reg_mult_v2 <= reg_v[1];
				5'd10: reg_mult_v2 <= reg_v[4];
				5'd11: reg_mult_v2 <= reg_v[7];
				5'd15: reg_mult_v2 <= reg_v[1];
				5'd16: reg_mult_v2 <= reg_v[4];
				5'd17: reg_mult_v2 <= reg_v[7];
				default: reg_mult_v2 <= reg_mult_v2;
			endcase
		end
		else reg_mult_v2 <= reg_mult_v2;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_mult_v3 <= 0;
	else begin
		if(c_state == CALCU) begin
			case(calcu_counter) 
				5'd3: reg_mult_v3 <= reg_v[2];
				5'd4: reg_mult_v3 <= reg_v[5];
				5'd5: reg_mult_v3 <= reg_v[8];
				5'd9: reg_mult_v3 <= reg_v[2];
				5'd10: reg_mult_v3 <= reg_v[5];
				5'd11: reg_mult_v3 <= reg_v[8];
				5'd15: reg_mult_v3 <= reg_v[2];
				5'd16: reg_mult_v3 <= reg_v[5];
				5'd17: reg_mult_v3 <= reg_v[8];
				default: reg_mult_v3 <= reg_mult_v3;
			endcase
		end
		else reg_mult_v3 <= reg_mult_v3;
	end
end
// V*h
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U19(.a(reg_mult_v1), .b(reg_recip_out_1), .c(reg_mult_v2), .d(reg_recip_out_2), .e(reg_mult_v3), .f(reg_recip_out_3), .rnd(3'b000), .z(dot_out_19));

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_out_1 <= 0;
	else begin
		if(calcu_counter == 4) reg_out_1 <= dot_out_19;
		else reg_out_1 <= reg_out_1;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_out_2 <= 0;
	else begin
		if(calcu_counter == 5) reg_out_2 <= dot_out_19;
		else reg_out_2 <= reg_out_2;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_out_3 <= 0;
	else begin
		if(calcu_counter == 6) reg_out_3 <= dot_out_19;
		else reg_out_3 <= reg_out_3;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_out_4 <= 0;
	else begin
		if(calcu_counter == 10) reg_out_4 <= dot_out_19;
		else reg_out_4 <= reg_out_4;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_out_5 <= 0;
	else begin
		if(calcu_counter == 11) reg_out_5 <= dot_out_19;
		else reg_out_5 <= reg_out_5;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) reg_out_6 <= 0;
	else begin
		if(calcu_counter == 12) reg_out_6 <= dot_out_19;
		else reg_out_6 <= reg_out_6;
	end
end
//ys@(posedge clk or negedge rst_n) begin
//if(!rst_n) reg_out_7 <= 0;
//else begin
//	if(calcu_counter == 16) reg_out_7 <= dot_out_19;
//	else reg_out_7 <= reg_out_7;
//end
//
//ys@(posedge clk or negedge rst_n) begin
//if(!rst_n) reg_out_8 <= 0;
//else begin
//	if(calcu_counter == 17) reg_out_8 <= dot_out_19;
//	else reg_out_8 <= reg_out_8;
//end
//
//ys@(posedge clk or negedge rst_n) begin
//if(!rst_n) reg_out_9 <= 0;
//else begin
//	if(calcu_counter == 18) reg_out_9 <= dot_out_19;
//	else reg_out_9 <= reg_out_9;
//end
//
//---------------------------------------------------------------------
//   Output Block
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end
	else begin
		if(c_state == CALCU) begin
			if(calcu_counter>9&&calcu_counter<19) out_valid <= 1;
			else out_valid <= 0;
		end
		else out_valid <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out <= 0;
	end
	else begin
		if(c_state == CALCU) begin
			case(calcu_counter)
				5'd10: out <= (reg_out_1[31])?0:reg_out_1;
				5'd11: out <= (reg_out_2[31])?0:reg_out_2;
				5'd12: out <= (reg_out_3[31])?0:reg_out_3;
				5'd13: out <= (reg_out_4[31])?0:reg_out_4;
				5'd14: out <= (reg_out_5[31])?0:reg_out_5;
				5'd15: out <= (reg_out_6[31])?0:reg_out_6;
				5'd16: out <= (dot_out_19[31])?0:dot_out_19;
				5'd17: out <= (dot_out_19[31])?0:dot_out_19;
				5'd18: out <= (dot_out_19[31])?0:dot_out_19;
				default: out <= 0;
			endcase
		end
		else begin
			out <= 0;
		end
	end
end
endmodule