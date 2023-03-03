`include "synchronizer.v"
`include "syn_XOR.v"
module CDC(
	//Input Port
	clk1,
    clk2,
    clk3,
	rst_n,
	in_valid1,
	in_valid2,
	user1,
	user2,

    //Output Port
    out_valid1,
    out_valid2,
	equal,
	exceed,
	winner
); 
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input 		clk1, clk2, clk3, rst_n;
input 		in_valid1, in_valid2;
input [3:0]	user1, user2;

output reg	out_valid1, out_valid2;
output reg	equal, exceed, winner;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
//----clk1----
reg in_valid_reg;
reg [3:0] user_reg;

reg [5:0] card_counter;
reg  epoch_counter;
reg [3:0] time_counter;
reg [3:0] user_clk3_counter;
reg [2:0] winner_clk3_counter;
reg [2:0] clk3_counter;


reg [2:0] point10_table;
reg [3:0] point9_table;
reg [3:0] point8_table;
reg [4:0] point7_table;
reg [4:0] point6_table;
reg [4:0] point5_table;
reg [4:0] point4_table;
reg [5:0] point3_table;
reg [5:0] point2_table;
reg [5:0] point1_table;

reg [4:0] temp1;
wire [6:0] temp2;
reg [6:0] temp3;

reg [5:0] cdf_diff_user1;
reg [6:0] equal_clk1;
reg [6:0] equal_clk3;
reg [5:0] cdf_diff_user2;
reg [6:0] exceed_clk1;
reg [6:0] exceed_clk3;

reg  [1:0] winner_clk1;
reg  [1:0] winner_clk3;
reg  flag_clk1; 
wire flag_clk3;  

//----clk2----

//----clk3----

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
//----clk1----;

//----clk2----

//----clk3----

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
//============================================
//   clk1 domain
//============================================
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		card_counter <= 0;
	end else begin
		if(in_valid_reg ) begin
			if(card_counter!=49) card_counter <= card_counter + 1;
			else card_counter <= 0;
		end
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		epoch_counter <= 0;
	end
	else begin
		if(card_counter == 49) epoch_counter <= 1;
		else epoch_counter <= 0;
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		time_counter <= 0;
	end else begin
		if(in_valid_reg) begin
			if(time_counter!=9) time_counter <= time_counter + 1;
			else time_counter <= 0;
		end
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		in_valid_reg <= 0;
	end
	else begin
		if(in_valid1) in_valid_reg <= in_valid1;
		else if(in_valid2) in_valid_reg <= in_valid2;
		else in_valid_reg <= 0;
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		user_reg <= 0;
	end
	else begin
		if(in_valid1) user_reg <= user1;
		else if(in_valid2) user_reg <= user2;
		else user_reg <= 0;
	end
end


always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) point10_table <= 4;
	else begin
		if(card_counter == 0) begin
			if(in_valid_reg) begin
				if(user_reg==10) point10_table <= 3;
				else point10_table <= 4;
			end
			else point10_table <= point10_table;
		end
		else begin
			if((user_reg==10)) point10_table <= point10_table-1;
			else point10_table <= point10_table;
		end	
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) point9_table <= 8;
	else begin
		if(card_counter == 0) begin
			if((user_reg>8)&&(user_reg<11)) point9_table <= 7;
			else point9_table <= 8;
		end
		else begin
			if(((user_reg>8)&&(user_reg<11))) point9_table <= point9_table-1;
			else point9_table <= point9_table;
		end	
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) point8_table <= 12;
	else begin
		if(card_counter == 0) begin
			if((user_reg>7)&&(user_reg<11)) point8_table <= 11;
			else point8_table <= 12;
		end
		else begin
			if(((user_reg>7)&&(user_reg<11))) point8_table <= point8_table-1;
			else point8_table <= point8_table;
		end	
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) point7_table <= 16;
	else begin
		if(card_counter == 0) begin
			if((user_reg>6)&&(user_reg<11)) point7_table <= 15;
			else point7_table <= 16;
		end
		else begin
			if(((user_reg>6)&&(user_reg<11))) point7_table <= point7_table-1;
			else point7_table <= point7_table;
		end	
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) point6_table <= 20;
	else begin
		if(card_counter == 0) begin
			if((user_reg>5)&&(user_reg<11)) point6_table <= 19;
			else point6_table <= 20;
		end
		else begin
			if(((user_reg>5)&&(user_reg<11))) point6_table <= point6_table-1;
			else point6_table <= point6_table;
		end	
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) point5_table <= 24;
	else begin
		if(card_counter == 0) begin
			if((user_reg>4)&&(user_reg<11)) point5_table <= 23;
			else point5_table <= 24;
		end
		else begin
			if(((user_reg>4)&&(user_reg<11))) point5_table <= point5_table-1;
			else point5_table <= point5_table;
		end	
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) point4_table <= 28;
	else begin
		if(card_counter == 0) begin
			if((user_reg>3)&&(user_reg<11)) point4_table <= 27;
			else point4_table <= 28;
		end
		else begin
			if(((user_reg>3)&&(user_reg<11))) point4_table <= point4_table-1;
			else point4_table <= point4_table;
		end	
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) point3_table <= 32;
	else begin
		if(card_counter == 0) begin
			if((user_reg>2)&&(user_reg<11)) point3_table <= 31;
			else point3_table <= 32;
		end
		else begin
			if(((user_reg>2)&&(user_reg<11))) point3_table <= point3_table-1;
			else point3_table <= point3_table;
		end	
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) point2_table <= 36;
	else begin
		if(card_counter == 0) begin
			if((user_reg>1)&&(user_reg<11)) point2_table <= 35;
			else point2_table <= 36;
		end
		else begin
			if(((user_reg>1)&&(user_reg<11))) point2_table <= point2_table-1;
			else point2_table <= point2_table;
		end	
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) point1_table <= 52;
	else begin
		if(card_counter == 0) begin
			if(user_reg>0) point1_table <= 51;
			else point1_table <= 52;
		end
		else begin
			if((user_reg>0)) point1_table <= point1_table-1;
			else point1_table <= point1_table;
		end	
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) cdf_diff_user1 <= 0;
	else begin
		if(in_valid_reg) begin
			case(time_counter) 
				4'd0: begin
					if(user_reg>10) cdf_diff_user1 <= 20;
					else cdf_diff_user1 <= 21 - user_reg;
				end
				4'd1, 4'd2, 4'd3, 4'd4: begin
					if(user_reg>10) cdf_diff_user1 <= cdf_diff_user1 - 1;
					else cdf_diff_user1 <= cdf_diff_user1 - user_reg;
				end
				default: cdf_diff_user1 <= cdf_diff_user1;
			endcase
		end	
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) cdf_diff_user2 <= 0;
	else begin
		if(in_valid_reg) begin
			case(time_counter) 
				4'd5: begin
					if(user_reg>10) cdf_diff_user2 <= 20;
					else cdf_diff_user2 <= 21 - user_reg;
				end
				4'd6, 4'd7, 4'd8, 4'd9: begin
					if(user_reg>10) cdf_diff_user2 <= cdf_diff_user2 - 1;
					else cdf_diff_user2 <= cdf_diff_user2 - user_reg;
				end
				default: cdf_diff_user2 <= cdf_diff_user2;
			endcase
		end	
	end
end
always@(*) begin
	if(time_counter<6) begin
		case(cdf_diff_user1)
			6'd1: temp1 = point1_table - point2_table;
			6'd2: temp1 = point2_table - point3_table;
			6'd3: temp1 = point3_table - point4_table;
			6'd4: temp1 = point4_table - point5_table;
			6'd5: temp1 = point5_table - point6_table;
			6'd6: temp1 = point6_table - point7_table;
			6'd7: temp1 = point7_table - point8_table;
			6'd8: temp1 = point8_table - point9_table;
			6'd9: temp1 = point9_table - point10_table;
			6'd10: temp1 = point10_table;
			default: temp1 = 0;
		endcase
	end
	else begin
		case(cdf_diff_user2)
			6'd1: temp1 = point1_table - point2_table;
			6'd2: temp1 = point2_table - point3_table;
			6'd3: temp1 = point3_table - point4_table;
			6'd4: temp1 = point4_table - point5_table;
			6'd5: temp1 = point5_table - point6_table;
			6'd6: temp1 = point6_table - point7_table;
			6'd7: temp1 = point7_table - point8_table;
			6'd8: temp1 = point8_table - point9_table;
			6'd9: temp1 = point9_table - point10_table;
			6'd10: temp1 = point10_table;
			default: temp1 = 0;
		endcase
	end
end

always@(*) begin
	if(time_counter<6) begin
		case(cdf_diff_user1)
			6'd0: temp3 = 100;
			6'd1: temp3 = point2_table;
			6'd2: temp3 = point3_table;
			6'd3: temp3 = point4_table;
			6'd4: temp3 = point5_table;
			6'd5: temp3 = point6_table;
			6'd6: temp3 = point7_table;
			6'd7: temp3 = point8_table;
			6'd8: temp3 = point9_table;
			6'd9: temp3 = point10_table;
			default: begin
				if(cdf_diff_user1<19) temp3 = 0;
				else temp3 = 100;
			end
		endcase
	end
	else begin
		case(cdf_diff_user2)
			6'd0: temp3 = 100;
			6'd1: temp3 = point2_table;
			6'd2: temp3 = point3_table;
			6'd3: temp3 = point4_table;
			6'd4: temp3 = point5_table;
			6'd5: temp3 = point6_table;
			6'd6: temp3 = point7_table;
			6'd7: temp3 = point8_table;
			6'd8: temp3 = point9_table;
			6'd9: temp3 = point10_table;
			default: begin
				if(cdf_diff_user2<19) temp3 = 0;
				else temp3 = 100;
			end
		endcase
	end
end
assign temp2 = ({temp1,6'b0}+{temp1,5'd0}+{temp1,2'd0})/point1_table;
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) equal_clk1 <= 0;
	else begin
		if(time_counter < 6) begin
			if(cdf_diff_user1>20) equal_clk1 <= 0;
			else begin
				equal_clk1 <= temp2;
			end
		end
		else begin
			if(cdf_diff_user2>20) equal_clk1 <= 0;
			else begin
				equal_clk1 <= temp2;
			end
		end
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) exceed_clk1 <= 0;
	else begin
		if(temp3==100) exceed_clk1 <= temp3;
		else exceed_clk1 <= ({temp3,6'b0}+{temp3,5'd0}+{temp3,2'd0})/point1_table;
	end
end
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) winner_clk1 <= 0;
	else begin
		if((card_counter>9)||(epoch_counter)) begin
			if(time_counter==0) begin
				if((cdf_diff_user1<19)&&(cdf_diff_user2<19)) begin
					if(cdf_diff_user1==cdf_diff_user2) winner_clk1 <= 2'b00;
					else if(cdf_diff_user1 < cdf_diff_user2) winner_clk1 <= 2'b10;
					else winner_clk1 <= 2'b11;
				end
				else if((cdf_diff_user1<19)&&(cdf_diff_user2>19)) begin
					winner_clk1 <= 2'b10;
				end
				else if((cdf_diff_user1>19)&&(cdf_diff_user2<19)) begin
					winner_clk1 <= 2'b11;
				end
				else begin
					winner_clk1 <= 2'b00;
				end
			end
			else winner_clk1 <= winner_clk1;
		end
		else begin
			winner_clk1 <= winner_clk1;
		end
	end
end
always@(*) begin
	if(card_counter>2) begin
		if((time_counter==4)||(time_counter==3)) begin
			flag_clk1 = 1;
		end
		else if((time_counter==9)||(time_counter==8)) begin
			flag_clk1 = 1;
		end
		else if(time_counter==0) begin
			flag_clk1 = 1;
		end
		else flag_clk1 = 0;
	end
	else if(epoch_counter) flag_clk1 = (time_counter==0)? 1:0;
	else begin
		flag_clk1 = 0;
	end
end

//============================================
//   clk2 domain
//============================================
//always@(posedge clk2 or negedge rst_n) begin
//	if(!rst_n) begin
//		
//	end else begin
//		
//	end
//end
//============================================
//   clk3 domain
//============================================
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		equal_clk3 <= 0;
	end 
	else begin
		if((flag_clk3)&&((clk3_counter==5)||(clk3_counter<4))) begin
			equal_clk3 <= equal_clk1;
		end
		else equal_clk3 <= equal_clk3;
	end
end
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		exceed_clk3 <= 0;
	end 
	else begin
		if((flag_clk3)&&((clk3_counter==5)||(clk3_counter<4))) exceed_clk3 <= exceed_clk1;
		else exceed_clk3 <= exceed_clk3;
	end
end
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		winner_clk3 <= 0;
	end 
	else begin
		if((flag_clk3)&&(clk3_counter==4)) winner_clk3 <= winner_clk1;
		else winner_clk3 <= winner_clk3;
	end
end
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) user_clk3_counter <= 8;
	else begin
		if(flag_clk3&&((clk3_counter==5)||(clk3_counter<4))) user_clk3_counter <= 0;
		else begin
			if(user_clk3_counter ==8) user_clk3_counter <= 8;
			else user_clk3_counter <= user_clk3_counter + 1;
		end
	
	end
end
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) winner_clk3_counter <= 7;
	else begin
		if(flag_clk3&&(clk3_counter==4)) winner_clk3_counter <= 0;
		else begin
			if(winner_clk3_counter ==7) winner_clk3_counter <= 7;
			else winner_clk3_counter <= winner_clk3_counter + 1;
		end
	end
end
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) clk3_counter <= 0;
	else begin
		if(clk3_counter!=5) begin
			if(flag_clk3) begin
				clk3_counter <= clk3_counter + 1;
			end
			else clk3_counter <= clk3_counter;
		end
		else begin
			if(flag_clk3) clk3_counter <= 1;
			else clk3_counter <= clk3_counter;
		end
	end
end
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		out_valid1 <= 0;
	end 
	else begin
		if((user_clk3_counter<7)) out_valid1 <= 1;
		else out_valid1 <= 0;
	end
end
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		out_valid2 <= 0;
	end 
	else begin
		if(winner_clk3_counter<2) begin
			if(winner_clk3_counter==0) begin
				out_valid2 <= 1;
			end
			else begin
				if(winner_clk3[1]==0) out_valid2 <= 0;
				else out_valid2 <= 1;
			end
		end
		else out_valid2 <= 0;
	end
end
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		equal <= 0;
	end 
	else begin
		case(user_clk3_counter)
			4'd0: equal <= equal_clk3[6];
			4'd1: equal <= equal_clk3[5];
			4'd2: equal <= equal_clk3[4];
			4'd3: equal <= equal_clk3[3];
			4'd4: equal <= equal_clk3[2];
			4'd5: equal <= equal_clk3[1];
			4'd6: equal <= equal_clk3[0];
			default: equal <= 0;
		endcase
	end
end
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		exceed <= 0;
	end 
	else begin
		case(user_clk3_counter)
			4'd0: exceed <= exceed_clk3[6];
			4'd1: exceed <= exceed_clk3[5];
			4'd2: exceed <= exceed_clk3[4];
			4'd3: exceed <= exceed_clk3[3];
			4'd4: exceed <= exceed_clk3[2];
			4'd5: exceed <= exceed_clk3[1];
			4'd6: exceed <= exceed_clk3[0];
			default: exceed <= 0;
		endcase
	end
end
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		winner <= 0;
	end 
	else begin
		if(winner_clk3_counter==0) winner <= winner_clk3[1];
		else if(winner_clk3_counter==1) winner <= winner_clk3[0];
		else winner <= 0;
	end
end
//---------------------------------------------------------------------
//   syn_XOR
//---------------------------------------------------------------------
syn_XOR u_syn_XOR1(.IN(flag_clk1),.OUT(flag_clk3),.TX_CLK(clk1),.RX_CLK(clk3),.RST_N(rst_n));


endmodule