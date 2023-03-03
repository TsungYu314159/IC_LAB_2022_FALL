module BP(
  clk,
  rst_n,
  in_valid,
  guy,
  in0,
  in1,
  in2,
  in3,
  in4,
  in5,
  in6,
  in7,
  
  out_valid,
  out
);

input             clk, rst_n;
input             in_valid;
input       [2:0] guy;
input       [1:0] in0, in1, in2, in3, in4, in5, in6, in7;
output reg        out_valid;
output reg  [1:0] out;
//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter IDLE   = 2'b00;
parameter INPUT  = 2'b01;
parameter OUTPUT = 2'b10;


//==============================================//
//                 reg declaration              //
//==============================================//
reg [1:0] c_state;
reg [1:0] n_state;
reg [5:0] output_counter;
reg [2:0] current_position;
reg [2:0] current_position_CB;
reg [2:0] next_position;
reg [1:0] obstacle;
reg flag_OR;

reg [7:0] left_reg;
reg [7:0] right_reg;
reg [62:0] left_out_reg;
reg [62:0] right_out_reg;


//==============================================//
//        Current & Next State Block            //
//==============================================//
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) c_state <= IDLE;
	else c_state <= n_state;
end
always@(*) begin
	case(c_state)
		IDLE:   begin
			if(in_valid) n_state = INPUT;
			else n_state = IDLE;
		end
		INPUT:  begin
			if(!in_valid) n_state = OUTPUT;
			else n_state = INPUT;
		end
		OUTPUT: begin
			if(output_counter==62) n_state = IDLE;
			else n_state = OUTPUT;
		end
		default: n_state = c_state;
	endcase
end
//==============================================//
//                  Input Block                 //
//==============================================//


//==============================================//
//              Calculation Block               //
//==============================================//
always@(*) begin
	if(c_state == INPUT) begin
		if(|in0) begin
			if(~&in0) next_position = 0;
			else if(~&in1) next_position = 1;
			else if(~&in2) next_position = 2;
			else if(~&in3) next_position = 3;
			else if(~&in4) next_position = 4;
			else if(~&in5) next_position = 5;
			else if(~&in6) next_position = 6;
			else if(~&in7) next_position = 7;
			else next_position = 0;
		end
		else next_position = 0;
	end
	else next_position = 0;

end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) current_position <= 0;
	else current_position <= current_position_CB;
end
always@(*) begin
	if(c_state == INPUT) begin
		if(|in0) current_position_CB = next_position;
		else current_position_CB = current_position;
	end
	else if(c_state == IDLE) current_position_CB = guy;
	else current_position_CB = current_position;
end
always@(*) begin
	if(c_state == INPUT) begin
		obstacle[0] = &({in0[0], in1[0], in2[0], in3[0], in4[0], in5[0], in6[0], in7[0]});
		obstacle[1] = &({in0[1], in1[1], in2[1], in3[1], in4[1], in5[1], in6[1], in7[1]}); 
	end
	else begin
		obstacle[0] = 0;
		obstacle[1] = 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) flag_OR <= 0;
	else begin
		if(|in0) flag_OR <= 1;
		else flag_OR <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) left_reg <= 0;
	else begin
		if(c_state == INPUT) begin
			if(next_position<current_position) begin
				if(obstacle == 1) begin
					case(current_position-next_position)
						3'd1: left_reg <= 8'b00000011;
						3'd2: left_reg <= 8'b00000111;
						3'd3: left_reg <= 8'b00001111;
						3'd4: left_reg <= 8'b00011111;
						3'd5: left_reg <= 8'b00111111;
						3'd6: left_reg <= 8'b01111111;
						3'd7: left_reg <= 8'b11111111;
						default: left_reg  <= 8'b00000001;
					endcase
				end
				else if(obstacle == 2) begin
					case(current_position-next_position)
						3'd1: left_reg <= 8'b00000001;
						3'd2: left_reg <= 8'b00000011;
						3'd3: left_reg <= 8'b00000111;
						3'd4: left_reg <= 8'b00001111;
						3'd5: left_reg <= 8'b00011111;
						3'd6: left_reg <= 8'b00111111;
						3'd7: left_reg <= 8'b01111111;
						default: left_reg  <= 8'b00000000;
					endcase
				end
				else left_reg <= 8'b00000000;
			end
			else begin
				if(obstacle == 1)     left_reg <= 8'b00000001;
				else if(obstacle ==2) left_reg <= 8'b00000000;
			end
		end
		else if(c_state == IDLE) left_reg <= 8'b00000000;
		else left_reg <= left_reg ;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) right_reg <= 0;
	else begin
		if(c_state == INPUT) begin
			if(next_position>current_position) begin
				if(obstacle == 1) begin
					case(next_position-current_position)
						3'd1: right_reg <= 8'b00000011;
						3'd2: right_reg <= 8'b00000111;
						3'd3: right_reg <= 8'b00001111;
						3'd4: right_reg <= 8'b00011111;
						3'd5: right_reg <= 8'b00111111;
						3'd6: right_reg <= 8'b01111111;
						3'd7: right_reg <= 8'b11111111;
						default: right_reg  <= 8'b00000001;
					endcase
				end
				else if(obstacle == 2) begin
					case(next_position-current_position)
						3'd1: right_reg <= 8'b00000001;
						3'd2: right_reg <= 8'b00000011;
						3'd3: right_reg <= 8'b00000111;
						3'd4: right_reg <= 8'b00001111;
						3'd5: right_reg <= 8'b00011111;
						3'd6: right_reg <= 8'b00111111;
						3'd7: right_reg <= 8'b01111111;
						default: right_reg  <= 8'b00000000;
					endcase
				end
				else right_reg <= 8'b00000000;
			end
			else begin
				if(obstacle == 1)     right_reg <= 8'b00000001;
				else if(obstacle ==2) right_reg <= 8'b00000000;
			end
		end
		else if(c_state == IDLE) right_reg <= 8'b00000000;
		else right_reg <= right_reg;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) left_out_reg <= 0;
	else begin
		if(c_state == INPUT) begin
			if(flag_OR) begin
				left_out_reg <= {left_out_reg[61:8], left_out_reg[7:0]|left_reg}<<1;
				//if(in_valid) left_out_reg <= {left_out_reg[61:8], left_out_reg[7:0]|left_reg}<<1;
				//else left_out_reg <= {left_out_reg[62:8], left_out_reg[7:0]|left_reg}<<1;
			end
			else begin
				left_out_reg <= left_out_reg << 1;
			end
		end
		else if(c_state == IDLE) left_out_reg <= 0;
		else if(c_state == OUTPUT) left_out_reg <= left_out_reg<<1;
		else left_out_reg <= left_out_reg;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) right_out_reg <= 0;
	else begin
		if(c_state == INPUT) begin
			if(flag_OR) begin
				right_out_reg <= {right_out_reg[62:8], right_out_reg[7:0]|right_reg}<<1;
				//if(in_valid) right_out_reg <= {right_out_reg[62:8], right_out_reg[7:0]|right_reg}<<1;
				//else right_out_reg <= {right_out_reg[62:8], right_out_reg[7:0]|right_reg}<<1;
			end
			else begin
				right_out_reg <= right_out_reg << 1;
			end
		end
		else if(c_state == IDLE) right_out_reg <= 0;
		else if(c_state == OUTPUT) right_out_reg <= right_out_reg<<1;
		else right_out_reg <= right_out_reg;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) output_counter <= 0;
	else begin
		if(c_state == OUTPUT) output_counter <= output_counter+1;
		else output_counter <= 0;
	end
end
//==============================================//
//                Output Block                  //
//==============================================//
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out <=0; 
	else begin
		if(n_state == OUTPUT) begin
			out<= {left_out_reg[62], right_out_reg[62]};
		end
		else out<=0;
		
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <=0; 
	else begin
		if(n_state == OUTPUT) begin
			out_valid <= 1;
		end
		else out_valid <= 0;
	end
end
endmodule
