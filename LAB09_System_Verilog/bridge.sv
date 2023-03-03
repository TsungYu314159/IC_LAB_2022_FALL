module bridge(input clk, INF.bridge_inf inf);

//================================================================
// logic 
//================================================================
logic [17:0] addr;
logic [63:0] data;
//================================================================
// state 
//================================================================
typedef enum logic [2:0] {IDLE			= 3'd0,
						  R_WAIT_READY  = 3'd1,
						  R_WAIT_VALID  = 3'd2,
						  W_WAIT_READY  = 3'd3,
						  W_WAIT_VALID  = 3'd4,
						  OUT			= 3'd5
						 } STATE;
STATE n_state, c_state;
//================================================================
//   FSM
//================================================================
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) c_state <= IDLE;
	else c_state <= n_state;
end
always_comb begin
	case(c_state)
		IDLE: begin
			if(inf.C_in_valid) begin
				if(inf.C_r_wb) n_state = R_WAIT_READY;
				else n_state = W_WAIT_READY;
			end
			else n_state = IDLE;
		end
		R_WAIT_READY: begin
			if(inf.AR_READY) n_state = R_WAIT_VALID;
			else n_state = R_WAIT_READY;
		end	
		R_WAIT_VALID: begin
			if(inf.R_VALID) n_state = OUT;
			else n_state = R_WAIT_VALID;
		end
		W_WAIT_READY: begin
			if(inf.AW_READY) n_state = W_WAIT_VALID;
			else n_state = W_WAIT_READY;
		end
		W_WAIT_VALID: begin
			if(inf.B_VALID) n_state = OUT;
			else n_state = W_WAIT_VALID;
		end
		OUT: begin
			n_state = IDLE;
		end	
		default: n_state = c_state;
	endcase
end
//================================================================
//   AXI Lite
//================================================================
assign inf.B_READY  = (c_state == W_WAIT_VALID)?   1        : 0;
assign inf.AR_VALID = (c_state == R_WAIT_READY)?   1        : 0;
assign inf.AW_VALID = (c_state == W_WAIT_READY)?   1        : 0;
assign inf.AR_ADDR  = (c_state == R_WAIT_READY)?   addr     : 0;
assign inf.R_READY  = (c_state == R_WAIT_VALID)?   1        : 0;
assign inf.AW_ADDR  = (c_state == W_WAIT_READY)?   addr     : 0;
assign inf.W_VALID  = (c_state == W_WAIT_VALID)?   1        : 0;
assign inf.W_DATA   = (c_state == W_WAIT_VALID)?   data     : 0;

//================================================================
//   ADDR & DATA
//================================================================
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) addr <= 0;
	else begin
		if(inf.C_in_valid) addr <= {6'b100000, inf.C_addr, 3'b000};
		else addr <= addr;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) data <= 0;
	else begin
		if(inf.C_in_valid && inf.C_r_wb == 0) begin
			data <= inf.C_data_w;
		end
		else if(inf.R_VALID) begin
			data <= inf.R_DATA;
		end
		else data <= data;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.C_data_r <= 0;
	else begin
		if(c_state == OUT) inf.C_data_r <= data;
		else inf.C_data_r <= 0;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.C_out_valid <= 0;
	else begin
		if(c_state == OUT) inf.C_out_valid <= 1;
		else inf.C_out_valid <= 0;
	end
end
endmodule