module HD(
	code_word1,
	code_word2,
	out_n
);
///************************
///	 input, output & wire  
///************************
input  [6:0]code_word1, code_word2;
output reg signed[5:0] out_n;
reg circle11, circle21;
reg circle12, circle22;
reg circle13, circle23;
reg EB1, EB2;
reg signed [3:0] c1;
reg signed [3:0] c2;
//************************
//	        Design         
//************************
// circle 1
always@(*) begin
	circle11 = code_word1[6]^code_word1[3]^code_word1[2]^code_word1[1];
end
always@(*) begin
	circle12 = code_word1[5]^code_word1[3]^code_word1[2]^code_word1[0];
end
always@(*) begin
	circle13 = code_word1[4]^code_word1[3]^code_word1[1]^code_word1[0];
end
// circle 2
always@(*) begin
	circle21 = code_word2[6]^code_word2[3]^code_word2[2]^code_word2[1];
end
always@(*) begin
	circle22 = code_word2[5]^code_word2[3]^code_word2[2]^code_word2[0];
end
always@(*) begin
	circle23 = code_word2[4]^code_word2[3]^code_word2[1]^code_word2[0];
end
always@(*) begin
	case({circle11, circle12, circle13})
		3'b110: EB1 = code_word1[2];
		3'b101: EB1 = code_word1[1];
		3'b011: EB1 = code_word1[0];
		3'b111: EB1 = code_word1[3];
		3'b001: EB1 = code_word1[4];
		3'b010: EB1 = code_word1[5];
		default: EB1 = code_word1[6];
	endcase
end
always@(*) begin
	case({circle21, circle22, circle23})
		3'b110: EB2 = code_word2[2];
		3'b101: EB2 = code_word2[1];
		3'b011: EB2 = code_word2[0];
		3'b111: EB2 = code_word2[3];
		3'b001: EB2 = code_word2[4];
		3'b010: EB2 = code_word2[5];
		default: EB2 = code_word2[6];
	endcase
end
always@(*) begin
	case({circle11, circle12, circle13})
		3'b110: c1 = ({code_word1[3], !EB1, code_word1[1], code_word1[0]});
		3'b101: c1 = ({code_word1[3], code_word1[2], !EB1, code_word1[0]});
		3'b011: c1 = ({code_word1[3], code_word1[2], code_word1[1], !EB1});
		3'b111: c1 = ({!EB1, code_word1[2], code_word1[1], code_word1[0]});
		default: c1 = ({code_word1[3], code_word1[2], code_word1[1], code_word1[0]});
	endcase
end
always@(*) begin
	case({circle21, circle22, circle23})
		3'b110: c2 = ({code_word2[3], !EB2, code_word2[1], code_word2[0]});
		3'b101: c2 = ({code_word2[3], code_word2[2], !EB2, code_word2[0]});
		3'b011: c2 = ({code_word2[3], code_word2[2], code_word2[1], !EB2});
		3'b111: c2 = ({!EB2, code_word2[2], code_word2[1], code_word2[0]});
		default: c2 = ({code_word2[3], code_word2[2], code_word2[1], code_word2[0]});
	endcase
end
always@(*) begin
	case({EB1, EB2})
		2'b00: out_n = (c1<<<1)+c2;
		2'b01: out_n = (c1<<<1)-c2;
		2'b10: out_n = c1-(c2<<<1);
		2'b11: out_n = c1+(c2<<<1);
	endcase
end
endmodule

