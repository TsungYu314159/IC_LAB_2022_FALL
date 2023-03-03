module RCL(
    clk,
    rst_n,
    in_valid,
    coef_Q,
    coef_L,
    out_valid,
    out
);
input clk , rst_n, in_valid;
input [4:0] coef_Q, coef_L;
output  reg out_valid;
output reg [1:0] out;
//`include 
reg signed [4:0] a, b, c, m, n;
reg [4:0] k;
parameter IDLE=2'd0;
parameter INPUT=2'd1;
parameter CALCU=2'd2;
parameter OUT=2'd3;

reg [1:0] c_state;
reg [1:0] n_state;
reg [1:0] input_counter;
reg [3:0] calcu_counter;

reg signed [10:0] x1, x2, x3, x4;
reg signed [12:0] k1;
reg signed [11:0] k2;
wire [11:0] root;

reg signed [23:0] i1;
reg signed [10:0] i2;
reg signed [23:0] i3;
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
			if(!in_valid) n_state = CALCU;
			else n_state = INPUT;
		end
		CALCU: begin
			if(calcu_counter ==3) n_state=OUT;
			else n_state = CALCU;
		end
		OUT: n_state = IDLE;
	endcase
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_counter <= 0;
	else begin
		if(n_state == INPUT) input_counter <= input_counter+1;
		else if(c_state == IDLE) input_counter <= 0;
		else input_counter <= input_counter;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) calcu_counter <= 0;
	else begin
		if(n_state == CALCU) calcu_counter <= calcu_counter+1;
		else if(c_state == IDLE) calcu_counter <= 0;
		else calcu_counter <= calcu_counter;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) a<=0;
	else begin
		if(n_state == INPUT) begin
			a <= (input_counter == 0)? $signed(coef_L):$signed(a);
		end
		else a<=a;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) b<=0;
	else begin
		if(c_state == INPUT) begin
			b <= (input_counter == 1)? $signed(coef_L):$signed(b);
		end
		else b<=b;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) c<=0;
	else begin
		if(c_state == INPUT) begin
			c <= (input_counter == 2)? $signed(coef_L):$signed(c);
		end
		else c<=c;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) m<=0;
	else begin
		if(n_state == INPUT) begin
			m <= (input_counter == 0)? $signed(coef_Q):$signed(m);
		end
		else m<=m;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) n<=0;
	else begin
		if(c_state == INPUT) begin
			n <= (input_counter == 1)? $signed(coef_Q):$signed(n);
		end
		else n<=n;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) k<=0;
	else begin
		if(c_state == INPUT) begin
			k <= (input_counter == 2)? coef_Q:k;
		end
		else k<=k;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) x1<=0;
	else begin
		if(n_state == CALCU) begin
			x1 <= (calcu_counter == 0)?a*m:x1;
		end
		else x1<=x1;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) x2<=0;
	else begin
		if(n_state == CALCU) begin
			x2 <= (calcu_counter == 0)?b*n:x2;
		end
		else x2<=x2;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) x3<=0;
	else begin
		if(n_state == CALCU) begin
			x3 <= (calcu_counter == 0)?a*a:x3;
		end
		else x3<=x3;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) x4<=0;
	else begin
		if(n_state == CALCU) begin
			x4 <= (calcu_counter == 0)?b*b:x4;
		end
		else x4<=x4;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) k1<=0;
	else begin
		if(c_state == CALCU) begin
			k1 <= (calcu_counter == 1)?x2+x1+c:k1;
		end
		else k1<=k1;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) k2<=0;
	else begin
		if(c_state == CALCU) begin
			k2 <= (calcu_counter == 1)?(((x3+x4)>=0)?x3+x4:(x3+x4)*(-1)):k2;
		end
		else k2<=k2;
	end
end

//DW_sqrt #(12, 0) U1 (.a(k2), .root(root));
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) i1<=0;
	else begin
		if(c_state == CALCU) begin
			i1 <= (calcu_counter == 2)?k1*k1:i1;
		end
		else i1<=i1;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) i2<=0;
	else begin
		if(c_state == CALCU) begin
			i2 <= (calcu_counter == 2)?k:i2;
		end
		else i2<=i2;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) i3<=0;
	else begin
		if(c_state == CALCU) begin
			i3 <= (calcu_counter == 3)?i2*k2:i3;
		end
		else i3<=i3;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
	else begin
		if(c_state == OUT) begin
			out_valid <= 1;
		end
		else out_valid <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out <= 0;
	else begin
		if(c_state == OUT) begin
			if(i1==i3) out <= 2'd1;
			else if(i1>i3)out <= 2'd0;
			else out<= 2'd2;
		end
		else out<=0;
	end
end













endmodule
