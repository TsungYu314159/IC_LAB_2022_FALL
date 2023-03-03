`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_FD.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
//      				  PARAMETERS
//================================================================
parameter PAT_NUM  		=  1000000;
parameter DRAM_r 		= "../00_TESTBED/DRAM/dram.dat";
//================================================================
//      				  Variable
//================================================================
Delivery_man_id 	dman_id;
Action 				action;
Ctm_Info			ctm_info;
Restaurant_id  		res_id;
food_ID_servings 	food_id;

Action 				old_action;
logic				gold_complete;
logic [63:0]		gold_out_info;
Error_Msg			gold_err_msg;



//================================================================
//      				  INTEGERS
//================================================================
integer pat;
integer SEED			=  152;
integer random_seed     =  123;
//================================================================
//      				  CLASS
//================================================================

class CUS_INFO_RAND;
	rand Ctm_Info cus_info;
	function new(int seed);
		this.srandom(seed);
	endfunction
	constraint limit{
		cus_info.ctm_status inside {Normal, VIP};
		cus_info.res_ID		inside {[0:255]};
		cus_info.food_ID	inside {FOOD1, FOOD2, FOOD3};
		cus_info.ser_food	inside {[1:15]};
		// provide one customer infomation
	}
endclass

class FOOD_RAND;
	rand food_ID_servings food;
	function new(int seed);
		this.srandom(seed);
	endfunction
	constraint limit{
		food.d_food_ID  inside {FOOD1, FOOD2, FOOD3};
		food.d_ser_food inside {[1:15]};
		// provide food infomation
	}
endclass

//================================================================
//		     				  DRAM
//================================================================
class Acess_DRAM;
	logic [7:0] dram_data [('h10000) : ('h10000+256*8-1)];

	function new();
		$readmemh(DRAM_r, dram_data);
	endfunction
	
	function res_info get_res_info(Restaurant_id res_id);
		res_info	current_res_info;
		current_res_info.limit_num_orders = this.dram_data[ 'h10000 + res_id * 8 ];
		current_res_info.ser_FOOD1		  = this.dram_data[ 'h10000 + res_id * 8 + 1 ];
		current_res_info.ser_FOOD2		  = this.dram_data[ 'h10000 + res_id * 8 + 2 ];
		current_res_info.ser_FOOD3		  = this.dram_data[ 'h10000 + res_id * 8 + 3 ];
		return current_res_info;
	endfunction
	
	function D_man_Info get_d_man_info(Delivery_man_id d_id);
		D_man_Info	current_d_man_info;
		current_d_man_info.ctm_info1 = {this.dram_data['h10000 + d_id*8 +4], this.dram_data['h10000 + d_id*8+5]};
		current_d_man_info.ctm_info2 = {this.dram_data['h10000 + d_id*8 +6], this.dram_data['h10000 + d_id*8+7]};
		return current_d_man_info;
	endfunction
	
	function store_res_info(Restaurant_id res_id, res_info updated_res_info);
		this.dram_data['h10000 + res_id * 8]     = updated_res_info.limit_num_orders;
		this.dram_data['h10000 + res_id * 8 + 1] = updated_res_info.ser_FOOD1;
		this.dram_data['h10000 + res_id * 8 + 2] = updated_res_info.ser_FOOD2;
		this.dram_data['h10000 + res_id * 8 + 3] = updated_res_info.ser_FOOD3;
	endfunction
	
	function store_d_man_info(Delivery_man_id d_id, D_man_Info updataed_d_info);
		{this.dram_data[('h10000 + d_id*8 +4)], this.dram_data[('h10000+d_id*8 +5)]} = updataed_d_info.ctm_info1;
		{this.dram_data[('h10000 + d_id*8 +6)], this.dram_data[('h10000+d_id*8 +7)]} = updataed_d_info.ctm_info2;
	endfunction
	
endclass
//================================================================
//		     			   Output
//================================================================
class OUTPUT_result;
	Action 				current_action;
	Restaurant_id 		R_id;
	res_info      		R_info;
	
	Delivery_man_id		D_id;
	D_man_Info			D_info;

	Acess_DRAM			DRAM;
	
	logic				golden_complete;
	logic [63:0]		golden_out_info;
	Error_Msg			golden_err_msg;
		
	function new();
		DRAM = new();
		current_action = No_action;
		R_id 	= 0;
		R_info 	= 0;
		D_id	= 0;
		D_info 	= 0;
		golden_complete = 0;
		golden_err_msg  = No_Err;
		golden_out_info = 0;
	endfunction
	// input action
	function Action_In(Action act);
		current_action = act;
	endfunction
	// get resaurant information
	function get_res_from_dram(Restaurant_id rid);
		R_id   = rid;
		R_info = DRAM.get_res_info(rid);
	endfunction
	// get delivery man information
	function get_dman_from_dram(Delivery_man_id did);
		D_id   = did;
		D_info = DRAM.get_d_man_info(did);
	endfunction
	
	// check result
	//=================
	//		Take
	//=================
	function Take_result(Delivery_man_id did, Ctm_Info ctm_info_in);
		void'(this.get_dman_from_dram(did));
		void'(this.get_res_from_dram(ctm_info_in.res_ID));
		//res_id = ctm_info_in.res_ID;
		//-----Delivery man busy
		if(D_info.ctm_info2.ctm_status !== None) begin
			golden_err_msg  = D_man_busy;
			golden_complete = 0;
			golden_out_info = 0;
			//$display("PAT: %d, hit 0", pat);
		end
		// restaurant has unenough food
		else if((ctm_info_in.food_ID === FOOD1 && R_info.ser_FOOD1 < ctm_info_in.ser_food) ||
			    (ctm_info_in.food_ID === FOOD2 && R_info.ser_FOOD2 < ctm_info_in.ser_food) ||
			    (ctm_info_in.food_ID === FOOD3 && R_info.ser_FOOD3 < ctm_info_in.ser_food))   begin
			golden_err_msg  = No_Food;
			golden_complete = 0;
			golden_out_info = 0;
			//$display("PAT: %d, hit 1", pat);
		end
		// correct 
		else begin
			// Updated delivery man information
			if	(D_info.ctm_info1.ctm_status === None) begin
				D_info.ctm_info1 = ctm_info_in;
			end
			else if (D_info.ctm_info1.ctm_status === Normal && ctm_info.ctm_status === VIP) begin
				D_info.ctm_info2 = D_info.ctm_info1;
				D_info.ctm_info1 = ctm_info_in;
			end
			else begin
				D_info.ctm_info2 = ctm_info_in;
			end
			// Updated restaurant information
			if		(ctm_info_in.food_ID === FOOD1) R_info.ser_FOOD1 = R_info.ser_FOOD1 - ctm_info_in.ser_food;
			else if (ctm_info_in.food_ID === FOOD2) R_info.ser_FOOD2 = R_info.ser_FOOD2 - ctm_info_in.ser_food;
			else if (ctm_info_in.food_ID === FOOD3) R_info.ser_FOOD3 = R_info.ser_FOOD3 - ctm_info_in.ser_food;
			// output			
			golden_err_msg  = No_Err;
			golden_complete = 1;
			golden_out_info = {D_info, R_info};
			// store DRAM data
			void'(DRAM.store_d_man_info(D_id, D_info));
			void'(DRAM.store_res_info(R_id, R_info));
			//$display("PAT: %d, hit 2", pat);
		end
	endfunction
	//=================
	//	   Deliver
	//=================
	function Deliver_result(Delivery_man_id did);
		void'(this.get_dman_from_dram(did));
		// No customer
		if(D_info.ctm_info1.ctm_status === None) begin
			golden_err_msg   = No_customers;
			golden_complete  = 0;
			golden_out_info  = 0;
			//$display("PAT: %d, hit 0", pat);
		end
		else begin
			D_info.ctm_info1 = D_info.ctm_info2;
			D_info.ctm_info2 = 0;
				
			golden_err_msg  = No_Err;
			golden_complete = 1;
			golden_out_info = {D_info, 32'd0};
			
			void'(DRAM.store_d_man_info(did, D_info));
			//$display("PAT: %d, hit 1", pat);
		end
		
	endfunction
	//=================
	//	   Order
	//=================
	function Order_result(Restaurant_id rid, food_ID_servings food_info_in);
		void'(this.get_res_from_dram(rid));
		if(food_info_in.d_ser_food > (R_info.limit_num_orders - R_info.ser_FOOD1 - R_info.ser_FOOD2 - R_info.ser_FOOD3)) begin
			golden_err_msg  = Res_busy;
			golden_complete = 0;
			golden_out_info = 0;
			//$display("PAT: %d, hit 0", pat);
		end
		else begin
			//Updated restaurant information
			if	   (food_info_in.d_food_ID === FOOD1) R_info.ser_FOOD1 = R_info.ser_FOOD1 + food_info_in.d_ser_food;
			else if(food_info_in.d_food_ID === FOOD2) R_info.ser_FOOD2 = R_info.ser_FOOD2 + food_info_in.d_ser_food;
			else if(food_info_in.d_food_ID === FOOD3) R_info.ser_FOOD3 = R_info.ser_FOOD3 + food_info_in.d_ser_food;
			// store dram data
			golden_err_msg  = No_Err;
			golden_complete = 1;
			golden_out_info = {32'd0, R_info};
			void'(DRAM.store_res_info(rid, R_info));
			//$display("PAT: %d, hit 1", pat);
		end
	endfunction
	//=================
	//	   Cancel
	//=================
	function Cancel_result(Restaurant_id rid, Food_id food_name, Delivery_man_id did);
		void'(this.get_dman_from_dram(did));
		if(D_info.ctm_info1.ctm_status === None) begin
			golden_err_msg  = Wrong_cancel;
			golden_complete = 0;
			golden_out_info = 0;
			//$display("PAT: %d, hit 0", pat);
		end
		else begin
			if(D_info.ctm_info1.res_ID !== res_id && D_info.ctm_info2.res_ID !== res_id) begin
				golden_err_msg  = Wrong_res_ID;
				golden_complete = 0;
				golden_out_info = 0;
				//$display("PAT: %d, hit 1", pat);
			end
			else if((D_info.ctm_info1.food_ID === food_name && D_info.ctm_info1.res_ID === res_id)||(D_info.ctm_info2.food_ID === food_name && D_info.ctm_info2.res_ID === res_id) )begin
				if(D_info.ctm_info1.res_ID === res_id && D_info.ctm_info1.food_ID === food_name && D_info.ctm_info2.res_ID === res_id && D_info.ctm_info2.food_ID === food_name ) begin
					D_info = 32'd0;
					//$display("PAT: %d, hit 2", pat);
				end
				else if(D_info.ctm_info1.res_ID === res_id && D_info.ctm_info1.food_ID === food_name) begin
					D_info = {D_info.ctm_info2, 16'd0};
					//$display("PAT: %d, hit 3", pat);
				end
				else if(D_info.ctm_info2.res_ID === res_id && D_info.ctm_info2.food_ID === food_name) begin
					D_info = {D_info.ctm_info1, 16'd0};
					//$display("PAT: %d, hit 4", pat);
				end
				golden_err_msg  = No_Err;
				golden_complete = 1;
				golden_out_info = {D_info, 32'd0};
				void'(DRAM.store_d_man_info(did, D_info));
				//$display("%h",golden_out_info);
				//$display(golden_err_msg.name());
			end
			else begin				
				//$display("PAT: %d, hit 5", pat);
				golden_err_msg  = Wrong_food_ID;
				golden_complete = 0;
				golden_out_info = 0;
			end			
		end
	
	endfunction
endclass
OUTPUT_result result;
//================================================================
//      			   Calculate Task
//================================================================
task Cal_Task; begin
	void'(result.Action_In(action));
	if(result.current_action == Take) begin
		void'(result.Take_result(dman_id, ctm_info));
		gold_complete = result.golden_complete;
		gold_out_info = result.golden_out_info;
		gold_err_msg  = result.golden_err_msg;
	end
	else if (result.current_action == Deliver) begin
		void'(result.Deliver_result(dman_id));
		gold_complete = result.golden_complete;
		gold_out_info = result.golden_out_info;
		gold_err_msg  = result.golden_err_msg;
	end
	else if (result.current_action == Order) begin
		void'(result.Order_result(res_id, food_id));
		gold_complete = result.golden_complete;
		gold_out_info = result.golden_out_info;
		gold_err_msg  = result.golden_err_msg;
	end
	else if (result.current_action == Cancel) begin
		void'(result.Cancel_result(res_id, food_id.d_food_ID, dman_id));
		gold_complete = result.golden_complete;
		gold_out_info = result.golden_out_info;
		gold_err_msg  = result.golden_err_msg;
	end
end endtask
//================================================================
//      			   Check Answer Task
//================================================================
task Check_Answer_Task; begin
	if(inf.out_valid) begin
		if((inf.err_msg !== gold_err_msg)||(inf.out_info !== gold_out_info)||(inf.complete !== gold_complete)) begin
			$display("Wrong Answer");
			//$display("golden_info:%16h , golden_complete: %b ,golden_err_msg: %10s",gold_out_info,gold_complete,gold_err_msg.name());
			//$display("your_info:%16h , your_complete: %b ,your_err_msg: %10s",inf.out_info,inf.complete,inf.err_msg.name());
			$finish;
		end
	end
end endtask
//================================================================
//		     				  MAIN
//================================================================
initial begin
	reset_task;
	for(pat = 0; pat<PAT_NUM; pat= pat+1) begin
		input_task;
		Cal_Task;
		wait_task;
		Check_Answer_Task;
		pass_task;
	end
	@(negedge clk);
	$finish;
end


//================================================================
//     				  INPUT Random Task
//================================================================
task Action_Task; begin
	// generate random action
	//ACTION_RAND random_action = new(SEED);
	// action_valid to be high
	//void'(random_action.randomize());
	old_action = action;
	//action = random_action.act;
	if(pat < 25) begin
		action = Cancel;
	end
	else if(pat>25 && pat<45) begin
		action = Order;
	end
	else begin
		case(pat%19)
			'd0: action = Cancel;
			'd1: action = Take;
			'd2: action = Cancel;
			'd3: action = Deliver;
			'd4: action = Cancel;
			'd5: action = Order;
			'd6: action = Cancel;
			'd7: action = Order;
			'd8: action = Take;
			'd9: action = Take;
			'd10: action = Deliver;
			'd11: action = Take;
			'd12: action = Order;
			'd13: action = Take;
			'd14: action = Deliver;
			'd15: action = Deliver;
			'd16: action = Order;
			'd17: action = Order;
			'd18: action = Deliver;
		endcase
	end
	inf.act_valid = 1'b1;
end endtask

task Deliver_ID_Task; begin
	// generate random deliver ID 
	//D_MAN_ID_RAND random_deliver_ID = new(SEED);
	// id_valid to be high
	//void'(random_deliver_ID.randomize());
	//dman_id = random_deliver_ID.ID;
	if(pat == 0) dman_id = 1;
	else if(pat == 1) dman_id = 2;
	else if(pat == 2) dman_id = 3;
	else if(pat == 3) dman_id = 4;
	else if(pat == 4) dman_id = 5;
	else if(pat < 40) dman_id = 0;
	else dman_id = dman_id+1;
	inf.id_valid = 1'b1;
end endtask

task Food_Task; begin
	// generate random food
	FOOD_RAND random_food = new(SEED);
	// food_valid to be high
	void'(random_food.randomize());
	if(pat  < 5) begin
		food_id.d_food_ID	= FOOD1;
		food_id.d_ser_food  = 0;
	end
	else food_id = random_food.food;
	inf.food_valid = 1'b1;
end endtask

task Restaurant_Task; begin
	// generate random restaurant
	//RES_ID_RAND random_res_ID = new(SEED);
	// res_valid to be high
	//void'(random_res_ID.randomize());
	//res_id = random_res_ID.RES;
	if(pat == 0) res_id = 0;
	else if(pat<40) res_id = 0;
	else res_id = $random(random_seed) % 256;
	inf.res_valid = 1'b1;
end endtask

task Ctm_Task; begin
	// generate random customer
	CUS_INFO_RAND random_ctm_info = new(SEED);
	// cus_valid to be high
	void'(random_ctm_info.randomize());
	ctm_info = random_ctm_info.cus_info;
	inf.cus_valid = 1'b1;
end endtask

//================================================================
//     				  	    RESET Task
//================================================================

task reset_task; begin
	inf.rst_n 		= 1;
	inf.act_valid	= 0;
	inf.id_valid 	= 0;
	inf.res_valid   = 0;
	inf.cus_valid   = 0;
	inf.food_valid  = 0;
	inf.D		    = 'dx;
	force clk = 0;
	#(5) inf.rst_n = 0;
	#(5) inf.rst_n = 1;
	#(5) release clk;
	result = new();
end endtask


//================================================================
//     				  	    INPUT Task
//================================================================
task input_task2; begin
	if(action == Take) begin
		inf.D = action;
		@(negedge clk);
		inf.act_valid = 1'b0;
		inf.D = 'dx;
		repeat( 1 ) @(negedge clk);
		if(({$random(SEED)} % 2 == 0 )||(pat == 0)||old_action !== Take) begin
			Deliver_ID_Task;
			inf.D = dman_id;
			@(negedge clk);
			inf.id_valid = 1'b0;
			inf.D = 'dx;
			repeat( 1 ) @(negedge clk);
		end
		Ctm_Task;
		inf.D = ctm_info;
		@(negedge clk);
		inf.cus_valid = 1'b0;
		inf.D = 'dx;
	end
	else if(action == Deliver) begin
		inf.D = action;
		@(negedge clk);
		inf.act_valid = 1'b0;
		inf.D = 'dx;
		repeat( 1 ) @(negedge clk);
		Deliver_ID_Task;
		inf.D = dman_id;
		@(negedge clk);
		inf.id_valid = 1'b0;
		inf.D = 'dx;
	end
	else if(action == Order) begin
		inf.D = action;
		@(negedge clk);
		inf.act_valid = 1'b0;
		inf.D = 'dx;
		repeat( 1) @(negedge clk);
		if(({$random(SEED)} % 2 == 0 )||(pat == 0)||old_action !== Order) begin
			Restaurant_Task;
			inf.D = res_id;
			@(negedge clk);
			inf.res_valid =1'b0;
			inf.D = 'dx;
			repeat( 1 ) @(negedge clk);
		end
		Food_Task;
		inf.D =food_id;
		@(negedge clk);
		inf.food_valid = 1'b0;
		inf.D = 'dx;
	end
	else if(action == Cancel) begin
		inf.D = action;
		@(negedge clk);
		inf.act_valid = 1'b0;
		inf.D = 'dx;
		repeat( 1 ) @(negedge clk);
		Restaurant_Task;
		//res_id = res_id;
		inf.D = res_id;
		@(negedge clk);
		inf.res_valid =1'b0;
		inf.D = 'dx;
		repeat( 1 ) @(negedge clk);
		Food_Task;
		food_id.d_ser_food = 0;
		inf.D =food_id;
		@(negedge clk);
		inf.food_valid = 1'b0;
		inf.D = 'dx;
		repeat( 1 ) @(negedge clk);
		Deliver_ID_Task;
		inf.D = dman_id;
		@(negedge clk);
		inf.id_valid = 1'b0;
		inf.D = 'dx;
	end
end endtask

task input_task; begin
	repeat(1) @(negedge clk);
	// input action 
	@(negedge clk);
	Action_Task;
	input_task2;
end endtask
//================================================================
//     				  	    Wait Task
//================================================================
task wait_task; begin
	while(inf.out_valid !== 1) begin
		@(negedge clk);
	end
end endtask
task pass_task; begin
	$display("\033[32mNo.%-5d PATTERN PASS!!!\033[1;0m", pat);
end endtask
endprogram