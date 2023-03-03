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
reg in_valid2;
reg in_valid3;
reg [13:0] num_counter;
reg signed [10:0] x1, x2, x3, x4;
reg [1:0] input_counter;
reg signed [4:0] a, b, c, m, n;
reg [4:0] k;
reg signed [23:0] k1;
reg signed [23:0] k2;
reg [1:0] output_list[3000:0];
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) input_counter <= 1;
	else begin
		if(in_valid) begin
			if(input_counter!=3) input_counter <= input_counter +1;
			else input_counter <= 1;	
		end
		else if(in_valid2) begin
			if(input_counter!=3) input_counter <= input_counter +1;
			else input_counter <= 1;
		end
		else if(in_valid3) begin
			if(input_counter!=3) input_counter <= input_counter +1;
			else input_counter <= 1;
		end
		else input_counter <= input_counter;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) num_counter <= 0;
	else begin
		if(input_counter==3) num_counter <= num_counter +1;
		else num_counter <= num_counter;	

	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) in_valid2 <=0;
	else begin
		if(in_valid) in_valid2<=1;
		else in_valid2<=0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) in_valid3 <=0;
	else begin
		if(in_valid2) in_valid3<=1;
		else in_valid3<=0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) a<=0;
	else begin
		if(in_valid)	a <= (input_counter == 1)? $signed(coef_L):$signed(a);
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) b<=0;
	else begin
		if(in_valid)	b <= (input_counter == 2)? $signed(coef_L):$signed(b);
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) c<=0;
	else begin
		if(in_valid)	c <= (input_counter == 3)? $signed(coef_L):$signed(c);
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) m<=0;
	else begin
		if(in_valid)	m <= (input_counter == 1)? $signed(coef_Q):$signed(m);
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) n<=0;
	else begin
		if(in_valid)	n <= (input_counter == 2)? $signed(coef_Q):$signed(n);
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) k<=0;
	else begin
		if(in_valid)	k <= (input_counter == 3)? coef_Q:k;
	end
end


always@(posedge clk or negedge rst_n) begin
	if(!rst_n) x1<=0;
	else begin
		x1 <= (input_counter == 2)?a*m:x1;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) x2<=0;
	else begin
		x2 <= (input_counter == 3)?b*n:x2;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) x3<=0;
	else begin
		x3 <= (input_counter == 2)?a*a:x3;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) x4<=0;
	else begin
		x4 <= (input_counter == 3)?b*b:x4;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) k1<=0;
	else begin
		k1 <= (x2+x1+c)*(x2+x1+c);
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) k2<=0;
	else begin
		k2 <= (x3+x4)*k;
	end
end





always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
	else begin
		if((input_counter==2)&&(num_counter>=1)) out_valid <= 1;
		else out_valid <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out <= 0;
	else begin
		if((input_counter==2)&&(num_counter>=1)) out<=(k1>=k2)?((k1>k2)?2'b00:2'b01):2'b10;
		else out<=0;
	end
end
endmodule
