//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : B2BCD_IP.v
//   Module Name : B2BCD_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module B2BCD_IP #(parameter WIDTH = 4, parameter DIGIT = 2) (
    // Input signals
    Binary_code,
    // Output signals
    BCD_code
);

// ===============================================================
// Declaration
// ===============================================================
input  [WIDTH-1:0]   Binary_code;
output [DIGIT*4-1:0] BCD_code;
wire [DIGIT*4+1:0] input_data;
wire [DIGIT*4+1:0] stage [WIDTH-4:0];
// ===============================================================
// Soft IP DESIGN
// ===============================================================
assign input_data = Binary_code;
genvar i,j,k;
generate
	for(i=0;i<=WIDTH-4;i=i+1) begin
		if(i!=0) assign stage[i][DIGIT*4+1:WIDTH-i+4*(i/3)+1] = stage[i-1][DIGIT*4+1:WIDTH-i+4*(i/3)+1];
		if(i!=0) assign stage[i][WIDTH-i-4:0] = stage[i-1][WIDTH-i-4:0];
		for(j = 0; j<=i/3;j=j+1) begin
			if(i==0&&j==0) begin
				assign stage[i][DIGIT*4+1:WIDTH+1] = 0;
				assign stage[i][WIDTH-i+4*j-4:0] = input_data[WIDTH-i+4*j-4:0];
				assign stage[i][WIDTH-i+4*j -: 4] = (input_data[WIDTH-i+4*j -: 4] > 4)?input_data[WIDTH-i+4*j -: 4]+4'd3:input_data[WIDTH-i+4*j -: 4];
			end
			else begin 
				assign stage[i][WIDTH-i+4*j -: 4] = (stage[i-1][WIDTH-i+4*j -: 4] > 4)?stage[i-1][WIDTH-i+4*j -: 4]+4'd3:stage[i-1][WIDTH-i+4*j -: 4];
			end
		end
	end
endgenerate

assign BCD_code  = stage[WIDTH-4][DIGIT*4-1:0];

endmodule

