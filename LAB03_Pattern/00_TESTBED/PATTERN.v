
`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif

module PATTERN(
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
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg       clk, rst_n;
output reg       in_valid;
output reg [2:0] guy;
output reg [1:0] in0, in1, in2, in3, in4, in5, in6, in7;
input            out_valid;
input      [1:0] out;

//================================================================
// parameters & integer
//================================================================
real CYCLE =`CYCLE_TIME;
parameter PATNUM = 300;
parameter CYCLE_NUM = 62;
integer patcount = 0;
integer total_latency, latency, SPEC_7_latency;
integer i;
integer j;
integer k;
integer n;
integer m;
//================================================================
// wire & registers 
//================================================================
reg [63:0] obstacle_wall;
reg [2:0] obstacle_pos[63:0];
reg [1:0] obs_sel_array[63:0];
reg left, right, front;
reg [1:0] exit;
reg [2:0] guy_num;
reg [7:0] guy_position;
reg [1:0] OBS_sel;
reg [9:0] counter;
reg flag_obstacle;
reg [3:0] in_position;
reg [1:0] high_position;
reg [1:0] jump_constraint[3:0];
reg [6:0] jump_counter;
reg flag_check_one_zero;
reg flag_check_two_zero_1;
reg flag_check_two_zero_2;
reg flag_check_one_zero_3;
//================================================================
// clock
//================================================================
initial 
begin
	clk = 0;
end
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// initial
//================================================================
initial 
begin

	rst_n = 1'b1;
	in_valid = 1'b0;
	guy = 3'bx;
	in0 = 2'bx;
	in1 = 2'bx;
	in2 = 2'bx;
	in3 = 2'bx;
	in4 = 2'bx;
	in5 = 2'bx;
	in6 = 2'bx;
	in7 = 2'bx;
	force clk = 0;
	#CYCLE; rst_n = 0; 
    #CYCLE; rst_n = 1;
	SPEC_3;
	#CYCLE;  release clk;
	@(negedge clk);
 	total_latency = 0;
 	for(j=0;j<PATNUM;j=j+1) begin
		FIRST_INPUT;
		GUY_POS;
		EXIT_TASK;
		OBS_GEN;
		OBS;
		FLAG_OBS;
		OBS_POS;
		@(negedge clk);
		for(k=0;k<CYCLE_NUM;k=k+1) begin
			INPUT_ZERO;
			counter=counter+1;
			OBS_POS;
			SPEC_4;
			SPEC_5;
			@(negedge clk);
		end
		INPUT_UNKNOWN;
		SPEC_6;
		@(posedge clk);
		while(out_valid==1) begin
			SPEC_7;
			SPEC8_3;
			SPEC8_2;
			SPEC8_1;
			IN_POS;
			jump_counter = jump_counter+1;
			@(posedge clk);
		end
		SPEC_7;
		counter=0;
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",j ,latency);
		repeat('d3+$urandom%3) @(negedge clk);
	end
	PASS;
	$finish;
	
  	//YOU_PASS_task;
end



//================================================================
// task
//================================================================
task FIRST_INPUT; begin
	in_valid = 1;
	guy = $urandom%8;
	guy_num = guy;
	in_position = guy;
	high_position = 0;
	SPEC_7_latency = 0;
	jump_counter = 0;
	counter = 0;
	in0=2'd0;
	in1=2'd0;
	in2=2'd0;
	in3=2'd0;
	in4=2'd0;
	in5=2'd0;
	in6=2'd0;
	in7=2'd0;
	for(n=0;n<64;n=n+1) begin
		obstacle_pos[n]=0;
		obstacle_wall[n]=0;
		obs_sel_array[n]=0;
	end
	@(negedge clk);
	counter=counter+1;
	guy = 3'dx;
end endtask
task INPUT_ZERO; begin
	if(OBS_sel == 1) begin
		GUY_POS;
		EXIT_TASK;
		OBS_GEN;
		OBS;
		FLAG_OBS;
	end
	else begin
		in0=2'd0;
		in1=2'd0;
		in2=2'd0;
		in3=2'd0;
		in4=2'd0;
		in5=2'd0;
		in6=2'd0;
		in7=2'd0;
		GUY_POS;
		EXIT_TASK;
		OBS_GEN;
		FLAG_OBS;
	end
end endtask
task GUY_POS; begin
	for(i=0;i<8;i=i+1) begin
		if(i==guy_num) guy_position[i] = 1;
		else guy_position[i] = 0;
	end
end endtask

task EXIT_TASK; begin
	if(guy_position[0]==1) begin
		exit = ($urandom%2)+'d1;
	end
	else if(guy_position[7]==1) begin
		exit = $urandom%2;
	end
	else begin
		exit = $urandom%3;
	end
	case(exit) 
		2'd0: begin
			left  = 1;
			right = 0;
			front = 0;
			guy_num = guy_num-1;
		end
		2'd1: begin
			left  = 0;
			right = 0;
			front = 1;
			guy_num = guy_num;
		end
		2'd2: begin
			left  = 0;
			right = 1;
			front = 0;
			guy_num = guy_num+1;
		end
	endcase
end endtask

task OBS_GEN; begin
	if(left==1) begin
		OBS_sel = 'd1+($urandom%'d2)*'d2;
	end
	else if(right==1) begin
		OBS_sel = 'd1+($urandom%'d2)*'d2;
	end
	else begin
		OBS_sel = 'd1+$urandom%3;
	end
end endtask
task OBS; begin
	in_valid =1;
	if(OBS_sel==1) begin
		in0=2'd0;
		in1=2'd0;
		in2=2'd0;
		in3=2'd0;
		in4=2'd0;
		in5=2'd0;
		in6=2'd0;
		in7=2'd0;
	end
	else if(OBS_sel==2) begin
		if(guy_num==0) begin
			in0=2'b01;
			in1=2'b11;
			in2=2'b11;
			in3=2'b11;
			in4=2'b11;
			in5=2'b11;
			in6=2'b11;
			in7=2'b11;
		end
		else if(guy_num==1) begin
			in0=2'b11;
			in1=2'b01;
			in2=2'b11;
			in3=2'b11;
			in4=2'b11;
			in5=2'b11;
			in6=2'b11;
			in7=2'b11;
		end
		else if(guy_num==2) begin
			in0=2'b11;
			in1=2'b11;
			in2=2'b01;
			in3=2'b11;
			in4=2'b11;
			in5=2'b11;
			in6=2'b11;
			in7=2'b11;
		end
		else if(guy_num==3) begin
			in0=2'b11;
			in1=2'b11;
			in2=2'b11;
			in3=2'b01;
			in4=2'b11;
			in5=2'b11;
			in6=2'b11;
			in7=2'b11;
		end
		else if(guy_num==4) begin
			in0=2'b11;
			in1=2'b11;
			in2=2'b11;
			in3=2'b11;
			in4=2'b01;
			in5=2'b11;
			in6=2'b11;
			in7=2'b11;
		end
		else if(guy_num==5) begin
			in0=2'b11;
			in1=2'b11;
			in2=2'b11;
			in3=2'b11;
			in4=2'b11;
			in5=2'b01;
			in6=2'b11;
			in7=2'b11;
		end
		else if(guy_num==6) begin
			in0=2'b11;
			in1=2'b11;
			in2=2'b11;
			in3=2'b11;
			in4=2'b11;
			in5=2'b11;
			in6=2'b01;
			in7=2'b11;
		end
		else if(guy_num==7) begin
			in0=2'b11;
			in1=2'b11;
			in2=2'b11;
			in3=2'b11;
			in4=2'b11;
			in5=2'b11;
			in6=2'b11;
			in7=2'b01;
		end
	end
	else if(OBS_sel==3) begin
		if(guy_num==0) begin
			in0=2'b10;
			in1=2'b11;
			in2=2'b11;
			in3=2'b11;
			in4=2'b11;
			in5=2'b11;
			in6=2'b11;
			in7=2'b11;
		end
		else if(guy_num==1) begin
			in0=2'b11;
			in1=2'b10;
			in2=2'b11;
			in3=2'b11;
			in4=2'b11;
			in5=2'b11;
			in6=2'b11;
			in7=2'b11;
		end
		else if(guy_num==2) begin
			in0=2'b11;
			in1=2'b11;
			in2=2'b10;
			in3=2'b11;
			in4=2'b11;
			in5=2'b11;
			in6=2'b11;
			in7=2'b11;
		end
		else if(guy_num==3) begin
			in0=2'b11;
			in1=2'b11;
			in2=2'b11;
			in3=2'b10;
			in4=2'b11;
			in5=2'b11;
			in6=2'b11;
			in7=2'b11;
		end
		else if(guy_num==4) begin
			in0=2'b11;
			in1=2'b11;
			in2=2'b11;
			in3=2'b11;
			in4=2'b10;
			in5=2'b11;
			in6=2'b11;
			in7=2'b11;
		end
		else if(guy_num==5) begin
			in0=2'b11;
			in1=2'b11;
			in2=2'b11;
			in3=2'b11;
			in4=2'b11;
			in5=2'b10;
			in6=2'b11;
			in7=2'b11;
		end
		else if(guy_num==6) begin
			in0=2'b11;
			in1=2'b11;
			in2=2'b11;
			in3=2'b11;
			in4=2'b11;
			in5=2'b11;
			in6=2'b10;
			in7=2'b11;
		end
		else if(guy_num==7) begin
			in0=2'b11;
			in1=2'b11;
			in2=2'b11;
			in3=2'b11;
			in4=2'b11;
			in5=2'b11;
			in6=2'b11;
			in7=2'b10;
		end
	end
end endtask
task INPUT_UNKNOWN; begin
	in_valid = 0;
	guy=8'dx;
	in0=2'dx;
	in1=2'dx;
	in2=2'dx;
	in3=2'dx;
	in4=2'dx;
	in5=2'dx;
	in6=2'dx;
	in7=2'dx;
	flag_obstacle=0;
end endtask
task FLAG_OBS; begin
	if((in0&in1&in2&in3&in4&in5&in6&in7)!==0&&(in_valid)) flag_obstacle = 1;
	else flag_obstacle = 0;
end endtask
task OBS_POS; begin
	if(in_valid) begin
		if(flag_obstacle) begin
			obstacle_pos[counter]=guy_num;
			obstacle_wall[counter] = 1;
			obs_sel_array[counter] = OBS_sel;
		end
		else begin
			obstacle_pos[counter] = 0;
			obstacle_wall[counter] = 0;
			obs_sel_array[counter] = 0;
		end
	end
	else begin
		for(m=0;m<64;m=m+1) begin
			obstacle_pos[m]=obstacle_pos[m];
			obstacle_wall[m] = obstacle_wall[m];
			obs_sel_array[m] = obs_sel_array[m];
		end
	end
end endtask
task IN_POS; begin
	if(out_valid) begin
		//jump_counter = jump_counter+1;
		if(out==2'd0) begin
			in_position = in_position;
			if(high_position>0) begin
				high_position = high_position-1;
			end
			else begin
				high_position = high_position;
			end
		end
		else if(out==2'd1) begin
			in_position = in_position+1;
			if(high_position>0) begin
				high_position = high_position-1;
			end
			else begin
				high_position = high_position;
			end
		end
		else if(out==2'd2) begin
			in_position = in_position-1;
			if(high_position>0) begin
				high_position = high_position-1;
			end
			else begin
				high_position = high_position;
			end
		end
		else if(out==2'd3) begin
			in_position = in_position;
			high_position = high_position+1;
		end
	end
end endtask
task SPEC8_1; begin
	if(out_valid) begin
		if((obstacle_wall[jump_counter]==1)&&(obstacle_pos[jump_counter]!==in_position)) begin
			DISPLAY_SPEC_8_1;
			
		end
		else if((obstacle_wall[jump_counter]==1)&&(obstacle_pos[jump_counter]==in_position)) begin
			if(high_position==1&&obs_sel_array[jump_counter]==2'd3) begin
				DISPLAY_SPEC_8_1;
				
			end
			else if(high_position==0&&obs_sel_array[jump_counter]==2'd2) begin
				DISPLAY_SPEC_8_1;
				
			end
		end
		else if(in_position>7) begin
			DISPLAY_SPEC_8_1;
			
		end
	end
end endtask
task DISPLAY_SPEC_8_1; begin
	$display("SPEC 8-1 IS FAIL!");
	$finish;
end endtask
task SPEC8_2; begin
	if(flag_check_two_zero_1) begin
		if(out!==0) begin
			$display("SPEC 8-2 IS FAIL!");
			$finish;
		end
	end
	else if(flag_check_two_zero_2) begin
		flag_check_two_zero_1 = 1;
	end
	else if(out==2'd3&&obs_sel_array[jump_counter+1-1]==2&&high_position==1&&obs_sel_array[jump_counter+2-1]==0) begin
		flag_check_two_zero_2 = 1;
	end
	else begin
		flag_check_two_zero_1 = 0;
		flag_check_two_zero_2 = 0;
	end
end endtask
task SPEC8_3; begin
	if(flag_check_one_zero) begin
		if(out!==0) begin
			$display("SPEC 8-3 IS FAIL!");
			$finish;
		end
	end
	else if(((obs_sel_array[jump_counter+2]==0&&high_position==0&&obs_sel_array[jump_counter]==0&&obs_sel_array[jump_counter+1]==0))||(obs_sel_array[jump_counter+2]==2&&high_position==1&&obs_sel_array[jump_counter]==2)) begin
		if(out==3) flag_check_one_zero = 1;
		else flag_check_one_zero = 0;
	end
	else begin
		flag_check_one_zero = 0;
		flag_check_one_zero_3 = 0;
	end
end endtask
task INPUT_TASK; begin
	GUY_POS;
	EXIT_TASK;
	OBS_GEN;
	OBS;
	@(negedge clk);
	INPUT_ZERO;
	@(negedge clk);
end endtask
task SPEC_3; begin 
	if((out_valid !== 0)||(out !== 0)) 
	begin
		$display("SPEC 3 IS FAIL!");
		$finish;
	end
end endtask

task SPEC_4; begin
	if(out_valid===0&&out!==0) begin    
		$display("SPEC 4 IS FAIL!");
		$finish;
	end
end endtask

task SPEC_5; begin
	if(in_valid===1&&out_valid===1) begin    
		$display("SPEC 5 IS FAIL!");
		$finish;
	end
end endtask

task SPEC_6; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
		latency = latency + 1;
		if(latency == 3000) begin    
          $display("SPEC 6 IS FAIL!");
		repeat(2)@(negedge clk);
	    $finish;
      end
	  @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task SPEC_7; begin
	if(out_valid===1) begin
		SPEC_7_latency = SPEC_7_latency+1;
		if(SPEC_7_latency>63) begin    
			$display("SPEC 7 IS FAIL!");
			$finish;
		end
	end
	else if(out_valid===0&&SPEC_7_latency!==63) begin    
		$display("SPEC 7 IS FAIL!");
		$finish;
	end
end endtask
task PASS; begin
	$display("*****************************************************************************");     
	$display("                              Congradulation!                                ");
	$display("                           You Pass All PATTERN                              ");
	$display("*****************************************************************************");
	$finish;
end endtask
endmodule