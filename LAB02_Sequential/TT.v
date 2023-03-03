module TT(
    //Input Port
    clk,
    rst_n,
	in_valid,
    source,
    destination,

    //Output Port
    out_valid,
    cost
    );

input               clk, rst_n, in_valid;
input       [3:0]   source;
input       [3:0]   destination;

output reg          out_valid;
output reg  [3:0]   cost;

//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter IDLE   = 2'd0;
parameter INPUT  = 2'd1;
parameter CHECK  = 2'd2;
parameter OUTPUT = 2'd3;
integer i;
genvar j;
//==============================================//
//            FSM State Declaration             //
//==============================================//
reg [1:0] c_state;
reg [1:0] n_state;

//==============================================//
//                 reg declaration              //
//==============================================//
reg [3:0] source_cp;
reg [3:0] destination_cp;
reg in_valid_cp;
reg flag_FC;
reg flag_check;
reg [3:0] count;
reg [3:0] visited_num;
reg [3:0] round;
reg [3:0] round_cp;
reg [3:0] start;
reg [3:0] start_station;
reg [3:0] end_station;
reg [15:0] Connected_Array [15:0];


reg [15:0] visited; 
reg [15:0] visited_cp;
reg [3:0] ticket [15:0];
reg [3:0] ticket_cp [15:0];

//==============================================//
//             Current State Block              //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        c_state <= IDLE;
	end
    else begin
        c_state <= n_state;
	end
end

//==============================================//
//              Next State Block                //
//==============================================//
always@(*) begin
    case(c_state)
		IDLE:   begin
			if(in_valid) n_state = INPUT;
			else n_state = IDLE;
		end
		INPUT:  begin
			if(!in_valid) n_state = CHECK;
			else n_state = INPUT;
		end
		CHECK:  begin
			if(flag_check) begin
				if (Connected_Array[start_station]==0||Connected_Array[end_station]==0) n_state = OUTPUT;
				else n_state = CHECK;
			end
			else begin
				if((ticket_cp[end_station]!=0)||(!round)) n_state = OUTPUT;
				else n_state = CHECK;
			end
		end
		OUTPUT: begin
			n_state = IDLE;
		end
    endcase
end

//==============================================//
//                  Input Block                 //
//==============================================//
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) source_cp <= 0;
	else begin
		if(c_state == INPUT) source_cp <= source;
		else source_cp <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) destination_cp <= 0;
	else begin
		if(c_state == INPUT) destination_cp <= destination;
		else destination_cp <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) in_valid_cp <= 0;
	else in_valid_cp <= in_valid;
end
//       Remember START & END station           
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) start_station <= 0;
	else begin
		if(in_valid && (flag_FC)) start_station <= source;
		else start_station <= start_station;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) end_station <= 0;
	else begin
		if(in_valid && (flag_FC)) end_station <= destination;
		else end_station <= end_station;
	end
end
//       Set a flag to trigger start & end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) flag_FC <= 1;
	else begin
		if(in_valid) flag_FC <= 0;
		else flag_FC <= 1;
	end
end
//  	Set a start variable to change check station
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) start <= 0;
	else begin
		if(c_state==CHECK) start <= visited_num;
		else start <= start_station;
	end
end
//		Remember the connected relationship of stations
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<16;i=i+1) Connected_Array[i] <= 0;
	end
	else begin
		case(c_state)
			INPUT: begin
				if(!flag_FC) begin
					Connected_Array[source_cp][destination_cp] <= 1;
					Connected_Array[destination_cp][source_cp] <= 1;
				end
				else begin
					for(i=0;i<16;i=i+1) Connected_Array[i] <= Connected_Array[i];
				end
			end
			CHECK: begin
				if(ticket_cp[count]) begin
					for(i=0;i<16;i=i+1) Connected_Array[i][count] <= 0;
				end
				else begin
					for(i=0;i<16;i=i+1) Connected_Array[i] <= Connected_Array[i];
				end
			end
			default: begin
				for(i=0;i<16;i=i+1) Connected_Array[i] <= 0;
			end
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) flag_check <= 0;
	else begin
		if(!in_valid&&in_valid_cp) flag_check <= 1;
		else flag_check <= 0;
	end
end
//==============================================//
//              Calculation Block               //
//==============================================//
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) visited <= 0;
	else begin
		if(c_state==CHECK) visited[start] <= 1;
		else visited <= 0;
	end
end
generate
	for(j=0;j<16;j=j+1) begin
		always@(*) begin
			if(c_state==CHECK) begin
				if(j==start) visited_cp[j] = 1;
				else visited_cp[j] = 0;
			end
			else visited_cp[j] = visited[j];
		end
	end
endgenerate
always@(*) begin
	if(c_state==CHECK) begin
		if(ticket[count-1]==round) visited_num = count-1;
		else if(count==0&&(ticket[15]==(round_cp))) visited_num = 15;
		else if(ticket_cp[count-1]==round&&(count==1)) visited_num = 0;
		else visited_num = start; 
	end
	else visited_num = start_station;
end
generate
	for(j=0;j<16;j=j+1) begin
		always@(*) begin
			if(c_state==CHECK) begin
				if ((Connected_Array[start][j]&(~visited[j]))&&(!(ticket[j]))) begin
					if(count==1&&((Connected_Array[start][j]&(~visited_cp[j])))) begin
						ticket_cp[j] = ticket[start]+(Connected_Array[start][j]&(~visited_cp[j]));
					end
					else ticket_cp[j] = ticket[start]+(Connected_Array[start][j]&(~visited[j]));
				end	
				else ticket_cp[j] = ticket[j];
			end
			else ticket_cp[j] = ticket[j];
		end
	end
endgenerate
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<16; i=i+1) ticket[i] <= 0;
	end
	else begin
		case(c_state)
			IDLE: begin
				for(i=0; i<16; i=i+1) ticket[i] <= 0;
			end
			CHECK: begin
				for(i=0;i<16;i=i+1) ticket[i] <= ticket_cp[i];
			end
			default: begin
				for(i=0; i<16; i=i+1) ticket[i] <= ticket[i];
			end
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) count <= 0;
	else begin
		if(c_state==CHECK) begin
			if(count>1&&count<13) begin
				if((ticket[count]!=round)&&(ticket[count+1]!=round)) count <= count+3;
				else if(ticket[count]!=round) count <= count+2;
				else count <= count+1;
			end
			else if(count==13) begin
				if(ticket[count]!=round) count <= count+2;
				else count <= count+1;
			end
			else count <= count+1;
		end
		else count<=0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) round_cp <= 1;
	else round_cp <= round;
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) round <= 1;
	else begin
		if(c_state == CHECK) begin
			if(count==15) round <= round+1;
			else round <= round;
		end
		else round <= 1;
	end
end

//==============================================//
//                Output Block                  //
//==============================================//

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_valid <= 0; /* remember to reset */
    else begin
		if(c_state == OUTPUT) out_valid <= 1;
		else out_valid <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cost <= 0; /* remember to reset */
    else begin
		if(c_state == OUTPUT)  
			if(round!=15) cost <= ticket[end_station];
			else if(ticket[15]!=0) cost <= 15;
			else cost<=0;
		else cost <= 0;
    end
end 

endmodule 