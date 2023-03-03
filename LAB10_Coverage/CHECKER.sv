module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//declare other cover group

//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write the required assertions below
//  assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0 [*2])
//  else
//  begin
//  	$display("Assertion X is violated");
//  	$fatal; 
//  end
wire #(0.5) rst_reg = inf.rst_n;

//========================================================================================================================================================
// Spec 1 (coverpoint inf.D.d_id[0] is divided into 256 bins and each bin has to be hit at least 1 time.)
//========================================================================================================================================================

covergroup Spec_1 @(posedge clk iff(inf.id_valid));
	coverpoint inf.D.d_id[0] {
		option.auto_bin_max = 256;
		option.at_least = 1;
	}
	option.per_instance = 1;
endgroup
Spec_1 iclab_eat1 = new();

//========================================================================================================================================================
// Spec 2 ( coverpoint inf.D.d_act[0] is divided into 16 transition bins and each bin has to be hit at least 10 time.)
//========================================================================================================================================================

covergroup Spec_2 @(posedge clk iff(inf.act_valid));
	coverpoint inf.D.d_act[0] {
		bins Take1    =  (Take   => Take);
		bins Take2    =  (Take   => Order);
		bins Take3    =  (Take   => Deliver);
		bins Take4    =  (Take   => Cancel);
								 
		bins Order1   =  (Order  => Take);
		bins Order2   =  (Order  => Order);
		bins Order3   =  (Order  => Deliver);
		bins Order4   =  (Order  => Cancel); 
		
		bins Deliver1 = (Deliver => Take);
		bins Deliver2 = (Deliver => Order);
		bins Deliver3 = (Deliver => Deliver);
		bins Deliver4 = (Deliver => Cancel); 
		
		bins Cancel1  = (Cancel  => Take);
		bins Cancel2  = (Cancel  => Order);
		bins Cancel3  = (Cancel  => Deliver);
		bins Cancel4  = (Cancel  => Cancel);  
	}
	option.at_least = 10;
	option.per_instance = 1;
endgroup
Spec_2 iclab_eat2 = new();

//========================================================================================================================================================
// Spec 3 ( coverpoint inf.complete need to be 0 and 1 and each bin should be hit at least 200 times.)
//========================================================================================================================================================

covergroup Spec_3 @(negedge clk iff(inf.out_valid));
	coverpoint inf.complete {
		bins number[] = {0, 1};
	}
	option.at_least = 200;
	option.per_instance = 1;
endgroup
Spec_3 iclab_eat3 = new();

//========================================================================================================================================================
// Spec 4 ( coverpoint inf.err_msg: each case except No_Err should occur at least 20 times.)
//========================================================================================================================================================

covergroup Spec_4 @(negedge clk iff(inf.out_valid));
	coverpoint inf.err_msg {
		bins msg[] = { No_Food, D_man_busy, No_customers, Res_busy, Wrong_cancel, Wrong_res_ID, Wrong_food_ID};
	}
	option.at_least = 20;
	option.per_instance = 1;
endgroup
Spec_4 iclab_eat4 = new();

//write other assertions
//========================================================================================================================================================
// Assertion 1 ( All outputs signals (including FD.sv and bridge.sv) should be zero after reset.)
//========================================================================================================================================================
always@(negedge rst_reg) begin
	assert_1: assert ((inf.out_valid === 0)  && (inf.out_info === 0) && (inf.err_msg === 0) && (inf.complete === 0) && 
					  (inf.C_in_valid === 0) && (inf.C_addr === 0)   && (inf.C_r_wb === 0)  && (inf.C_data_w === 0) &&
					  (inf.C_out_valid=== 0) && (inf.C_data_r === 0) && (inf.AR_VALID === 0)&& (inf.AR_ADDR  === 0) &&
					  (inf.R_READY === 0)    && (inf.AW_VALID === 0) && (inf.AW_ADDR === 0) && (inf.W_VALID  === 0) &&
					  (inf.W_DATA === 0)     && (inf.B_READY === 0))
	else begin
		$display("Assertion 1 is violated");
		$fatal;
	end	
end
//========================================================================================================================================================
// Assertion 2 ( If action is completed, err_msg should be 4’b0.)
//========================================================================================================================================================
assert_2 : assert property(@(negedge clk) ((inf.out_valid === 1) && (inf.complete === 1)) |-> (inf.err_msg === No_Err))
	else begin
		$display("Assertion 2 is violated");
		$fatal;
	end
//========================================================================================================================================================
// Assertion 3 ( If action is not completed, out_info should be 64’b0.)
//========================================================================================================================================================
assert_3 : assert property(@(negedge clk) ((inf.out_valid === 1) && (inf.complete === 0)) |-> (inf.out_info === 64'd0))
	else begin
		$display("Assertion 3 is violated");
		$fatal;
	end
//========================================================================================================================================================
// Assertion 4 ( The gap between each input valid is at least 1 cycle and at most 5 cycles.)
//========================================================================================================================================================
Action action;
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) 			action <= No_action;
	else if(inf.out_valid)  action <= No_action;
	else if(inf.act_valid)  action <= inf.D.d_act[0];
	else 					action <= action;
end

assert_4_Take_1 : assert property(@(negedge clk) (inf.act_valid && action == Take) |=> ##[1:5] (inf.id_valid || inf.cus_valid))
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Take_1_1 : assert property(@(negedge clk) (inf.act_valid && action == Take) |=> ((inf.id_valid == 0) && (inf.cus_valid == 0)))
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Take_2 : assert property(@(negedge clk) (inf.id_valid && action == Take) |=>##[1:5] inf.cus_valid)
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Take_2_1 : assert property(@(negedge clk) (inf.id_valid && action == Take) |=> inf.cus_valid ==0)
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Deliver: assert property(@(negedge clk) (inf.act_valid && action == Deliver) |=>##[1:5] inf.id_valid)
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Deliver_1: assert property(@(negedge clk) (inf.act_valid && action == Deliver) |=> inf.id_valid==0)
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Order1:  assert property(@(negedge clk) (inf.act_valid && action == Order) |=> ##[1:5] (inf.res_valid || inf.food_valid))
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Order1_1:  assert property(@(negedge clk) (inf.act_valid && action == Order) |=> ((inf.res_valid==0) && (inf.food_valid==0)))
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Order2: assert property(@(negedge clk) (inf.res_valid && action == Order) |=> ##[1:5] inf.food_valid)
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Order2_1: assert property(@(negedge clk) (inf.res_valid && action == Order) |=> inf.food_valid == 0)
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Cancel: assert property(@(negedge clk) (inf.act_valid && action == Cancel) |=> ##[1:5] inf.res_valid)
				else begin
					$display("Assertion 4 is violated");
					//repeat(30) @(negedge clk);
					$fatal;
				end
assert_4_Cancel_1: assert property(@(negedge clk) (inf.act_valid && action == Cancel) |=> inf.res_valid ==0)
				else begin
					$display("Assertion 4 is violated");
					//repeat(30) @(negedge clk);
					$fatal;
				end
assert_4_Cancel2: assert property(@(negedge clk) (inf.res_valid && action == Cancel) |=>##[1:5] inf.food_valid)
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Cancel2_1: assert property(@(negedge clk) (inf.res_valid && action == Cancel) |=>  inf.food_valid ==0)
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Cancel3: assert property(@(negedge clk) (inf.food_valid && action === Cancel) |=> ##[1:5] inf.id_valid )
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
assert_4_Cancel3_1: assert property(@(negedge clk) (inf.food_valid && action === Cancel) |=> inf.id_valid ==0)
				else begin
					$display("Assertion 4 is violated");
					$fatal;
				end
//========================================================================================================================================================
// Assertion 5 ( All input valid signals won’t overlap with each other.)
//========================================================================================================================================================
assertion_5_act: assert property (@(posedge clk) (inf.act_valid === 1 |-> inf.id_valid === 0 && inf.cus_valid === 0  && inf.food_valid === 0 && inf.res_valid === 0))
		else begin
			$display("Assertion 5 is violated");
			$fatal;
		end
assertion_5_id: assert property (@(posedge clk) (inf.id_valid === 1 |-> inf.act_valid === 0 && inf.cus_valid === 0  && inf.food_valid === 0 && inf.res_valid === 0))
		else begin
			$display("Assertion 5 is violated");
			$fatal;
		end
assertion_5_res: assert property (@(posedge clk) (inf.res_valid === 1 |-> inf.act_valid === 0 && inf.cus_valid === 0  && inf.food_valid === 0 && inf.id_valid === 0))
		else begin
			$display("Assertion 5 is violated");
			$fatal;
		end
assertion_5_cus: assert property (@(posedge clk) (inf.cus_valid === 1 |-> inf.act_valid === 0 && inf.id_valid === 0  && inf.food_valid === 0 && inf.res_valid === 0))
		else begin
			$display("Assertion 5 is violated");
			$fatal;
		end
assertion_5_food: assert property (@(posedge clk) (inf.food_valid === 1 |-> inf.act_valid === 0 && inf.cus_valid === 0  && inf.id_valid === 0 && inf.res_valid === 0))
		else begin
			$display("Assertion 5 is violated");
			$fatal;
		end
//========================================================================================================================================================
// Assertion 6 ( Out_valid can only be high for exactly one cycle.)
//========================================================================================================================================================
assert_6: assert property (@(posedge clk) (inf.out_valid === 1) |=> (inf.out_valid === 0))
		 else begin
			$display("Assertion 6 is violated");
			$fatal;
		 end
//========================================================================================================================================================
// Assertion 7 ( Next operation will be valid 2-10 cycles after out_valid fall.)
//========================================================================================================================================================

assert_7_1: assert property (@(posedge clk) (inf.out_valid ===1) |-> ##[2:10] (inf.act_valid === 1))
		else begin
			$display("Assertion 7 is violated");
			$fatal;
		end
assert_7_2: assert property(@(posedge clk) ((inf.out_valid === 1) |-> (inf.act_valid === 0)) and ((inf.out_valid === 1) |=> (inf.act_valid === 0)))
		else begin
			$display("Assertion 7 is violated");
			$fatal;
		end
//========================================================================================================================================================
// Assertion 8 ( Latency should be less than 1200 cycles for each operation)
//========================================================================================================================================================
assert_8: assert property (@(posedge clk) ((action == Take && inf.cus_valid)||(action == Deliver && inf.id_valid) ||
										   (action == Order && inf.food_valid) || (action == Cancel && inf.id_valid)) |=> ##[0:1199] (inf.out_valid === 1))
		else begin
			$display("Assertion 8 is violated");
			$fatal;
		end
endmodule