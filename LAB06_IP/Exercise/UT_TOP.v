//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : UT_TOP.v
//   Module Name : UT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


`include "B2BCD_IP.v"


module UT_TOP (
    // Input signals
    clk, rst_n, in_valid, in_time,
    // Output signals
    out_valid, out_display, out_day
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [30:0] in_time;
output reg out_valid;
output reg [3:0] out_display;
output reg [2:0] out_day;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
parameter IDLE   = 2'b00;
parameter INPUT  = 2'b01;
parameter CALCU  = 2'b10;
parameter OUTPUT = 2'b11;

//================================================================
// Wire & Reg Declaration
//================================================================
reg [1:0] c_state;
reg [1:0] n_state;

reg [23:0] in_time_24bit;
reg [6:0]  in_time_7bit;
reg [15:0] total_day;
reg [16:0] total_sec;
reg [5:0] num_4year;
reg [2:0] today;
reg [11:0] sec_in_one_hour;
reg [10:0] day_in_four_years;
reg [10:0] year;
reg [3:0] month;
reg [4:0] day;
reg [4:0] hour;
reg [5:0] minute;
reg [5:0] second;



wire [15:0] out_year ;
wire [7:0] out_month;
wire [7:0] out_date;
wire [7:0] out_hour;
wire [7:0] out_minute;
wire [7:0] out_second;

reg [3:0] calcu_counter;
reg [3:0] output_counter;
//================================================================
// DESIGN
//================================================================

//======================
// 		  FSM
//======================
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
			if(calcu_counter ==3) n_state = OUTPUT;
			else n_state = CALCU;
		end
		OUTPUT: begin
			if(output_counter==14) n_state = IDLE;
			else n_state = OUTPUT;
		end	
	endcase

end

//======================
//	  Calculation
//======================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) in_time_24bit <= 0;
	else begin
		if(n_state == INPUT) in_time_24bit <= in_time[30:7];
		else in_time_24bit <= in_time_24bit;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) in_time_7bit <= 0;
	else begin
		if(n_state == INPUT) in_time_7bit <= in_time[6:0];
		else in_time_7bit <= in_time_7bit;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) total_day <= 0;
	else begin
		if(n_state == CALCU) total_day <= in_time_24bit/10'd675+1;
		else total_day <= total_day;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) total_sec <= 0;
	else begin
		case(calcu_counter) 
			4'd0: total_sec <= (in_time_24bit%10'd675);
			4'd1: total_sec <= total_sec<<7;
			4'd2: total_sec <= total_sec+in_time_7bit;
			default: total_sec <= total_sec;
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) today <= 0;
	else begin
		if(c_state == CALCU) begin
			case(total_day%7)
				3'd0: today <= 3'd3;
				3'd1: today <= 3'd4;
				3'd2: today <= 3'd5;
				3'd3: today <= 3'd6;
				3'd4: today <= 3'd0;
				3'd5: today <= 3'd1;
				default: today <= 3'd2;
			endcase
		end
		else today <= today;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) sec_in_one_hour <= 0;
	else begin
		case(calcu_counter)
			4'd3: sec_in_one_hour <= (total_sec[16:4] % 8'd225);
			4'd4: sec_in_one_hour <= sec_in_one_hour<<4;
			4'd5: sec_in_one_hour <= sec_in_one_hour+total_sec[3:0];
			default: sec_in_one_hour <= sec_in_one_hour;
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) day_in_four_years <= 0;
	else begin
		if(n_state == CALCU) day_in_four_years <= total_day % 11'd1461;
		else day_in_four_years <= day_in_four_years;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) num_4year <= 0;
	else begin
		case(calcu_counter)
			4'd1: num_4year <= total_day/9'd487;
			4'd2: num_4year <= num_4year/2'd3;
			default: num_4year <= num_4year;
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) year <= 0;
	else begin
		if(c_state == CALCU) begin
			case(calcu_counter)
				4'd3: begin
					if(day_in_four_years<366) begin
						if(day_in_four_years == 0) year <= (num_4year<<2)+1969;
						else year <= (num_4year<<2)+1970;
					end
					else if(day_in_four_years<731) year <= (num_4year<<2)+1971;
					else if(day_in_four_years<1097) year <= (num_4year<<2)+1972;
					else year <= (num_4year<<2)+1973;
				end
				default: year <= year;
			endcase
		end
		else year <= year;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) month <= 0;
	else begin
		if(day_in_four_years<366) begin //-------------First year
			if(day_in_four_years<182) begin //Jan to Jun
				if(day_in_four_years<91) begin //Jan to Mar
					if(day_in_four_years == 0) month <= 12;
					else if(day_in_four_years<32) month <= 1; 
					else if(day_in_four_years<60) month <= 2;
					else month <= 3;
				end
				else begin //Apr to Jun
					if(day_in_four_years<121) month <=4;
					else if(day_in_four_years<152) month <= 5;
					else month <= 6;
				end
			end
			else begin //July to Dec
				if(day_in_four_years<274) begin //Jul to Sep
					if(day_in_four_years<213) month <= 7; 
					else if(day_in_four_years<244) month <= 8;
					else month <= 9;
				end
				else begin //Oct to Dec
					if(day_in_four_years<305) month <=10;
					else if(day_in_four_years<335) month <= 11;
					else month <= 12;
				end
			end
		end
		else if(day_in_four_years<731) begin //-------------Second year
			if(day_in_four_years<547) begin //Jan to Jun
				if(day_in_four_years<456) begin //Jan to Mar
					if(day_in_four_years<397) month <= 1; 
					else if(day_in_four_years<425) month <= 2;
					else month <= 3;
				end
				else begin //Apr to Jun
					if(day_in_four_years<486) month <=4;
					else if(day_in_four_years<517) month <= 5;
					else month <= 6;
				end
			end
			else begin //July to Dec
				if(day_in_four_years<639) begin //Jul to Sep
					if(day_in_four_years<578) month <= 7; 
					else if(day_in_four_years<609) month <= 8;
					else month <= 9;
				end
				else begin //Oct to Dec
					if(day_in_four_years<670) month <=10;
					else if(day_in_four_years<700) month <= 11;
					else month <= 12;
				end
			end
		end
		else if(day_in_four_years<1097) begin //-------------Third year
			if(day_in_four_years<913) begin //Jan to Jun
				if(day_in_four_years<822) begin //Jan to Mar
					if(day_in_four_years<762) month <= 1; 
					else if(day_in_four_years<791) month <= 2;
					else month <= 3;
				end
				else begin //Apr to Jun
					if(day_in_four_years<852) month <=4;
					else if(day_in_four_years<883) month <= 5;
					else month <= 6;
				end
			end
			else begin //July to Dec
				if(day_in_four_years<1005) begin //Jul to Sep
					if(day_in_four_years<944) month <= 7; 
					else if(day_in_four_years<975) month <= 8;
					else month <= 9;
				end
				else begin //Oct to Dec
					if(day_in_four_years<1036) month <=10;
					else if(day_in_four_years<1066) month <= 11;
					else month <= 12;
				end
			end
		end
		else begin //-------------Fourth year
			if(day_in_four_years<1278) begin //Jan to Jun
				if(day_in_four_years<1187) begin //Jan to Mar
					if(day_in_four_years<1128) month <= 1; 
					else if(day_in_four_years<1156) month <= 2;
					else month <= 3;
				end
				else begin //Apr to Jun
					if(day_in_four_years<1217) month <=4;
					else if(day_in_four_years<1248) month <= 5;
					else month <= 6;
				end
			end
			else begin //July to Dec
				if(day_in_four_years<1370) begin //Jul to Sep
					if(day_in_four_years<1309) month <= 7; 
					else if(day_in_four_years<1340) month <= 8;
					else month <= 9;
				end
				else begin //Oct to Dec
					if(day_in_four_years<1401) month <=10;
					else if(day_in_four_years<1431) month <= 11;
					else month <= 12;
				end
			end
		end
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) day <= 0;
	else begin
		if(day_in_four_years<366) begin //-------------First year
			if(day_in_four_years<182) begin //Jan to Jun
				if(day_in_four_years<91) begin //Jan to Mar
					if(day_in_four_years == 0) day <= 31;
					else if(day_in_four_years<32) day <= day_in_four_years; 
					else if(day_in_four_years<60) day <= day_in_four_years-31;
					else day <= day_in_four_years-59;
				end
				else begin //Apr to Jun
					if(day_in_four_years<121) day <= day_in_four_years-90;
					else if(day_in_four_years<152) day <= day_in_four_years-120;
					else day <= day_in_four_years-151;
				end
			end
			else begin //July to Dec
				if(day_in_four_years<274) begin //Jul to Sep
					if(day_in_four_years<213) day <= day_in_four_years-181; 
					else if(day_in_four_years<244) day <= day_in_four_years-212;
					else day <= day_in_four_years-243;
				end
				else begin //Oct to Dec
					if(day_in_four_years<305) day <= day_in_four_years-273;
					else if(day_in_four_years<335) day <= day_in_four_years-304;
					else day <= day_in_four_years-334;
				end
			end
		end
		else if(day_in_four_years<731) begin //-------------Second year
			if(day_in_four_years<547) begin //Jan to Jun
				if(day_in_four_years<456) begin //Jan to Mar
					if(day_in_four_years<397) day <= day_in_four_years-365; 
					else if(day_in_four_years<425) day <= day_in_four_years-396;
					else day <= day_in_four_years-424;
				end
				else begin //Apr to Jun
					if(day_in_four_years<486) day <= day_in_four_years-455;
					else if(day_in_four_years<517) day <= day_in_four_years-485;
					else day <= day_in_four_years-516;
				end
			end
			else begin //July to Dec
				if(day_in_four_years<639) begin //Jul to Sep
					if(day_in_four_years<578) day <= day_in_four_years-546; 
					else if(day_in_four_years<609) day <= day_in_four_years-577;
					else day <= day_in_four_years-608;
				end
				else begin //Oct to Dec
					if(day_in_four_years<670) day <= day_in_four_years-638;
					else if(day_in_four_years<700) day <= day_in_four_years-669;
					else day <= day_in_four_years-699;
				end
			end
		end
		else if(day_in_four_years<1097) begin //-------------Third year
			if(day_in_four_years<913) begin //Jan to Jun
				if(day_in_four_years<822) begin //Jan to Mar
					if(day_in_four_years<762) day <= day_in_four_years-730; 
					else if(day_in_four_years<791) day <= day_in_four_years-761;
					else day <= day_in_four_years-790;
				end
				else begin //Apr to Jun
					if(day_in_four_years<852) day <= day_in_four_years-821;
					else if(day_in_four_years<883) day <= day_in_four_years-851;
					else day <= day_in_four_years-882;
				end
			end
			else begin //July to Dec
				if(day_in_four_years<1005) begin //Jul to Sep
					if(day_in_four_years<944) day <= day_in_four_years-912; 
					else if(day_in_four_years<975) day <= day_in_four_years-943;
					else day <= day_in_four_years-974;
				end
				else begin //Oct to Dec
					if(day_in_four_years<1036) day <= day_in_four_years-1004;
					else if(day_in_four_years<1066) day <= day_in_four_years-1035;
					else day <= day_in_four_years-1065;
				end
			end
		end
		else begin //-------------Fourth year
			if(day_in_four_years<1278) begin //Jan to Jun
				if(day_in_four_years<1187) begin //Jan to Mar
					if(day_in_four_years<1128) day <= day_in_four_years-1096; 
					else if(day_in_four_years<1156) day <= day_in_four_years-1127;
					else day <= day_in_four_years-1155;
				end
				else begin //Apr to Jun
					if(day_in_four_years<1217) day <= day_in_four_years-1186;
					else if(day_in_four_years<1248) day <= day_in_four_years-1216;
					else day <= day_in_four_years-1247;
				end
			end
			else begin //July to Dec
				if(day_in_four_years<1370) begin //Jul to Sep
					if(day_in_four_years<1309) day <= day_in_four_years-1277; 
					else if(day_in_four_years<1340) day <= day_in_four_years-1308;
					else day <= day_in_four_years-1339;
				end
				else begin //Oct to Dec
					if(day_in_four_years<1401) day <= day_in_four_years-1369;
					else if(day_in_four_years<1431) day <= day_in_four_years-1400;
					else day <= day_in_four_years-1430;
				end
			end
		end
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) hour <= 0;
	else begin
		case(calcu_counter)
			4'd3: hour <= total_sec[16:4] / 8'd225;
			default: hour <= hour;
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) minute <= 0;
	else begin
		case(calcu_counter)
			4'd6: minute <= sec_in_one_hour[11:2] / 4'd15;
			default: minute <= minute;
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) second <= 0;
	else begin
		case(calcu_counter)
			4'd6: second <= (sec_in_one_hour[11:2] % 4'd15);
			4'd7: second <= second <<2;
			4'd8: second <= second +sec_in_one_hour[1:0];
			default: second <= second;
		endcase
	end
end

//======================
//    IP Block
//======================
B2BCD_IP #(.WIDTH(11), .DIGIT(4)) I_B2BCD_IP1 ( .Binary_code(year), .BCD_code(out_year) );
B2BCD_IP #(.WIDTH(4), .DIGIT(2)) I_B2BCD_IP2 ( .Binary_code(month), .BCD_code(out_month) );
B2BCD_IP #(.WIDTH(5), .DIGIT(2)) I_B2BCD_IP3 ( .Binary_code(day), .BCD_code(out_date) );
B2BCD_IP #(.WIDTH(5), .DIGIT(2)) I_B2BCD_IP4 ( .Binary_code(hour), .BCD_code(out_hour) );
B2BCD_IP #(.WIDTH(6), .DIGIT(2)) I_B2BCD_IP5 ( .Binary_code(minute), .BCD_code(out_minute) );
B2BCD_IP #(.WIDTH(6), .DIGIT(2)) I_B2BCD_IP6 ( .Binary_code(second), .BCD_code(out_second) );
//======================
//    Counter Block
//======================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) calcu_counter <= 0;
	else begin
		if(n_state == CALCU) calcu_counter <= calcu_counter+1;
		else if(n_state == OUTPUT) calcu_counter <= calcu_counter+1;
		else calcu_counter <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) output_counter <= 0;
	else begin
		if(n_state == OUTPUT) output_counter <= output_counter+1;
		else output_counter <= 0;
	end
end
//======================
//	  Output block
//======================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
	else begin
		if(n_state == OUTPUT) begin
			out_valid <= 1;
		end
		else out_valid <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_display <= 0;
	else begin
		if(n_state == OUTPUT) begin
			case(output_counter)
				4'd0: begin
					if((num_4year>6 && day_in_four_years>730)||num_4year >7) out_display <= 2;
					else out_display <= 1;
				end
				4'd1: out_display <= out_year[11:8];
				4'd2: out_display <= out_year[7:4];
				4'd3: out_display <= out_year[3:0];
				4'd4: out_display <= out_month[7:4];
				4'd5: out_display <= out_month[3:0];
				4'd6: out_display <= out_date[7:4];
				4'd7: out_display <= out_date[3:0];
				4'd8: out_display <= out_hour[7:4];
				4'd9: out_display <= out_hour[3:0];
				4'd10: out_display <= out_minute[7:4];
				4'd11: out_display <= out_minute[3:0];
				4'd12: out_display <= out_second[7:4];
				default: out_display <= out_second[3:0];
			endcase
		end
		else out_display <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) out_day <= 0;
	else begin
		if(n_state == OUTPUT) begin
			//if(output_counter == 4'd13) 
			out_day <= today;
			//else out_day <= out_day;
		end
		else out_day <= 0;
	end
end

endmodule