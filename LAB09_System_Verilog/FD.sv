module FD(input clk, INF.FD_inf inf);
import usertype::*;

//===========================================================================
// parameter 
//===========================================================================


//===========================================================================
// logic 
//===========================================================================
typedef enum logic [3:0] { STATE_IDLE    = 4'd0,
						   STATE_ACT     = 4'd1,
						   STATE_ID      = 4'd2,
						   STATE_CUS     = 4'd3,
						   STATE_FOOD    = 4'd4,
						   STATE_RES     = 4'd5,
						   STATE_d_id    = 4'd6,
						   STATE_res_id  = 4'd7,
						   STATE_d_WAIT  = 4'd8,
						   STATE_res_WAIT= 4'd9,
						   STATE_wr_WAIT = 4'd10,
						   STATE_OUT     = 4'd11,
						   STATE_WRITE   = 4'd12,
						   STATE_EXE     = 4'd13
						  } STATE;

					
STATE 				c_state, n_state;
Action 				action;
Delivery_man_id     d_man_id;
D_man_Info          d_man_infomation;
Restaurant_id       res_id;
res_info			res_infomation;
Ctm_Info			cus_info;
food_ID_servings	food_info;

bit 				flag_cancel;
bit					flag_ID;
bit					flag_CUS;
bit					flag_FOOD;
bit					flag_d_id;
bit					flag_res_id;
bit 				flag_RES;
bit 				flag_addr_jump;
logic [1:0]			write_counter;
logic [7:0]  		addr_d;
logic [7:0]			addr_res;
logic [63:0]    	d_man_data;
logic [63:0] 		res_data;
//===========================================================================
// FSM
//===========================================================================
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) c_state <= STATE_IDLE;
	else c_state <= n_state;
end
always_comb begin
	case(c_state) 
		STATE_IDLE: begin
											n_state = (inf.act_valid)? STATE_ACT : STATE_IDLE;
		end
		STATE_ACT: begin
			case(action) 
				No_action: begin
											n_state = c_state;
				end
				Take: begin
					if(inf.id_valid) 		n_state = STATE_ID;
					else if(inf.cus_valid)  n_state = STATE_CUS;
					else 					n_state = c_state;
				end
				Deliver: begin
					if(inf.id_valid)		n_state = STATE_ID;
					else 					n_state = c_state;
				end
				Order: begin
					if(inf.res_valid) 		n_state = STATE_RES;
					else if(inf.food_valid) n_state = STATE_FOOD;
					else 					n_state = c_state;
				end
				Cancel: begin
											n_state = STATE_RES;
				end
				default: 					n_state = c_state;
			endcase
		end
		STATE_ID: begin
			case(action)
				Take: begin
					n_state = (flag_ID)? 
							  ((flag_addr_jump)? (flag_d_id)? STATE_WRITE : STATE_d_id : STATE_d_id) 
							  : c_state;
				end
				Deliver: begin
					n_state = (flag_addr_jump)? (flag_d_id)? STATE_WRITE : STATE_d_id : STATE_d_id;
				end
				Cancel : begin
					n_state = (flag_addr_jump)? (flag_d_id)? STATE_WRITE : STATE_d_id : STATE_d_id;
				end
				default: n_state = c_state;
			endcase
		end
		STATE_CUS: begin
											n_state = (flag_ID)?
													  (flag_addr_jump)? (flag_res_id)? STATE_WRITE : STATE_res_id : STATE_res_id  :
													  STATE_WRITE;
		end
		STATE_FOOD: begin///////
				if(action == Cancel)		n_state = (flag_ID)? STATE_ID  : c_state;
				else begin
					if(flag_FOOD) 			n_state = (write_counter==1)? STATE_res_id : (flag_addr_jump)? STATE_EXE : STATE_res_id;
					else 					n_state = STATE_FOOD;
				end
		end
		STATE_RES: begin//////////
			if(flag_RES)					n_state = (flag_addr_jump)? (action == Cancel)? STATE_FOOD: (flag_res_id)? STATE_WRITE : STATE_FOOD : (flag_FOOD)? STATE_FOOD : c_state;
			else 							n_state = c_state;
		end
		STATE_d_id: begin
											n_state = STATE_d_WAIT;
		end
		STATE_res_id: begin
											n_state = STATE_res_WAIT;
		end
		STATE_WRITE: begin
											n_state = STATE_wr_WAIT;
		end
		STATE_d_WAIT: begin
			if(inf.C_out_valid) begin
											n_state = (action == Deliver)? STATE_EXE : (action == Take)? STATE_CUS : STATE_EXE;
			end
			else 							n_state = c_state;
		end
		STATE_res_WAIT: begin
			if(inf.C_out_valid) begin
				n_state = STATE_EXE;
			end
			else n_state = c_state;
		end
		STATE_wr_WAIT: begin
			if(inf.C_out_valid) begin
				case(action)
					Take: begin
											n_state = (flag_ID)? (write_counter == 1)? STATE_d_id : STATE_res_id : STATE_res_id ;
					end
					Deliver: begin
											n_state = STATE_d_id;
					end
					Order: begin
											n_state = STATE_FOOD;
					end
					Cancel: begin
						if(flag_ID)			n_state = STATE_d_id;
						else 				n_state = STATE_FOOD;
					end
					default: 				n_state = c_state;
				endcase
			end
			else 							n_state = c_state;
		end
		STATE_EXE: begin
											n_state = STATE_OUT;
		end
		STATE_OUT: begin
											n_state = STATE_IDLE;
		end
		default: 							n_state = c_state;
	endcase
end
//===========================================================================
// Design
//===========================================================================
//-------------input------------------------------------
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) action <= No_action;
	else begin
		if(inf.act_valid) action <= inf.D.d_act[0];
		else action <= action;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) d_man_id <= 0;
	else begin
		if(inf.id_valid) begin
			d_man_id <= inf.D.d_id[0];
		end
		else d_man_id <= d_man_id;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) res_id <= 0;
	else begin
		if(inf.res_valid) res_id <= inf.D.d_res_id[0];
		else if(c_state == STATE_d_id) begin
			if(action == Cancel || action == Deliver) res_id <= res_id;
			else res_id <= cus_info.res_ID;
		end
		else if(c_state == STATE_CUS)  res_id <= cus_info.res_ID;
		else res_id <= res_id;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) cus_info <= 0;
	else begin
		if(inf.cus_valid) cus_info <= inf.D.d_ctm_info[0];
		else cus_info <= cus_info;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) food_info <= 0;
	else begin
		if(inf.food_valid) food_info <= inf.D.d_food_ID_ser[0];
		else food_info <= food_info;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) d_man_infomation <= 0;
	else begin
		if(c_state == STATE_d_WAIT) d_man_infomation <= (inf.C_out_valid)? {inf.C_data_r[39:38], inf.C_data_r[37:32], inf.C_data_r[47:40], inf.C_data_r[55:54], inf.C_data_r[53:48], inf.C_data_r[63:56]} : d_man_infomation;
		else if(c_state == STATE_EXE) begin
			case(action) 
				Take: begin
					if(d_man_infomation.ctm_info1.ctm_status != None && d_man_infomation.ctm_info2.ctm_status != None) begin
						d_man_infomation <= d_man_infomation;
					end
					else begin
						case(cus_info.food_ID)
							FOOD1: begin
								if(res_infomation.ser_FOOD1 < cus_info.ser_food) d_man_infomation <= d_man_infomation;
								else begin
									if(d_man_infomation.ctm_info1.ctm_status != None) begin
										if(d_man_infomation.ctm_info1.ctm_status == VIP) d_man_infomation <= {d_man_infomation.ctm_info1, cus_info};
										else if(cus_info.ctm_status == VIP) d_man_infomation <= {cus_info, d_man_infomation.ctm_info1};
										else d_man_infomation <= {d_man_infomation.ctm_info1, cus_info};
									end
									else d_man_infomation <= {cus_info, 16'd0};
								end
							end
							FOOD2: begin
								if(res_infomation.ser_FOOD2 < cus_info.ser_food) d_man_infomation <= d_man_infomation;
								else begin
									if(d_man_infomation.ctm_info1.ctm_status != None) begin
										if(d_man_infomation.ctm_info1.ctm_status == VIP) d_man_infomation <= {d_man_infomation.ctm_info1, cus_info};
										else if(cus_info.ctm_status == VIP) d_man_infomation <= {cus_info, d_man_infomation.ctm_info1};
										else d_man_infomation <= {d_man_infomation.ctm_info1, cus_info};
									end
									else d_man_infomation <= {cus_info, 16'd0};
								end
							end
							FOOD3: begin
								if(res_infomation.ser_FOOD3 < cus_info.ser_food) d_man_infomation <= d_man_infomation;
								else begin
									if(d_man_infomation.ctm_info1.ctm_status != None) begin
										if(d_man_infomation.ctm_info1.ctm_status == VIP) d_man_infomation <= {d_man_infomation.ctm_info1, cus_info};
										else if(cus_info.ctm_status == VIP) d_man_infomation <= {cus_info, d_man_infomation.ctm_info1};
										else d_man_infomation <= {d_man_infomation.ctm_info1, cus_info};
									end
									else d_man_infomation <= {cus_info, 16'd0};
								end
							end
							default: d_man_infomation <= d_man_infomation;
						endcase
					end
				end
				Deliver: begin
					if(d_man_infomation.ctm_info1.ctm_status != None) begin
						if(d_man_infomation.ctm_info2.ctm_status != None) begin
							d_man_infomation <= {d_man_infomation.ctm_info2, 16'd0};
						end
						else d_man_infomation <= 32'd0;
					end
					else d_man_infomation <= 32'd0;
				end
				Cancel: begin
					if(d_man_infomation.ctm_info1.res_ID == res_id && d_man_infomation.ctm_info1.food_ID == food_info.d_food_ID && d_man_infomation.ctm_info2.res_ID == res_id && d_man_infomation.ctm_info2.food_ID == food_info.d_food_ID ) begin
						d_man_infomation <= 32'd0;
					end
					else if(d_man_infomation.ctm_info1.res_ID == res_id && d_man_infomation.ctm_info1.food_ID == food_info.d_food_ID) begin
						d_man_infomation <= {d_man_infomation.ctm_info2, 16'd0};
					end
					else if(d_man_infomation.ctm_info2.res_ID == res_id && d_man_infomation.ctm_info2.food_ID == food_info.d_food_ID) begin
						d_man_infomation <= {d_man_infomation.ctm_info1, 16'd0};
					end
					else d_man_infomation <= d_man_infomation;
				end
			endcase		
		end
		else d_man_infomation <= d_man_infomation;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) res_infomation <= 0;
	else begin
		if(c_state == STATE_res_WAIT)  res_infomation <= (inf.C_out_valid)? {inf.C_data_r[7:0], inf.C_data_r[15:8], inf.C_data_r[23:16], inf.C_data_r[31:24]} : res_infomation;
		else if(c_state == STATE_EXE) begin
			case(action) 
				Take: begin
					if(d_man_infomation.ctm_info1.ctm_status != None && d_man_infomation.ctm_info2.ctm_status != None) begin
						res_infomation <= res_infomation;
					end
					else begin
						case(cus_info.food_ID)
							FOOD1: begin
								if(res_infomation.ser_FOOD1 < cus_info.ser_food) res_infomation <= res_infomation;
								else res_infomation <= {res_infomation.limit_num_orders, res_infomation.ser_FOOD1-cus_info.ser_food, res_infomation.ser_FOOD2, res_infomation.ser_FOOD3};
							end
							FOOD2: begin
								if(res_infomation.ser_FOOD2 < cus_info.ser_food) res_infomation <= res_infomation;
								else res_infomation <= {res_infomation.limit_num_orders, res_infomation.ser_FOOD1, res_infomation.ser_FOOD2-cus_info.ser_food, res_infomation.ser_FOOD3};
							end
							FOOD3: begin
								if(res_infomation.ser_FOOD3 < cus_info.ser_food) res_infomation <= res_infomation;
								else res_infomation <= {res_infomation.limit_num_orders, res_infomation.ser_FOOD1, res_infomation.ser_FOOD2, res_infomation.ser_FOOD3-cus_info.ser_food};
							end
							default: res_infomation <= res_infomation;
						endcase
					end
				end
				Order: begin
					if((res_infomation.limit_num_orders-res_infomation.ser_FOOD1-res_infomation.ser_FOOD2-res_infomation.ser_FOOD3) < food_info.d_ser_food ) begin
						res_infomation <= res_infomation;
					end
					else begin
						case(food_info.d_food_ID) 
							FOOD1: begin
								res_infomation <= {res_infomation.limit_num_orders, {res_infomation.ser_FOOD1 + food_info.d_ser_food}, res_infomation.ser_FOOD2, res_infomation.ser_FOOD3};
							end
							FOOD2: begin
								res_infomation <= {res_infomation.limit_num_orders, res_infomation.ser_FOOD1, {res_infomation.ser_FOOD2 + food_info.d_ser_food}, res_infomation.ser_FOOD3};
							end
							FOOD3: begin
								res_infomation <= {res_infomation.limit_num_orders, res_infomation.ser_FOOD1, res_infomation.ser_FOOD2, {res_infomation.ser_FOOD3 + food_info.d_ser_food}};
							end
							default: res_infomation <= res_infomation;
						endcase
					end
				end
			endcase		
		end
	end
end
//----------------flag---------------------------------
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) flag_ID <= 0;
	else begin
		if(inf.id_valid) flag_ID <= 1;
		else if(c_state == STATE_IDLE) flag_ID <= 0;
		else flag_ID <= flag_ID;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) flag_CUS <= 0;
	else begin
		if(inf.cus_valid) flag_CUS <= 1;
		else if(c_state == STATE_IDLE) flag_CUS <= 0;
		else flag_CUS <= flag_CUS;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) flag_FOOD <= 0;
	else begin
		if(inf.food_valid) flag_FOOD <= 1;
		else if(c_state == STATE_IDLE) flag_FOOD <= 0;
		else flag_FOOD <= flag_FOOD;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) flag_addr_jump <= 0;
	else begin
		if(inf.out_valid) flag_addr_jump <= 1;
		else flag_addr_jump <= flag_addr_jump;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) flag_d_id <= 0;
	else begin
		if(c_state == STATE_d_id) flag_d_id <= 1;
		else if(c_state == STATE_ID) flag_d_id <= 0;
		else flag_d_id <= flag_d_id;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) flag_res_id <= 0;
	else begin
		if(c_state == STATE_res_id) begin
			flag_res_id <= 1;
		end
		else if((c_state == STATE_CUS)||(c_state == STATE_RES)) begin
			flag_res_id <= (action == Cancel)? (flag_res_id)? 1 : 0 : 0;
		end
		else flag_res_id <= flag_res_id;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) flag_RES <= 0;
	else begin
		if(inf.res_valid) flag_RES <= 1;
		else if(c_state == STATE_IDLE) flag_RES <= 0;
		else flag_RES <= flag_RES;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) write_counter <= 0;
	else begin
		if(c_state == STATE_WRITE) write_counter <= write_counter + 1;
		else if(c_state == STATE_IDLE) write_counter <= 0;
		else write_counter <= write_counter;
	end
end
//---------------------address---------------------------------
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) addr_d <= 0;
	else begin
		if(c_state == STATE_d_id) addr_d <= d_man_id;
		else addr_d <= addr_d;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) addr_res <= 0;
	else begin
		if(c_state == STATE_res_id) addr_res <= res_id;
		else addr_res <= addr_res;
	end
end
//----------------DRAM DATA-------------------------------------
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) d_man_data <= 0;
	else begin
		if(c_state == STATE_d_WAIT) begin
			if(inf.C_out_valid) begin
				if(d_man_id == addr_res) begin
					d_man_data <= res_data;
				end
				else d_man_data <= inf.C_data_r;
			end
			else d_man_data <= d_man_data;
		end
		else if (c_state == STATE_OUT) begin
			case(action)
				Take: begin

					if(d_man_id == res_id) d_man_data <= {d_man_infomation[7:0], d_man_infomation[15:14], d_man_infomation[13:8], d_man_infomation[23:16], d_man_infomation[31:24], res_infomation[7:0], res_infomation[15:8], res_infomation[23:16], res_infomation[31:24]};
					else d_man_data <= {d_man_infomation[7:0], d_man_infomation[15:14], d_man_infomation[13:8], d_man_infomation[23:16], d_man_infomation[31:24], d_man_data[31:0]};

				end
				Deliver: begin
					if(d_man_id == res_id) d_man_data <= {d_man_infomation[7:0], d_man_infomation[15:14], d_man_infomation[13:8], d_man_infomation[23:16], d_man_infomation[31:24], d_man_data[31:0]};
					else d_man_data <= {d_man_infomation[7:0], d_man_infomation[15:14], d_man_infomation[13:8], d_man_infomation[23:16], d_man_infomation[31:24], d_man_data[31:0]};
				end
				Cancel: begin
					d_man_data <= {d_man_infomation[7:0], d_man_infomation[15:14], d_man_infomation[13:8], d_man_infomation[23:16], d_man_infomation[31:24], d_man_data[31:0]};
				end
				default: d_man_data <= d_man_data;
			endcase
		end
		else if(c_state == STATE_IDLE) begin
			if(action == Order) begin
				if(addr_d == addr_res) d_man_data <= res_data;
				else d_man_data <= d_man_data;
			end
			else d_man_data <= d_man_data;
		end
		else d_man_data <= d_man_data;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) res_data <= 0;
	else begin
		if(c_state == STATE_res_WAIT) res_data <= (inf.C_out_valid)? inf.C_data_r : res_data;
		else if(c_state == STATE_OUT) begin
			case(action) 
				Take, Order: begin
					if(d_man_id == res_id)  res_data <= {d_man_infomation[7:0], d_man_infomation[15:14], d_man_infomation[13:8], d_man_infomation[23:16], d_man_infomation[31:24], res_infomation[7:0], res_infomation[15:8], res_infomation[23:16], res_infomation[31:24]};
					else res_data <= {res_data[63:32], res_infomation[7:0], res_infomation[15:8], res_infomation[23:16], res_infomation[31:24]};
				end
				Cancel: begin
					if(addr_res == addr_d )  res_data <= {d_man_infomation[7:0], d_man_infomation[15:14], d_man_infomation[13:8], d_man_infomation[23:16], d_man_infomation[31:24], res_infomation[7:0], res_infomation[15:8], res_infomation[23:16], res_infomation[31:24]};
					else res_data <= res_data;
				end
				default: begin
					res_data <= res_data;
				end
			endcase
		end
		else if(c_state == STATE_IDLE) begin
			if(action == Deliver) begin
				if(addr_d == addr_res) res_data <= d_man_data;
				else res_data <= res_data;
			end
			else res_data <= res_data;
		end
		else res_data <= res_data;
	end
end
//===========================================================================
// OUTPUT Block
//===========================================================================

//-------------Send to PATTERN--------------------------
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.out_valid <= 0;
	else begin
		if(c_state == STATE_OUT) inf.out_valid <= 1;
		else inf.out_valid <= 0;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.err_msg <= No_Err;
	else begin
		if(c_state == STATE_EXE) begin
			if(action == Deliver) begin
				if(d_man_infomation.ctm_info1.ctm_status == None && d_man_infomation.ctm_info2.ctm_status == None) begin
					inf.err_msg <= No_customers;
				end
				else inf.err_msg <= No_Err;
			end
			else if(action == Take) begin
				if(d_man_infomation.ctm_info1.ctm_status != None && d_man_infomation.ctm_info2.ctm_status != None) begin
					inf.err_msg <= D_man_busy;
				end
				else begin
					case(cus_info.food_ID)
						FOOD1: begin
							if(res_infomation.ser_FOOD1 < cus_info.ser_food) inf.err_msg <= No_Food;
							else inf.err_msg <= No_Err;
						end
						FOOD2: begin
							if(res_infomation.ser_FOOD2 < cus_info.ser_food) inf.err_msg <= No_Food;
							else inf.err_msg <= No_Err;
						end
						FOOD3: begin
							if(res_infomation.ser_FOOD3 < cus_info.ser_food) inf.err_msg <= No_Food;
							else inf.err_msg <= No_Err;
						end
						default: inf.err_msg <= No_Err;
					endcase
				end
			end
			else if(action == Order) begin
				if((res_infomation.limit_num_orders-res_infomation.ser_FOOD1-res_infomation.ser_FOOD2-res_infomation.ser_FOOD3) < food_info.d_ser_food ) begin
					inf.err_msg <= Res_busy;
				end
				else inf.err_msg <= No_Err;
			end
			else if(action == Cancel) begin
				if(d_man_infomation.ctm_info1.ctm_status == None) begin
					inf.err_msg <= Wrong_cancel;
				end
				else begin
					if(d_man_infomation.ctm_info2.ctm_status != None) begin
						if(d_man_infomation.ctm_info1.res_ID != res_id && d_man_infomation.ctm_info2.res_ID != res_id) begin
							inf.err_msg <= Wrong_res_ID;
						end
						else if((d_man_infomation.ctm_info1.food_ID == food_info.d_food_ID && d_man_infomation.ctm_info1.res_ID == res_id)||(d_man_infomation.ctm_info2.food_ID == food_info.d_food_ID && d_man_infomation.ctm_info2.res_ID == res_id)) begin
							inf.err_msg <= No_Err;
						end
						else inf.err_msg <= Wrong_food_ID;
					end
					else begin
						if(d_man_infomation.ctm_info1.res_ID != res_id) begin
							inf.err_msg <= Wrong_res_ID;
						end
						else if((d_man_infomation.ctm_info1.food_ID == food_info.d_food_ID && d_man_infomation.ctm_info1.res_ID == res_id)) begin
							inf.err_msg <= No_Err;
						end
						else inf.err_msg <= Wrong_food_ID;
					end
				end
			end
		end
		//else if(c_state == STATE_IDLE) inf.err_msg <= 0;
		else inf.err_msg <= inf.err_msg;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.complete <= 0;
	else begin	
		if(c_state == STATE_EXE) begin
			if(action == Deliver) begin
				if(d_man_infomation.ctm_info1.ctm_status != None || d_man_infomation.ctm_info2.ctm_status != None) begin
					inf.complete <= 1;
				end
				else inf.complete <= 0;
			end
			else if(action == Take) begin
				if(d_man_infomation.ctm_info1.ctm_status != None && d_man_infomation.ctm_info2.ctm_status != None) begin
					inf.complete <= 0;
				end
				else begin
					case(cus_info.food_ID)
						FOOD1: begin
							if(res_infomation.ser_FOOD1 < cus_info.ser_food) inf.complete <= 0;
							else inf.complete <= 1;
						end
						FOOD2: begin
							if(res_infomation.ser_FOOD2 < cus_info.ser_food) inf.complete <= 0;
							else inf.complete <= 1;
						end
						FOOD3: begin
							if(res_infomation.ser_FOOD3 < cus_info.ser_food) inf.complete <= 0;
							else inf.complete <= 1;
						end
						default: inf.complete <= 1;
					endcase
				end
			end
			else if(action == Order) begin
				if((res_infomation.limit_num_orders-res_infomation.ser_FOOD1-res_infomation.ser_FOOD2-res_infomation.ser_FOOD3) < food_info.d_ser_food ) begin
					inf.complete <= 0;
				end
				else inf.complete <= 1;
			end
			else if(action == Cancel) begin
				if(d_man_infomation.ctm_info1.ctm_status == None) begin
					inf.complete <= 0;
				end
				else begin
					if(d_man_infomation.ctm_info2.ctm_status != None) begin
						if(d_man_infomation.ctm_info1.res_ID != res_id && d_man_infomation.ctm_info2.res_ID != res_id) begin
							inf.complete <= 0;
						end
						else if((d_man_infomation.ctm_info1.food_ID == food_info.d_food_ID && d_man_infomation.ctm_info1.res_ID == res_id)||(d_man_infomation.ctm_info2.food_ID == food_info.d_food_ID && d_man_infomation.ctm_info2.res_ID == res_id)) begin
							inf.complete <= 1;
						end
						else inf.complete <= 0;
					end
					else begin
						if(d_man_infomation.ctm_info1.res_ID != res_id) begin
							inf.complete <= 0;
						end
						else if((d_man_infomation.ctm_info1.food_ID == food_info.d_food_ID && d_man_infomation.ctm_info1.res_ID == res_id)) begin
							inf.complete <= 1;
						end
						else inf.complete <= 0;
					end
				end
			end
		end
		else if(c_state == STATE_IDLE) inf.complete <= 0;
		else inf.complete <= inf.complete;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.out_info <= 0;
	else begin
		if(c_state == STATE_OUT) begin
			if(action == Deliver) begin
				if(d_man_infomation.ctm_info1.ctm_status == None && d_man_infomation.ctm_info2.ctm_status == None) begin
					inf.out_info <= 0;
				end
				else inf.out_info <= {d_man_infomation, 32'd0};
			end
			else if(action == Take) begin
				case(inf.err_msg)
					No_Err : inf.out_info <= {d_man_infomation, res_infomation};
					default: inf.out_info <= 0;
				endcase
			end
			else if(action == Order) begin
				case(inf.err_msg)
					No_Err : inf.out_info <= {32'd0, res_infomation};
					default: inf.out_info <= 0;
				endcase			
			end
			else if(action == Cancel) begin
				case(inf.err_msg)
					No_Err : inf.out_info <= {d_man_infomation, 32'd0};
					default: inf.out_info <= 0;
				endcase
			end
		end
		else if(c_state == STATE_IDLE) inf.out_info <= 0;
		else inf.out_info <= inf.out_info;
	end
end

//-------------Send to Bridge---------------------------
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.C_addr <= 0;
	else begin
		if(c_state == STATE_d_id) begin
			inf.C_addr <= d_man_id;
		end
		else if(c_state == STATE_res_id) begin
			inf.C_addr <= res_id;
		end
		else if(c_state == STATE_WRITE) begin
			case(action)
				Take: begin
					if(flag_ID && flag_CUS) inf.C_addr <= addr_res;
					else if(flag_ID) inf.C_addr <= addr_d;
					else inf.C_addr <= addr_res;
				end
				default: inf.C_addr <= inf.C_addr;
				Deliver: inf.C_addr <= addr_d;
				Order:   inf.C_addr <= addr_res;
				Cancel : inf.C_addr <= addr_d;
			endcase
		end
		else inf.C_addr <= inf.C_addr;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.C_in_valid <= 0;
	else begin
		if(c_state == STATE_d_id) begin
			inf.C_in_valid <= 1;
		end
		else if(c_state == STATE_res_id) begin
			inf.C_in_valid <= 1;
		end
		else if(c_state == STATE_WRITE) begin
			inf.C_in_valid <= 1;
		end
		else inf.C_in_valid <= 0;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.C_r_wb <= 0;
	else begin
		if(c_state == STATE_d_id) begin
			inf.C_r_wb <= 1;
		end
		else if(c_state == STATE_res_id) begin
			inf.C_r_wb <= 1;
		end
		else inf.C_r_wb <= 0;
	end
end
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.C_data_w <= 0;
	else begin
		if(c_state == STATE_WRITE) begin
			case(action)
				Take: begin
					if(flag_ID && flag_CUS) inf.C_data_w <= res_data;
					else if(flag_ID) inf.C_data_w <= d_man_data;
					else inf.C_data_w <= res_data;
				end
				default: inf.C_data_w <= inf.C_data_w;
				Deliver: inf.C_data_w <= d_man_data;
				Order:   inf.C_data_w <= res_data;
				Cancel:  inf.C_data_w <= d_man_data;
			endcase		
		end
		else inf.C_data_w <= 0;
	end
end
endmodule