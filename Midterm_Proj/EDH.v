//synopsys translate_off
`include "DW_minmax.v"
`include "DW_div.v"
//synopsys translate_on
module EDH(
	// input signals
	clk,
	rst_n,
	in_valid,
	pic_no,
	se_no,
	op,
	// output signals
	busy,
	//==========================================
	// axi write address channel 
	
	//-----Master-----
	awid_m_inf,
	awaddr_m_inf,
	awsize_m_inf,
	awburst_m_inf,
	awlen_m_inf,
	awvalid_m_inf,
	//-----Slave-----
	awready_m_inf,
	
	//==========================================
	// axi write data channel 
	
	//-----Master-----
	wdata_m_inf,
	wlast_m_inf,
	wvalid_m_inf,
	//-----Slave-----
	wready_m_inf,
	
	//==========================================
	// axi write response channel
	
	//-----Slave-----
	bid_m_inf,
	bresp_m_inf,
	bvalid_m_inf,
	//-----Master-----
	bready_m_inf,
	
	//==========================================
	// axi read address channel 
	
	//-----Master-----
	arid_m_inf,
	araddr_m_inf,
	arlen_m_inf,
	arsize_m_inf,
	arburst_m_inf,
	arvalid_m_inf,
	//-----Slave-----
	arready_m_inf,
	
	//==========================================
	// axi read data channel 
	
	//-----Slave-----
	rid_m_inf,
	rdata_m_inf,
	rresp_m_inf,
	rlast_m_inf,
	rvalid_m_inf,
	//-----Master-----
	rready_m_inf
	
	);
//======================================
//          I/O PORTS
//======================================
input         clk;
input         rst_n;
input         in_valid;
input [3:0]   pic_no;
input [5:0]   se_no;
input [1:0]   op;
output reg    busy;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 128;
// ----------------------------------------------------------
// axi write address channel 
//-----Master-----
output     [ID_WIDTH-1:0]       awid_m_inf;
output reg [ADDR_WIDTH-1:0]     awaddr_m_inf;
output     [2:0]                awsize_m_inf;
output     [1:0]                awburst_m_inf;
output     [7:0]                awlen_m_inf;
output reg                      awvalid_m_inf;
//-----Slave-----
input                           awready_m_inf;
// ----------------------------------------------------------
// axi write data channel 
//-----Master-----
output reg [DATA_WIDTH-1:0]     wdata_m_inf;
output reg                      wlast_m_inf;
output reg                      wvalid_m_inf;
//-----Slave-----
input                           wready_m_inf;
// ----------------------------------------------------------
// axi write response channel
//-----Slave-----
input [ID_WIDTH-1:0]            bid_m_inf;
input [1:0]                     bresp_m_inf;
input                           bvalid_m_inf;
//-----Master-----
output reg                      bready_m_inf;
// ----------------------------------------------------------
// axi read address channel 
//-----Master-----
output        [ID_WIDTH-1:0]    arid_m_inf;
output reg    [ADDR_WIDTH-1:0]  araddr_m_inf;
output        [7:0]             arlen_m_inf;
output        [2:0]             arsize_m_inf;
output        [1:0]             arburst_m_inf;
output reg                      arvalid_m_inf;
//-----Slave-----
input                           arready_m_inf;
// -----------------------------------------------------------
// axi read data channel 
//-----Slave-----
input [ID_WIDTH-1:0]            rid_m_inf;
input [DATA_WIDTH-1:0]          rdata_m_inf;
input [1:0]                     rresp_m_inf;
input                           rlast_m_inf;
input                           rvalid_m_inf;
//-----Master-----
output reg                      rready_m_inf;

//======================================
//      PARAMETERS & VARIABLES
//======================================
parameter IDLE            = 4'd0;
parameter INPUT           = 4'd1;
parameter READ_SE_ADDR    = 4'd2;
parameter READ_SE_DATA    = 4'd3;
parameter READ_PIC_ADDR   = 4'd4;
parameter READ_PIC_DATA   = 4'd5;
parameter EROS            = 4'd6;
parameter DILA_A          = 4'd7;
parameter DILA_B          = 4'd8;
parameter HIST_A          = 4'd9;
parameter HIST_B		  = 4'd13;
parameter HIST_C          = 4'd10;
parameter WRITE_DRAM_ADDR = 4'd11;
parameter WRITE_DRAM_DATA = 4'd12;
integer i;
//======================================
//      	REGS & WIRES
//======================================
reg [3:0] c_state;
reg [3:0] n_state;

reg [1:0] operation;

reg [31:0] pic_address;
reg [31:0] se_address;

reg [127:0] se_elements;

reg  [7:0]   pic_A;
reg  [127:0] pic_D;
wire [127:0] pic_Q;
reg          pic_WEN;

reg flag_DILA;
reg [7:0] pic_counter; // For HIST
reg [1:0] catch_pic_counter; //for DILA_A and EROS
reg [6:0] row_counter;
reg [8:0] DILA_counter;
reg [8:0] div_counter;
reg [8:0] w_DRAM_counter;

reg [7:0] row1 [63:0];
reg [7:0] row2 [63:0];
reg [7:0] row3 [63:0];
reg [7:0] row4 [63:0];

reg [255:0] record [15:0];
reg [19:0] cdf_table[255:0];


wire [7:0]   temp_min;
wire [3:0]   index_min;
reg  [11:0]  min;
wire [127:0] ED_group[15:0];
wire [7:0]   ED_minmax[15:0];
wire max_min_mode;
wire [3:0]   ED_index[15:0];
reg  [12:0]  temp [255:0];
reg  [12:0]  temp_quotient;

reg  [19:0] hist_div;
reg  [11:0] hist_div_b;
wire [19:0] quotient;
wire [11:0] remainder;
wire pin;

reg [7:0] kernel  [15:0];

reg [127:0] write_data;
reg [7:0] item_data [15:0];

//======================================
//      CONSTANT AXI SIGNALs
//======================================
// Write Address Channel
assign awid_m_inf    = 0;		// recongnize the master
assign awlen_m_inf   = 8'd255;   // give the number of transfer in a burst
assign awsize_m_inf  = 3'b100;  // 16 bytes in each transfer
assign awburst_m_inf = 2'b01;   // details the address for each transfer within the burst is calculated (we use "INCR")
// Read Address Channel
assign arid_m_inf    = 0;       // recongnize the master
assign arlen_m_inf   = (c_state == READ_SE_ADDR || c_state == READ_SE_DATA)?8'd0:8'd255;   // give the number of transfer in a burst  -------select 16*16 or 64*64 image
assign arsize_m_inf  = 3'b100;  // 16 bytes in each transfer
assign arburst_m_inf = 2'b01;   // details the address for each transfer within the burst is calculated (we use "INCR")

//======================================
//      	FSM Block
//======================================
always@(posedge clk or negedge rst_n) begin
	if(~rst_n) c_state <= IDLE;
	else c_state <= n_state;
end
always@(*) begin
	case(c_state)
		IDLE : n_state = (in_valid)?  INPUT : IDLE;
		INPUT: n_state = (!in_valid)? READ_SE_ADDR : INPUT;
		READ_SE_ADDR : begin
			if(arready_m_inf) begin
				n_state = READ_SE_DATA;
			end
			else n_state = READ_SE_ADDR;
		end
		READ_SE_DATA: begin
			if(rlast_m_inf) begin
				n_state = READ_PIC_ADDR;
			end
			else n_state = READ_SE_DATA;
		end
		READ_PIC_ADDR: begin
			if(arready_m_inf) begin
				n_state = READ_PIC_DATA;
			end
			else n_state = READ_PIC_ADDR;
		end
		READ_PIC_DATA: begin	
			if(rlast_m_inf) begin
				case(operation)
					2'b00:   n_state = EROS;
					2'b01:   n_state = DILA_A;
					default: n_state = HIST_A;
				endcase
			end
			else n_state = READ_PIC_DATA;
		end
		HIST_A: n_state = HIST_B;
		HIST_B: n_state = HIST_C;
		HIST_C: begin
			if(div_counter == 257) n_state = WRITE_DRAM_ADDR;
			else n_state = HIST_C;
		end
		EROS: begin
			if(DILA_counter == 255) n_state = WRITE_DRAM_ADDR;
			else n_state = EROS;
		end
		DILA_A: begin
			if(DILA_counter == 254) n_state = DILA_B;
			else n_state = DILA_A;
		end
		DILA_B: begin
			if(row_counter == 69) n_state = WRITE_DRAM_ADDR;
			else n_state = DILA_B;
		end
		WRITE_DRAM_ADDR: begin
			if(awready_m_inf) n_state = WRITE_DRAM_DATA;
			else n_state = WRITE_DRAM_ADDR;
		end
		WRITE_DRAM_DATA: begin
			if(w_DRAM_counter == 258) n_state = IDLE;
			else n_state = WRITE_DRAM_DATA;
		end
		default: n_state = c_state;
	endcase
end
//======================================
//      	Counter Block
//======================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) pic_counter <= 0;
	else begin
		if(c_state == READ_PIC_DATA) begin
			if(rvalid_m_inf) pic_counter <= pic_counter+1;
			else pic_counter <= 0;
		end
		else pic_counter <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) catch_pic_counter <= 0;
	else begin
		if(c_state == READ_PIC_DATA) begin
			if(rvalid_m_inf) begin
				if(catch_pic_counter == 3) catch_pic_counter <= 0;
				else catch_pic_counter <= catch_pic_counter+1;
			end
			else catch_pic_counter <= 0;
		end
		else if((c_state == DILA_A)||(c_state == EROS)) begin
			if(catch_pic_counter == 3) catch_pic_counter <= 0;
			else catch_pic_counter <= catch_pic_counter+1;
		end
		else catch_pic_counter <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) row_counter <= 0;
	else begin
		case(c_state) 
			READ_PIC_DATA: begin
				if(rvalid_m_inf) begin
					if(catch_pic_counter==3) row_counter <= row_counter+1;
					else row_counter <= row_counter;
				end
				else row_counter <= 0;
			end
			EROS, DILA_A: begin
				if(catch_pic_counter==3) row_counter <= row_counter+1;
				else row_counter <= row_counter;
			end
			DILA_B: row_counter <= row_counter + 1;
			default: row_counter <= 0;
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) DILA_counter <= 0;
	else begin
		case(c_state) 
			READ_PIC_DATA: begin
				if(row_counter>3) begin
					if(row_counter==4) begin
						DILA_counter <= (catch_pic_counter>0)? DILA_counter+1 : DILA_counter;
					end
					else DILA_counter <= DILA_counter +1;
				end
				else DILA_counter <= 0;
			end
			EROS, DILA_B, DILA_A: DILA_counter <= DILA_counter + 1;
			default: DILA_counter <= 0;
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) div_counter <= 0;
	else begin
		if(c_state == HIST_C) div_counter <= div_counter+1;
		else if(c_state == IDLE) div_counter <= 0;
		else div_counter <= div_counter;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) w_DRAM_counter <= 0;
	else begin
		if(c_state == WRITE_DRAM_DATA) begin
			if(wready_m_inf) w_DRAM_counter <= w_DRAM_counter+1;
			else w_DRAM_counter <= 0;
		end
		else w_DRAM_counter <= 0;
	end
end
//======================================
//      	Flag Block
//======================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) flag_DILA <= 0;
	else begin
		if(operation==2'b01&&row_counter==4&&catch_pic_counter==0) flag_DILA <= 1;
		else if(DILA_counter == 254) flag_DILA <= 0;
		else flag_DILA <= flag_DILA;
	end
end
//======================================
//      	INPUT Block
//======================================

//------------INPUT STATE----------------
always@(posedge clk or negedge rst_n) begin
	if(~rst_n) operation <= 0;
	else begin
		if(n_state == INPUT) operation <= op;
		else operation <= operation;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(~rst_n) pic_address <= 0;
	else begin
		if(n_state == INPUT) pic_address <= {12'd0, 4'b0100, pic_no, 12'd0};
		else pic_address <= pic_address;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(~rst_n) se_address <= 0;
	else begin
		if(n_state == INPUT) se_address <= 32'h00030000+{se_no, 4'd0};
		else se_address <= se_address;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) se_elements <= 0;
	else begin
		if(c_state == READ_SE_DATA) se_elements <= (rvalid_m_inf)? rdata_m_inf : se_elements;
		else se_elements <= se_elements;
	end
end
//-------------READ STATE------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) arvalid_m_inf <= 0;
	else begin
		if(c_state == READ_PIC_ADDR)     arvalid_m_inf <= (n_state == READ_PIC_DATA)? 0:1;
		else if(c_state == READ_SE_ADDR) arvalid_m_inf <= (n_state == READ_SE_DATA)? 0:1;
		else arvalid_m_inf <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) araddr_m_inf <= 0;
	else begin
		if(c_state == READ_PIC_ADDR)     araddr_m_inf <= (n_state == READ_PIC_DATA)? 0:pic_address;
		else if(c_state == READ_SE_ADDR) araddr_m_inf <= (n_state == READ_SE_DATA)? 0:se_address;
		else araddr_m_inf <= araddr_m_inf;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) rready_m_inf <= 0;
	else begin
		if(c_state == READ_PIC_DATA) rready_m_inf <= 1;
		else if(c_state == READ_SE_DATA) rready_m_inf <= 1;
		else rready_m_inf <= 0;
	end
end
//-------------READ STATE------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) awaddr_m_inf <= 0;
	else begin
		if(n_state == WRITE_DRAM_ADDR) awaddr_m_inf <= pic_address;
		else awaddr_m_inf <= awaddr_m_inf;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) awvalid_m_inf <= 0;
	else begin
		if(n_state == WRITE_DRAM_ADDR) awvalid_m_inf <= 1;
		else awvalid_m_inf <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) wvalid_m_inf <= 0;
	else begin
		if(c_state == WRITE_DRAM_DATA) begin
			if(wready_m_inf ==0) wvalid_m_inf <= 1;
			else begin
				case(operation)
					2'b10: begin
						if(w_DRAM_counter>3) wvalid_m_inf <= 1;
						else wvalid_m_inf <= 0;
					end
					default: begin
						if(w_DRAM_counter>2) wvalid_m_inf <= 1;
						else wvalid_m_inf <= 0;
					end
				endcase
			end
		end
		else wvalid_m_inf <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) wdata_m_inf <= 0;
	else begin
		if(c_state == WRITE_DRAM_DATA) begin
			if(wready_m_inf ==0) wdata_m_inf <= write_data;
			else begin
				if(w_DRAM_counter>2) wdata_m_inf <= write_data;
				else wdata_m_inf <= 0;
			end
		end
		
		else wdata_m_inf <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) wlast_m_inf <= 0;
	else begin
		if(c_state == WRITE_DRAM_DATA) begin
			case(operation)
				2'b10: begin
					if(w_DRAM_counter == 258) wlast_m_inf <= 1;
					else wlast_m_inf <= 0;
				end
				default: begin
					if(w_DRAM_counter == 257) wlast_m_inf <= 1;
					else wlast_m_inf <= 0;
				end
			endcase
		end
		else wlast_m_inf <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) bready_m_inf <= 0;
	else begin
		if(c_state == WRITE_DRAM_DATA) begin
			bready_m_inf <= 1;
		end
		else if(c_state == IDLE) begin
			if(bvalid_m_inf) bready_m_inf <= 0;
			else bready_m_inf <= 1;
		end
		else bready_m_inf <= 0;
	end
end
//======================================
//      	MEM Block
//======================================
//-----------------PIC MEM------------------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) pic_WEN <= 1;
	else begin
		if(c_state ==  READ_PIC_DATA) begin
			case(operation)
				2'b01, 2'b00: begin
					if(row_counter==4&&catch_pic_counter==0) pic_WEN <= 0;  
					else pic_WEN <= pic_WEN;
				end
				default:pic_WEN <= (rvalid_m_inf)?0:1;
			endcase
		end
		else if((c_state == DILA_A)||(c_state == EROS)) pic_WEN <= 0;
		else if(c_state == DILA_B) begin
			 if(DILA_counter >= 256) pic_WEN <= 1;
			 else pic_WEN <= 0;
		end
		else pic_WEN <= 1;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) pic_A <= 0;
	else begin
		if(c_state == READ_PIC_DATA) begin
			if(rvalid_m_inf) begin
				case(operation)
					2'b01, 2'b00: pic_A <= DILA_counter;
					default: pic_A <= pic_counter;
				endcase
			end
		end
		else if((c_state == DILA_A)||(c_state == DILA_B)||(c_state == EROS)) begin
			pic_A <= DILA_counter;
		end
		else if(n_state == WRITE_DRAM_DATA) begin
			case(operation)
				2'b10: begin
					if(wready_m_inf) pic_A <= pic_A+1;
					else pic_A <= 0;
				end
				default : begin
					if(wready_m_inf ==0) pic_A <= 0;
					else begin
						pic_A <= pic_A+1;
					end
				end
			endcase
		end
		else pic_A <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) pic_D <= 0;
	else begin
		if(rvalid_m_inf) begin
			case(operation)
				2'b01, 2'b00: pic_D <= {ED_minmax[15],  ED_minmax[14],  ED_minmax[13], ED_minmax[12], 
								        ED_minmax[11],  ED_minmax[10],  ED_minmax[9],  ED_minmax[8], 
								        ED_minmax[7],   ED_minmax[6],   ED_minmax[5],  ED_minmax[4], 
								        ED_minmax[3],   ED_minmax[2],   ED_minmax[1],  ED_minmax[0]};
				default: pic_D <= rdata_m_inf;
			endcase
		end
		else if(c_state == READ_PIC_DATA) begin
			if(flag_DILA) begin
				pic_D <= {ED_minmax[15],  ED_minmax[14],  ED_minmax[13],  ED_minmax[12], 
						  ED_minmax[11],  ED_minmax[10],  ED_minmax[9],  ED_minmax[8], 
						  ED_minmax[7],  ED_minmax[6],  ED_minmax[5], ED_minmax[4], 
						  ED_minmax[3], ED_minmax[2], ED_minmax[1], ED_minmax[0]};
			end
			else pic_D <= pic_D;
		end
		else if((c_state == DILA_A)||(c_state == DILA_B)||(c_state == EROS)) begin
			case(operation)
				2'b01, 2'b00: pic_D <= {ED_minmax[15],  ED_minmax[14],  ED_minmax[13], ED_minmax[12], 
								        ED_minmax[11],  ED_minmax[10],  ED_minmax[9],  ED_minmax[8], 
								        ED_minmax[7],   ED_minmax[6],   ED_minmax[5],  ED_minmax[4], 
								        ED_minmax[3],   ED_minmax[2],   ED_minmax[1],  ED_minmax[0]};
				default: pic_D <= rdata_m_inf;
			endcase
		end 
		else pic_D <= pic_D;
	end
end
pic_256_128_4 PIC1 (.Q(pic_Q), .CLK(clk), .CEN(1'b0), .WEN(pic_WEN), .A(pic_A), .D(pic_D), .OEN(1'b0));

//======================================
//      	Read SRAM Block
//======================================
genvar n;
generate
	for(n=0;n<16;n=n+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) item_data[n] <= 0;
			else begin
				if(n_state == WRITE_DRAM_DATA) item_data[n] <= pic_Q[8*(n+1)-1:8*n];
				else item_data[n] <= 0;
			end
		end
	end
endgenerate

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) write_data <= 0;
	else begin
		if(n_state == WRITE_DRAM_DATA) begin
			case(operation)
				2'b10: write_data <= {cdf_table[item_data[15]][7:0], cdf_table[item_data[14]][7:0], cdf_table[item_data[13]][7:0], cdf_table[item_data[12]][7:0],
							   cdf_table[item_data[11]][7:0], cdf_table[item_data[10]][7:0], cdf_table[item_data[9]][7:0],  cdf_table[item_data[8]][7:0],
							   cdf_table[item_data[7]][7:0],  cdf_table[item_data[6]][7:0],  cdf_table[item_data[5]][7:0],  cdf_table[item_data[4]][7:0],
							   cdf_table[item_data[3]][7:0],  cdf_table[item_data[2]][7:0],  cdf_table[item_data[1]][7:0],  cdf_table[item_data[0]][7:0]};
				default: write_data <= pic_Q;
			endcase
		end
		else if(c_state == READ_PIC_DATA) begin
			write_data <= rdata_m_inf;
		end
		else write_data <= 0;
	end
end

//======================================
//      	Row Block
//======================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<64;i=i+1) row1[i] <= 8'd0;
	end
	else begin
		if(c_state == READ_PIC_DATA) begin
			if(rvalid_m_inf) begin
				case(operation)
					2'b00, 2'b01: begin
						if(row_counter == 0) begin
							case(catch_pic_counter)
								2'd0: begin
									row1[0]    <= rdata_m_inf[7 : 0];
									row1[1]    <= rdata_m_inf[15: 8];
									row1[2]    <= rdata_m_inf[23:16];
									row1[3]    <= rdata_m_inf[31:24];
									row1[4]    <= rdata_m_inf[39:32];
									row1[5]    <= rdata_m_inf[47:40];
									row1[6]    <= rdata_m_inf[55:48];
									row1[7]    <= rdata_m_inf[63:56];
									row1[8]    <= rdata_m_inf[71:64];
									row1[9]    <= rdata_m_inf[79:72];
									row1[10]   <= rdata_m_inf[87:80];
									row1[11]   <= rdata_m_inf[95:88];
									row1[12]   <= rdata_m_inf[103:96];
									row1[13]   <= rdata_m_inf[111:104];
									row1[14]   <= rdata_m_inf[119:112];
									row1[15]   <= rdata_m_inf[127:120];
									//for(i=16;i<64;i=i+1) row1[i] <= row1[i];
								end
								2'd1: begin
									//for(i=0;i<16;i=i+1) row1[i] <= row1[i];
									row1[16]   <= rdata_m_inf[7 : 0];
									row1[17]   <= rdata_m_inf[15: 8];
									row1[18]   <= rdata_m_inf[23:16];
									row1[19]   <= rdata_m_inf[31:24];
									row1[20]   <= rdata_m_inf[39:32];
									row1[21]   <= rdata_m_inf[47:40];
									row1[22]   <= rdata_m_inf[55:48];
									row1[23]   <= rdata_m_inf[63:56];
									row1[24]   <= rdata_m_inf[71:64];
									row1[25]   <= rdata_m_inf[79:72];
									row1[26]   <= rdata_m_inf[87:80];
									row1[27]   <= rdata_m_inf[95:88];
									row1[28]   <= rdata_m_inf[103:96];
									row1[29]   <= rdata_m_inf[111:104];
									row1[30]   <= rdata_m_inf[119:112];
									row1[31]   <= rdata_m_inf[127:120];
									//for(i=32;i<64;i=i+1) row1[i] <= row1[i];
								end
								2'd2: begin
									//for(i=0;i<32;i=i+1) row1[i] <= row1[i];
									row1[32]   <= rdata_m_inf[7 : 0];
									row1[33]   <= rdata_m_inf[15: 8];
									row1[34]   <= rdata_m_inf[23:16];
									row1[35]   <= rdata_m_inf[31:24];
									row1[36]   <= rdata_m_inf[39:32];
									row1[37]   <= rdata_m_inf[47:40];
									row1[38]   <= rdata_m_inf[55:48];
									row1[39]   <= rdata_m_inf[63:56];
									row1[40]   <= rdata_m_inf[71:64];
									row1[41]   <= rdata_m_inf[79:72];
									row1[42]   <= rdata_m_inf[87:80];
									row1[43]   <= rdata_m_inf[95:88];
									row1[44]   <= rdata_m_inf[103:96];
									row1[45]   <= rdata_m_inf[111:104];
									row1[46]   <= rdata_m_inf[119:112];
									row1[47]   <= rdata_m_inf[127:120];
									//for(i=48;i<64;i=i+1) row1[i] <= row1[i];
								end
								2'd3: begin
									//for(i=0;i<48;i=i+1) row1[i] <= row1[i];
									row1[48]   <= rdata_m_inf[7 : 0];
									row1[49]   <= rdata_m_inf[15: 8];
									row1[50]   <= rdata_m_inf[23:16];
									row1[51]   <= rdata_m_inf[31:24];
									row1[52]   <= rdata_m_inf[39:32];
									row1[53]   <= rdata_m_inf[47:40];
									row1[54]   <= rdata_m_inf[55:48];
									row1[55]   <= rdata_m_inf[63:56];
									row1[56]   <= rdata_m_inf[71:64];
									row1[57]   <= rdata_m_inf[79:72];
									row1[58]   <= rdata_m_inf[87:80];
									row1[59]   <= rdata_m_inf[95:88];
									row1[60]   <= rdata_m_inf[103:96];
									row1[61]   <= rdata_m_inf[111:104];
									row1[62]   <= rdata_m_inf[119:112];
									row1[63]   <= rdata_m_inf[127:120];
								end
								//default: for(i=0;i<64;i=i+1) row1[i] <= row1[i];
							endcase
						end
						else if(row_counter > 3) begin
							case(catch_pic_counter)
								2'd3: begin
									//if(row_counter==4) for(i=0;i<64;i=i+1) row1[i] <= row1[i];
									//else begin
										//for(i=0;i<48;i=i+1) row1[i] <= row1[i];
										row1[48]   <= row2[48];
										row1[49]   <= row2[49];
										row1[50]   <= row2[50];
										row1[51]   <= row2[51];
										row1[52]   <= row2[52];
										row1[53]   <= row2[53];
										row1[54]   <= row2[54];
										row1[55]   <= row2[55];
										row1[56]   <= row2[56];
										row1[57]   <= row2[57];
										row1[58]   <= row2[58];
										row1[59]   <= row2[59];
										row1[60]   <= row2[60];
										row1[61]   <= row2[61];
										row1[62]   <= row2[62];
										row1[63]   <= row2[63];
									//end
								end
								2'd0: begin
									row1[0]  <= row2[0];
									row1[1]  <= row2[1];
									row1[2]  <= row2[2];
									row1[3]  <= row2[3];
									row1[4]  <= row2[4];
									row1[5]  <= row2[5];
									row1[6]  <= row2[6];
									row1[7]  <= row2[7];
									row1[8]  <= row2[8];
									row1[9]  <= row2[9];
									row1[10] <= row2[10];
									row1[11] <= row2[11];
									row1[12] <= row2[12];
									row1[13] <= row2[13];
									row1[14] <= row2[14];
									row1[15] <= row2[15];
									//for(i=16;i<64;i=i+1) row1[i] <= row1[i];
								end
								2'd1: begin
									//for(i=0;i<16;i=i+1) row1[i] <= row1[i];
									row1[16] <= row2[16];
									row1[17] <= row2[17];
									row1[18] <= row2[18];
									row1[19] <= row2[19];
									row1[20] <= row2[20];
									row1[21] <= row2[21];
									row1[22] <= row2[22];
									row1[23] <= row2[23];
									row1[24] <= row2[24];
									row1[25] <= row2[25];
									row1[26] <= row2[26];
									row1[27] <= row2[27];
									row1[28] <= row2[28];
									row1[29] <= row2[29];
									row1[30] <= row2[30];
									row1[31] <= row2[31];
									//for(i=32;i<64;i=i+1) row1[i] <= row1[i];
								end
								2'd2: begin
									//for(i=0;i<32;i=i+1) row1[i] <= row1[i];
									row1[32] <= row2[32];
									row1[33] <= row2[33];
									row1[34] <= row2[34];
									row1[35] <= row2[35];
									row1[36] <= row2[36];
									row1[37] <= row2[37];
									row1[38] <= row2[38];
									row1[39] <= row2[39];
									row1[40] <= row2[40];
									row1[41] <= row2[41];
									row1[42] <= row2[42];
									row1[43] <= row2[43];
									row1[44] <= row2[44];
									row1[45] <= row2[45];
									row1[46] <= row2[46];
									row1[47] <= row2[47];
									//for(i=48;i<64;i=i+1) row1[i] <= row1[i];
								end
							endcase
						end
						//else for(i=0;i<64;i=i+1) row1[i] <= row1[i];
					end
					//default: for(i=0;i<64;i=i+1) row1[i] <= 0;
				endcase
			end
			//else for(i=0;i<64;i=i+1) row1[i] <= row1[i];
		end
		else if((c_state == DILA_A)||(c_state == EROS)) begin
			case(catch_pic_counter)
				2'd3: begin
					//for(i=0;i<48;i=i+1)  row1[i] <= row1[i];
					//for(i=48;i<64;i=i+1) row1[i] <= row2[i];
					row1[48] <= row2[48];
					row1[49] <= row2[49];
					row1[50] <= row2[50];
					row1[51] <= row2[51];
					row1[52] <= row2[52];
					row1[53] <= row2[53];
					row1[54] <= row2[54];
					row1[55] <= row2[55];
					row1[56] <= row2[56];
					row1[57] <= row2[57];
					row1[58] <= row2[58];
					row1[59] <= row2[59];
					row1[60] <= row2[60];
					row1[61] <= row2[61];
					row1[62] <= row2[62];
					row1[63] <= row2[63];
				end
				2'd0: begin
					//for(i=0;i<16;i=i+1)  row1[i] <= row2[i];
					//for(i=16;i<64;i=i+1) row1[i] <= row1[i];
					row1[0] <= row2[0];
					row1[1] <= row2[1];
					row1[2] <= row2[2];
					row1[3] <= row2[3];
					row1[4] <= row2[4];
					row1[5] <= row2[5];
					row1[6] <= row2[6];
					row1[7] <= row2[7];
					row1[8] <= row2[8];
					row1[9] <= row2[9];
					row1[10] <= row2[10];
					row1[11] <= row2[11];
					row1[12] <= row2[12];
					row1[13] <= row2[13];
					row1[14] <= row2[14];
					row1[15] <= row2[15];
				end
				2'd1: begin
					//for(i=0;i<16;i=i+1)  row1[i] <= row1[i];
					//for(i=16;i<32;i=i+1) row1[i] <= row2[i];
					//for(i=32;i<64;i=i+1) row1[i] <= row1[i];
					row1[16] <= row2[16];
					row1[17] <= row2[17];
					row1[18] <= row2[18];
					row1[19] <= row2[19];
					row1[20] <= row2[20];
					row1[21] <= row2[21];
					row1[22] <= row2[22];
					row1[23] <= row2[23];
					row1[24] <= row2[24];
					row1[25] <= row2[25];
					row1[26] <= row2[26];
					row1[27] <= row2[27];
					row1[28] <= row2[28];
					row1[29] <= row2[29];
					row1[30] <= row2[30];
					row1[31] <= row2[31];
				end
				2'd2: begin
					//for(i=0;i<32;i=i+1)  row1[i] <= row1[i];
					//for(i=32;i<48;i=i+1) row1[i] <= row2[i];
					//for(i=48;i<64;i=i+1) row1[i] <= row1[i];
					row1[32] <= row2[32];
					row1[33] <= row2[33];
					row1[34] <= row2[34];
					row1[35] <= row2[35];
					row1[36] <= row2[36];
					row1[37] <= row2[37];
					row1[38] <= row2[38];
					row1[39] <= row2[39];
					row1[40] <= row2[40];
					row1[41] <= row2[41];
					row1[42] <= row2[42];
					row1[43] <= row2[43];
					row1[44] <= row2[44];
					row1[45] <= row2[45];
					row1[46] <= row2[46];
					row1[47] <= row2[47];
				end
			endcase
		end
		//else for(i=0;i<64;i=i+1) row1[i] <= row1[i];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<64;i=i+1) row2[i] <= 8'd0;
	end
	else begin
		if(c_state == READ_PIC_DATA) begin
			if(rvalid_m_inf) begin
				case(operation)
					2'b00, 2'b01: begin
						if(row_counter == 1) begin
							case(catch_pic_counter)
								2'd0: begin
									row2[0]    <= rdata_m_inf[7 : 0];
									row2[1]    <= rdata_m_inf[15: 8];
									row2[2]    <= rdata_m_inf[23:16];
									row2[3]    <= rdata_m_inf[31:24];
									row2[4]    <= rdata_m_inf[39:32];
									row2[5]    <= rdata_m_inf[47:40];
									row2[6]    <= rdata_m_inf[55:48];
									row2[7]    <= rdata_m_inf[63:56];
									row2[8]    <= rdata_m_inf[71:64];
									row2[9]    <= rdata_m_inf[79:72];
									row2[10]   <= rdata_m_inf[87:80];
									row2[11]   <= rdata_m_inf[95:88];
									row2[12]   <= rdata_m_inf[103:96];
									row2[13]   <= rdata_m_inf[111:104];
									row2[14]   <= rdata_m_inf[119:112];
									row2[15]   <= rdata_m_inf[127:120];
									//for(i=16;i<64;i=i+1) row2[i] <= row2[i];
								end
								2'd1: begin
									//for(i=0;i<16;i=i+1) row2[i] <= row2[i];
									row2[16]   <= rdata_m_inf[7 : 0];
									row2[17]   <= rdata_m_inf[15: 8];
									row2[18]   <= rdata_m_inf[23:16];
									row2[19]   <= rdata_m_inf[31:24];
									row2[20]   <= rdata_m_inf[39:32];
									row2[21]   <= rdata_m_inf[47:40];
									row2[22]   <= rdata_m_inf[55:48];
									row2[23]   <= rdata_m_inf[63:56];
									row2[24]   <= rdata_m_inf[71:64];
									row2[25]   <= rdata_m_inf[79:72];
									row2[26]   <= rdata_m_inf[87:80];
									row2[27]   <= rdata_m_inf[95:88];
									row2[28]   <= rdata_m_inf[103:96];
									row2[29]   <= rdata_m_inf[111:104];
									row2[30]   <= rdata_m_inf[119:112];
									row2[31]   <= rdata_m_inf[127:120];
									//for(i=32;i<64;i=i+1) row2[i] <= row2[i];
								end
								2'd2: begin
									//for(i=0;i<32;i=i+1) row2[i] <= row2[i];
									row2[32]   <= rdata_m_inf[7 : 0];
									row2[33]   <= rdata_m_inf[15: 8];
									row2[34]   <= rdata_m_inf[23:16];
									row2[35]   <= rdata_m_inf[31:24];
									row2[36]   <= rdata_m_inf[39:32];
									row2[37]   <= rdata_m_inf[47:40];
									row2[38]   <= rdata_m_inf[55:48];
									row2[39]   <= rdata_m_inf[63:56];
									row2[40]   <= rdata_m_inf[71:64];
									row2[41]   <= rdata_m_inf[79:72];
									row2[42]   <= rdata_m_inf[87:80];
									row2[43]   <= rdata_m_inf[95:88];
									row2[44]   <= rdata_m_inf[103:96];
									row2[45]   <= rdata_m_inf[111:104];
									row2[46]   <= rdata_m_inf[119:112];
									row2[47]   <= rdata_m_inf[127:120];
									//for(i=48;i<64;i=i+1) row2[i] <= row2[i];
								end
								2'd3: begin
									//for(i=0;i<48;i=i+1) row2[i] <= row2[i];
									row2[48]   <= rdata_m_inf[7 : 0];
									row2[49]   <= rdata_m_inf[15: 8];
									row2[50]   <= rdata_m_inf[23:16];
									row2[51]   <= rdata_m_inf[31:24];
									row2[52]   <= rdata_m_inf[39:32];
									row2[53]   <= rdata_m_inf[47:40];
									row2[54]   <= rdata_m_inf[55:48];
									row2[55]   <= rdata_m_inf[63:56];
									row2[56]   <= rdata_m_inf[71:64];
									row2[57]   <= rdata_m_inf[79:72];
									row2[58]   <= rdata_m_inf[87:80];
									row2[59]   <= rdata_m_inf[95:88];
									row2[60]   <= rdata_m_inf[103:96];
									row2[61]   <= rdata_m_inf[111:104];
									row2[62]   <= rdata_m_inf[119:112];
									row2[63]   <= rdata_m_inf[127:120];
								end
								//default: for(i=0;i<64;i=i+1) row2[i] <= row2[i];
							endcase
						end
						else if(row_counter>3) begin
							case(catch_pic_counter)
								2'd3: begin
									//if(row_counter==4) for(i=0;i<64;i=i+1) row2[i] <= row2[i];
									//else begin
										//for(i=0;i<48;i=i+1) row2[i] <= row2[i];
										row2[48]   <= row3[48];
										row2[49]   <= row3[49];
										row2[50]   <= row3[50];
										row2[51]   <= row3[51];
										row2[52]   <= row3[52];
										row2[53]   <= row3[53];
										row2[54]   <= row3[54];
										row2[55]   <= row3[55];
										row2[56]   <= row3[56];
										row2[57]   <= row3[57];
										row2[58]   <= row3[58];
										row2[59]   <= row3[59];
										row2[60]   <= row3[60];
										row2[61]   <= row3[61];
										row2[62]   <= row3[62];
										row2[63]   <= row3[63];
									//end
								end
								2'd0: begin
									row2[0]  <= row3[0];
									row2[1]  <= row3[1];
									row2[2]  <= row3[2];
									row2[3]  <= row3[3];
									row2[4]  <= row3[4];
									row2[5]  <= row3[5];
									row2[6]  <= row3[6];
									row2[7]  <= row3[7];
									row2[8]  <= row3[8];
									row2[9]  <= row3[9];
									row2[10] <= row3[10];
									row2[11] <= row3[11];
									row2[12] <= row3[12];
									row2[13] <= row3[13];
									row2[14] <= row3[14];
									row2[15] <= row3[15];
									//for(i=16;i<64;i=i+1) row2[i] <= row2[i];
								end
								2'd1: begin
									//for(i=0;i<16;i=i+1) row2[i] <= row2[i];
									row2[16] <= row3[16];
									row2[17] <= row3[17];
									row2[18] <= row3[18];
									row2[19] <= row3[19];
									row2[20] <= row3[20];
									row2[21] <= row3[21];
									row2[22] <= row3[22];
									row2[23] <= row3[23];
									row2[24] <= row3[24];
									row2[25] <= row3[25];
									row2[26] <= row3[26];
									row2[27] <= row3[27];
									row2[28] <= row3[28];
									row2[29] <= row3[29];
									row2[30] <= row3[30];
									row2[31] <= row3[31];
									//for(i=32;i<64;i=i+1) row2[i] <= row2[i];
								end
								2'd2: begin
									//for(i=0;i<32;i=i+1) row2[i] <= row2[i];
									row2[32] <= row3[32];
									row2[33] <= row3[33];
									row2[34] <= row3[34];
									row2[35] <= row3[35];
									row2[36] <= row3[36];
									row2[37] <= row3[37];
									row2[38] <= row3[38];
									row2[39] <= row3[39];
									row2[40] <= row3[40];
									row2[41] <= row3[41];
									row2[42] <= row3[42];
									row2[43] <= row3[43];
									row2[44] <= row3[44];
									row2[45] <= row3[45];
									row2[46] <= row3[46];
									row2[47] <= row3[47];
									//for(i=48;i<64;i=i+1) row2[i] <= row2[i];
								end
							endcase
						end
						//else for(i=0;i<64;i=i+1) row2[i] <= row2[i];
					end
					//default: for(i=0;i<64;i=i+1) row2[i] <= 0;
				endcase
			end
			//else for(i=0;i<64;i=i+1) row2[i] <= row2[i];
		end
		else if((c_state == DILA_A)||(c_state == EROS)) begin
			case(catch_pic_counter)
				2'd3: begin
					//for(i=0;i<48;i=i+1)  row2[i] <= row2[i];
					//for(i=48;i<64;i=i+1) row2[i] <= row3[i];
					row2[48] <= row3[48];
					row2[49] <= row3[49];
					row2[50] <= row3[50];
					row2[51] <= row3[51];
					row2[52] <= row3[52];
					row2[53] <= row3[53];
					row2[54] <= row3[54];
					row2[55] <= row3[55];
					row2[56] <= row3[56];
					row2[57] <= row3[57];
					row2[58] <= row3[58];
					row2[59] <= row3[59];
					row2[60] <= row3[60];
					row2[61] <= row3[61];
					row2[62] <= row3[62];
					row2[63] <= row3[63];
				end
				2'd0: begin
					//for(i=0;i<16;i=i+1)  row2[i] <= row3[i];
					//for(i=16;i<64;i=i+1) row2[i] <= row2[i];
					row2[0] <= row3[0];
					row2[1] <= row3[1];
					row2[2] <= row3[2];
					row2[3] <= row3[3];
					row2[4] <= row3[4];
					row2[5] <= row3[5];
					row2[6] <= row3[6];
					row2[7] <= row3[7];
					row2[8] <= row3[8];
					row2[9] <= row3[9];
					row2[10] <= row3[10];
					row2[11] <= row3[11];
					row2[12] <= row3[12];
					row2[13] <= row3[13];
					row2[14] <= row3[14];
					row2[15] <= row3[15];
				end
				2'd1: begin
					//for(i=0;i<16;i=i+1)  row2[i] <= row2[i];
					//for(i=16;i<32;i=i+1) row2[i] <= row3[i];
					//for(i=32;i<64;i=i+1) row2[i] <= row2[i];
					row2[16] <= row3[16];
					row2[17] <= row3[17];
					row2[18] <= row3[18];
					row2[19] <= row3[19];
					row2[20] <= row3[20];
					row2[21] <= row3[21];
					row2[22] <= row3[22];
					row2[23] <= row3[23];
					row2[24] <= row3[24];
					row2[25] <= row3[25];
					row2[26] <= row3[26];
					row2[27] <= row3[27];
					row2[28] <= row3[28];
					row2[29] <= row3[29];
					row2[30] <= row3[30];
					row2[31] <= row3[31];
				end
				2'd2: begin
					//for(i=0;i<32;i=i+1)  row2[i] <= row2[i];
					//for(i=32;i<48;i=i+1) row2[i] <= row3[i];
					//for(i=48;i<64;i=i+1) row2[i] <= row2[i];
					row2[32] <= row3[32];
					row2[33] <= row3[33];
					row2[34] <= row3[34];
					row2[35] <= row3[35];
					row2[36] <= row3[36];
					row2[37] <= row3[37];
					row2[38] <= row3[38];
					row2[39] <= row3[39];
					row2[40] <= row3[40];
					row2[41] <= row3[41];
					row2[42] <= row3[42];
					row2[43] <= row3[43];
					row2[44] <= row3[44];
					row2[45] <= row3[45];
					row2[46] <= row3[46];
					row2[47] <= row3[47];
				end
			endcase
		end
		//else for(i=0;i<64;i=i+1) row2[i] <= row2[i];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<64;i=i+1) row3[i] <= 8'd0;
	end
	else begin
		if(c_state == READ_PIC_DATA) begin
			if(rvalid_m_inf) begin
				case(operation) 
					2'b00, 2'b01: begin
						if(row_counter == 2) begin
							case(catch_pic_counter)
								2'd0: begin
									row3[0]    <= rdata_m_inf[7 : 0];
									row3[1]    <= rdata_m_inf[15: 8];
									row3[2]    <= rdata_m_inf[23:16];
									row3[3]    <= rdata_m_inf[31:24];
									row3[4]    <= rdata_m_inf[39:32];
									row3[5]    <= rdata_m_inf[47:40];
									row3[6]    <= rdata_m_inf[55:48];
									row3[7]    <= rdata_m_inf[63:56];
									row3[8]    <= rdata_m_inf[71:64];
									row3[9]    <= rdata_m_inf[79:72];
									row3[10]   <= rdata_m_inf[87:80];
									row3[11]   <= rdata_m_inf[95:88];
									row3[12]   <= rdata_m_inf[103:96];
									row3[13]   <= rdata_m_inf[111:104];
									row3[14]   <= rdata_m_inf[119:112];
									row3[15]   <= rdata_m_inf[127:120];
									//for(i=16;i<64;i=i+1) row3[i] <= row3[i];
								end
								2'd1: begin
									//for(i=0;i<16;i=i+1) row3[i] <= row3[i];
									row3[16]   <= rdata_m_inf[7 : 0];
									row3[17]   <= rdata_m_inf[15: 8];
									row3[18]   <= rdata_m_inf[23:16];
									row3[19]   <= rdata_m_inf[31:24];
									row3[20]   <= rdata_m_inf[39:32];
									row3[21]   <= rdata_m_inf[47:40];
									row3[22]   <= rdata_m_inf[55:48];
									row3[23]   <= rdata_m_inf[63:56];
									row3[24]   <= rdata_m_inf[71:64];
									row3[25]   <= rdata_m_inf[79:72];
									row3[26]   <= rdata_m_inf[87:80];
									row3[27]   <= rdata_m_inf[95:88];
									row3[28]   <= rdata_m_inf[103:96];
									row3[29]   <= rdata_m_inf[111:104];
									row3[30]   <= rdata_m_inf[119:112];
									row3[31]   <= rdata_m_inf[127:120];
									//for(i=32;i<64;i=i+1) row3[i] <= row3[i];
								end
								2'd2: begin
									//for(i=0;i<32;i=i+1) row3[i] <= row3[i];
									row3[32]   <= rdata_m_inf[7 : 0];
									row3[33]   <= rdata_m_inf[15: 8];
									row3[34]   <= rdata_m_inf[23:16];
									row3[35]   <= rdata_m_inf[31:24];
									row3[36]   <= rdata_m_inf[39:32];
									row3[37]   <= rdata_m_inf[47:40];
									row3[38]   <= rdata_m_inf[55:48];
									row3[39]   <= rdata_m_inf[63:56];
									row3[40]   <= rdata_m_inf[71:64];
									row3[41]   <= rdata_m_inf[79:72];
									row3[42]   <= rdata_m_inf[87:80];
									row3[43]   <= rdata_m_inf[95:88];
									row3[44]   <= rdata_m_inf[103:96];
									row3[45]   <= rdata_m_inf[111:104];
									row3[46]   <= rdata_m_inf[119:112];
									row3[47]   <= rdata_m_inf[127:120];
									//for(i=48;i<64;i=i+1) row3[i] <= row3[i];
								end
								2'd3: begin
									//for(i=0;i<48;i=i+1) row3[i] <= row3[i];
									row3[48]   <= rdata_m_inf[7 : 0];
									row3[49]   <= rdata_m_inf[15: 8];
									row3[50]   <= rdata_m_inf[23:16];
									row3[51]   <= rdata_m_inf[31:24];
									row3[52]   <= rdata_m_inf[39:32];
									row3[53]   <= rdata_m_inf[47:40];
									row3[54]   <= rdata_m_inf[55:48];
									row3[55]   <= rdata_m_inf[63:56];
									row3[56]   <= rdata_m_inf[71:64];
									row3[57]   <= rdata_m_inf[79:72];
									row3[58]   <= rdata_m_inf[87:80];
									row3[59]   <= rdata_m_inf[95:88];
									row3[60]   <= rdata_m_inf[103:96];
									row3[61]   <= rdata_m_inf[111:104];
									row3[62]   <= rdata_m_inf[119:112];
									row3[63]   <= rdata_m_inf[127:120];
								end
								//default: for(i=0;i<64;i=i+1) row3[i] <= row3[i];
							endcase
						end
						else if(row_counter>3) begin
							case(catch_pic_counter)
								2'd3: begin
									//if(row_counter==4) for(i=0;i<64;i=i+1) row3[i] <= row3[i];
									//else begin
										//for(i=0;i<48;i=i+1) row3[i] <= row3[i];
										row3[48]   <= row4[48];
										row3[49]   <= row4[49];
										row3[50]   <= row4[50];
										row3[51]   <= row4[51];
										row3[52]   <= row4[52];
										row3[53]   <= row4[53];
										row3[54]   <= row4[54];
										row3[55]   <= row4[55];
										row3[56]   <= row4[56];
										row3[57]   <= row4[57];
										row3[58]   <= row4[58];
										row3[59]   <= row4[59];
										row3[60]   <= row4[60];
										row3[61]   <= row4[61];
										row3[62]   <= row4[62];
										row3[63]   <= row4[63];
									//end
								end
								2'd0: begin
									row3[0]  <= row4[0];
									row3[1]  <= row4[1];
									row3[2]  <= row4[2];
									row3[3]  <= row4[3];
									row3[4]  <= row4[4];
									row3[5]  <= row4[5];
									row3[6]  <= row4[6];
									row3[7]  <= row4[7];
									row3[8]  <= row4[8];
									row3[9]  <= row4[9];
									row3[10] <= row4[10];
									row3[11] <= row4[11];
									row3[12] <= row4[12];
									row3[13] <= row4[13];
									row3[14] <= row4[14];
									row3[15] <= row4[15];
									//for(i=16;i<64;i=i+1) row3[i] <= row3[i];
								end
								2'd1: begin
									//for(i=0;i<16;i=i+1) row3[i] <= row3[i];
									row3[16] <= row4[16];
									row3[17] <= row4[17];
									row3[18] <= row4[18];
									row3[19] <= row4[19];
									row3[20] <= row4[20];
									row3[21] <= row4[21];
									row3[22] <= row4[22];
									row3[23] <= row4[23];
									row3[24] <= row4[24];
									row3[25] <= row4[25];
									row3[26] <= row4[26];
									row3[27] <= row4[27];
									row3[28] <= row4[28];
									row3[29] <= row4[29];
									row3[30] <= row4[30];
									row3[31] <= row4[31];
									//for(i=32;i<64;i=i+1) row3[i] <= row3[i];
								end
								2'd2: begin
									//for(i=0;i<32;i=i+1) row3[i] <= row3[i];
									row3[32] <= row4[32];
									row3[33] <= row4[33];
									row3[34] <= row4[34];
									row3[35] <= row4[35];
									row3[36] <= row4[36];
									row3[37] <= row4[37];
									row3[38] <= row4[38];
									row3[39] <= row4[39];
									row3[40] <= row4[40];
									row3[41] <= row4[41];
									row3[42] <= row4[42];
									row3[43] <= row4[43];
									row3[44] <= row4[44];
									row3[45] <= row4[45];
									row3[46] <= row4[46];
									row3[47] <= row4[47];
									//for(i=48;i<64;i=i+1) row3[i] <= row3[i];
								end
							endcase
						end
						//else for(i=0;i<64;i=i+1) row3[i] <= row3[i];
					end
					//default: begin
						//for(i=0;i<64;i=i+1) row3[i] <= 0;
					//end
				endcase
			end
			//else for(i=0;i<64;i=i+1) row3[i] <= row3[i];
		end
		else if((c_state == DILA_A)||(c_state == EROS)) begin
			case(catch_pic_counter)
				2'd3: begin
					//for(i=0;i<48;i=i+1)  row3[i] <= row3[i];
					//for(i=48;i<64;i=i+1) row3[i] <= row4[i];
					row3[48] <= row4[48];
					row3[49] <= row4[49];
					row3[50] <= row4[50];
					row3[51] <= row4[51];
					row3[52] <= row4[52];
					row3[53] <= row4[53];
					row3[54] <= row4[54];
					row3[55] <= row4[55];
					row3[56] <= row4[56];
					row3[57] <= row4[57];
					row3[58] <= row4[58];
					row3[59] <= row4[59];
					row3[60] <= row4[60];
					row3[61] <= row4[61];
					row3[62] <= row4[62];
					row3[63] <= row4[63];
				end
				2'd0: begin
					//for(i=0;i<16;i=i+1)  row3[i] <= row4[i];
					//for(i=16;i<64;i=i+1) row3[i] <= row3[i];
					row3[0] <= row4[0];
					row3[1] <= row4[1];
					row3[2] <= row4[2];
					row3[3] <= row4[3];
					row3[4] <= row4[4];
					row3[5] <= row4[5];
					row3[6] <= row4[6];
					row3[7] <= row4[7];
					row3[8] <= row4[8];
					row3[9] <= row4[9];
					row3[10] <= row4[10];
					row3[11] <= row4[11];
					row3[12] <= row4[12];
					row3[13] <= row4[13];
					row3[14] <= row4[14];
					row3[15] <= row4[15];
				end
				2'd1: begin
					//for(i=0;i<16;i=i+1)  row3[i] <= row3[i];
					//for(i=16;i<32;i=i+1) row3[i] <= row4[i];
					//for(i=32;i<64;i=i+1) row3[i] <= row3[i];
					row3[16] <= row4[16];
					row3[17] <= row4[17];
					row3[18] <= row4[18];
					row3[19] <= row4[19];
					row3[20] <= row4[20];
					row3[21] <= row4[21];
					row3[22] <= row4[22];
					row3[23] <= row4[23];
					row3[24] <= row4[24];
					row3[25] <= row4[25];
					row3[26] <= row4[26];
					row3[27] <= row4[27];
					row3[28] <= row4[28];
					row3[29] <= row4[29];
					row3[30] <= row4[30];
					row3[31] <= row4[31];
				end
				2'd2: begin
					//for(i=0;i<32;i=i+1)  row3[i] <= row3[i];
					//for(i=32;i<48;i=i+1) row3[i] <= row4[i];
					//for(i=48;i<64;i=i+1) row3[i] <= row3[i];
					row3[32] <= row4[32];
					row3[33] <= row4[33];
					row3[34] <= row4[34];
					row3[35] <= row4[35];
					row3[36] <= row4[36];
					row3[37] <= row4[37];
					row3[38] <= row4[38];
					row3[39] <= row4[39];
					row3[40] <= row4[40];
					row3[41] <= row4[41];
					row3[42] <= row4[42];
					row3[43] <= row4[43];
					row3[44] <= row4[44];
					row3[45] <= row4[45];
					row3[46] <= row4[46];
					row3[47] <= row4[47];



				end
			endcase
		end
		//else for(i=0;i<64;i=i+1) row3[i] <= row3[i];
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<64;i=i+1) row4[i] <= 8'd0;
	end
	else begin
		if(c_state == READ_PIC_DATA) begin
			if(rvalid_m_inf) begin
				case(operation) 
					2'b00, 2'b01: begin
						if((row_counter>2)) begin
							case(catch_pic_counter)
								2'd0: begin
									row4[0]    <= rdata_m_inf[7 : 0];
									row4[1]    <= rdata_m_inf[15: 8];
									row4[2]    <= rdata_m_inf[23:16];
									row4[3]    <= rdata_m_inf[31:24];
									row4[4]    <= rdata_m_inf[39:32];
									row4[5]    <= rdata_m_inf[47:40];
									row4[6]    <= rdata_m_inf[55:48];
									row4[7]    <= rdata_m_inf[63:56];
									row4[8]    <= rdata_m_inf[71:64];
									row4[9]    <= rdata_m_inf[79:72];
									row4[10]   <= rdata_m_inf[87:80];
									row4[11]   <= rdata_m_inf[95:88];
									row4[12]   <= rdata_m_inf[103:96];
									row4[13]   <= rdata_m_inf[111:104];
									row4[14]   <= rdata_m_inf[119:112];
									row4[15]   <= rdata_m_inf[127:120];
									//for(i=16;i<64;i=i+1) row4[i] <= row4[i];
								end
								2'd1: begin
									//for(i=0;i<16;i=i+1) row4[i] <= row4[i];
									row4[16]   <= rdata_m_inf[7 : 0];
									row4[17]   <= rdata_m_inf[15: 8];
									row4[18]   <= rdata_m_inf[23:16];
									row4[19]   <= rdata_m_inf[31:24];
									row4[20]   <= rdata_m_inf[39:32];
									row4[21]   <= rdata_m_inf[47:40];
									row4[22]   <= rdata_m_inf[55:48];
									row4[23]   <= rdata_m_inf[63:56];
									row4[24]   <= rdata_m_inf[71:64];
									row4[25]   <= rdata_m_inf[79:72];
									row4[26]   <= rdata_m_inf[87:80];
									row4[27]   <= rdata_m_inf[95:88];
									row4[28]   <= rdata_m_inf[103:96];
									row4[29]   <= rdata_m_inf[111:104];
									row4[30]   <= rdata_m_inf[119:112];
									row4[31]   <= rdata_m_inf[127:120];
									//for(i=32;i<64;i=i+1) row4[i] <= row4[i];
								end
								2'd2: begin
									//for(i=0;i<32;i=i+1) row4[i] <= row4[i];
									row4[32]   <= rdata_m_inf[7 : 0];
									row4[33]   <= rdata_m_inf[15: 8];
									row4[34]   <= rdata_m_inf[23:16];
									row4[35]   <= rdata_m_inf[31:24];
									row4[36]   <= rdata_m_inf[39:32];
									row4[37]   <= rdata_m_inf[47:40];
									row4[38]   <= rdata_m_inf[55:48];
									row4[39]   <= rdata_m_inf[63:56];
									row4[40]   <= rdata_m_inf[71:64];
									row4[41]   <= rdata_m_inf[79:72];
									row4[42]   <= rdata_m_inf[87:80];
									row4[43]   <= rdata_m_inf[95:88];
									row4[44]   <= rdata_m_inf[103:96];
									row4[45]   <= rdata_m_inf[111:104];
									row4[46]   <= rdata_m_inf[119:112];
									row4[47]   <= rdata_m_inf[127:120];
									//for(i=48;i<64;i=i+1) row4[i] <= row4[i];
								end
								2'd3: begin
									//for(i=0;i<48;i=i+1) row4[i] <= row4[i];
									row4[48]   <= rdata_m_inf[7 : 0];
									row4[49]   <= rdata_m_inf[15: 8];
									row4[50]   <= rdata_m_inf[23:16];
									row4[51]   <= rdata_m_inf[31:24];
									row4[52]   <= rdata_m_inf[39:32];
									row4[53]   <= rdata_m_inf[47:40];
									row4[54]   <= rdata_m_inf[55:48];
									row4[55]   <= rdata_m_inf[63:56];
									row4[56]   <= rdata_m_inf[71:64];
									row4[57]   <= rdata_m_inf[79:72];
									row4[58]   <= rdata_m_inf[87:80];
									row4[59]   <= rdata_m_inf[95:88];
									row4[60]   <= rdata_m_inf[103:96];
									row4[61]   <= rdata_m_inf[111:104];
									row4[62]   <= rdata_m_inf[119:112];
									row4[63]   <= rdata_m_inf[127:120];
								end
							endcase
						end
					end
					//default: begin
						//for(i=0;i<64;i=i+1) row4[i] <= 0;
					//end
				endcase
			end
			//else for(i=0;i<64;i=i+1) row4[i] <= row4[i];
		end
		else if((c_state == DILA_A)||(c_state == EROS)) begin
			case(catch_pic_counter)
				2'd3: begin
					//for(i=0;i<48;i=i+1)  row4[i] <= row4[i];
					//for(i=48;i<64;i=i+1) row4[i] <= row5[i];
					row4[48] <= rdata_m_inf[7 : 0];
					row4[49] <= rdata_m_inf[15: 8];
					row4[50] <= rdata_m_inf[23:16];
					row4[51] <= rdata_m_inf[31:24];
					row4[52] <= rdata_m_inf[39:32];
					row4[53] <= rdata_m_inf[47:40];
					row4[54] <= rdata_m_inf[55:48];
					row4[55] <= rdata_m_inf[63:56];
					row4[56] <= rdata_m_inf[71:64];
					row4[57] <= rdata_m_inf[79:72];
					row4[58] <= rdata_m_inf[87:80];
					row4[59] <= rdata_m_inf[95:88];
					row4[60] <= rdata_m_inf[103:96];
					row4[61] <= rdata_m_inf[111:104];
					row4[62] <= rdata_m_inf[119:112];
					row4[63] <= rdata_m_inf[127:120];
				end
				2'd0: begin
					//for(i=0;i<16;i=i+1)  row4[i] <= row5[i];
					//for(i=16;i<64;i=i+1) row4[i] <= row4[i];
					row4[0] <= rdata_m_inf[7 : 0];
					row4[1] <= rdata_m_inf[15: 8];
					row4[2] <= rdata_m_inf[23:16];
					row4[3] <= rdata_m_inf[31:24];
					row4[4] <= rdata_m_inf[39:32];
					row4[5] <= rdata_m_inf[47:40];
					row4[6] <= rdata_m_inf[55:48];
					row4[7] <= rdata_m_inf[63:56];
					row4[8] <= rdata_m_inf[71:64];
					row4[9] <= rdata_m_inf[79:72];
					row4[10] <=rdata_m_inf[87:80];
					row4[11] <=rdata_m_inf[95:88];
					row4[12] <=rdata_m_inf[103:96];
					row4[13] <=rdata_m_inf[111:104];
					row4[14] <=rdata_m_inf[119:112];
					row4[15] <=rdata_m_inf[127:120];
				end
				2'd1: begin
					//for(i=0;i<16;i=i+1)  row4[i] <= row4[i];
					//for(i=16;i<32;i=i+1) row4[i] <= row5[i];
					//for(i=32;i<64;i=i+1) row4[i] <= row4[i];
					row4[16] <= rdata_m_inf[7 : 0];
					row4[17] <= rdata_m_inf[15: 8];
					row4[18] <= rdata_m_inf[23:16];
					row4[19] <= rdata_m_inf[31:24];
					row4[20] <= rdata_m_inf[39:32];
					row4[21] <= rdata_m_inf[47:40];
					row4[22] <= rdata_m_inf[55:48];
					row4[23] <= rdata_m_inf[63:56];
					row4[24] <= rdata_m_inf[71:64];
					row4[25] <= rdata_m_inf[79:72];
					row4[26] <= rdata_m_inf[87:80];
					row4[27] <= rdata_m_inf[95:88];
					row4[28] <= rdata_m_inf[103:96];
					row4[29] <= rdata_m_inf[111:104];
					row4[30] <= rdata_m_inf[119:112];
					row4[31] <= rdata_m_inf[127:120];
				end
				2'd2: begin
					//for(i=0;i<32;i=i+1)  row4[i] <= row4[i];
					//for(i=32;i<48;i=i+1) row4[i] <= row5[i];
					//for(i=48;i<64;i=i+1) row4[i] <= row4[i];
					row4[32] <= rdata_m_inf[7 : 0];
					row4[33] <= rdata_m_inf[15: 8];
					row4[34] <= rdata_m_inf[23:16];
					row4[35] <= rdata_m_inf[31:24];
					row4[36] <= rdata_m_inf[39:32];
					row4[37] <= rdata_m_inf[47:40];
					row4[38] <= rdata_m_inf[55:48];
					row4[39] <= rdata_m_inf[63:56];
					row4[40] <= rdata_m_inf[71:64];
					row4[41] <= rdata_m_inf[79:72];
					row4[42] <= rdata_m_inf[87:80];
					row4[43] <= rdata_m_inf[95:88];
					row4[44] <= rdata_m_inf[103:96];
					row4[45] <= rdata_m_inf[111:104];
					row4[46] <= rdata_m_inf[119:112];
					row4[47] <= rdata_m_inf[127:120];
				end
			endcase
		end
		//else for(i=0;i<64;i=i+1) row4[i] <= row4[i];
	end
end
//======================================
//      	Kernel Block
//======================================
genvar j;
generate 
	for(j=0;j<16;j=j+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) kernel[j] <= 0; 
			else begin
				if(c_state == READ_PIC_DATA) begin
					case(operation)
						2'b00: kernel[j] <= se_elements[(j+1)*8-1:j*8];
						default: kernel[j] <= se_elements[127-j*8:120-j*8];
					endcase
				end
				else kernel[j] <= kernel[j];
			end
		end
	end
endgenerate

//======================================
// 	   DILA_A & EROS elements Block
//======================================
generate
	for(j=0;j<16;j=j+1) begin
		assign ED_group[j] = {cdf_table[16*j][7:0],    cdf_table[16*j+1][7:0],  cdf_table[16*j+2][7:0], 
						      cdf_table[16*j+3][7:0],  cdf_table[16*j+4][7:0],  cdf_table[16*j+5][7:0], 
						      cdf_table[16*j+6][7:0],  cdf_table[16*j+7][7:0],  cdf_table[16*j+8][7:0], 
						      cdf_table[16*j+9][7:0],  cdf_table[16*j+10][7:0], cdf_table[16*j+11][7:0], 
						      cdf_table[16*j+12][7:0], cdf_table[16*j+13][7:0], cdf_table[16*j+14][7:0], 
						      cdf_table[16*j+15][7:0]};
	end
endgenerate
assign max_min_mode = (operation ==2'b01)? 1'b1: 1'b0;

DW_minmax #(8, 16) minmax1  (.a(ED_group[0]),  .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[0]),  .index(ED_index[0]));
DW_minmax #(8, 16) minmax2  (.a(ED_group[1]),  .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[1]),  .index(ED_index[1]));
DW_minmax #(8, 16) minmax3  (.a(ED_group[2]),  .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[2]),  .index(ED_index[2]));
DW_minmax #(8, 16) minmax4  (.a(ED_group[3]),  .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[3]),  .index(ED_index[3]));
DW_minmax #(8, 16) minmax5  (.a(ED_group[4]),  .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[4]),  .index(ED_index[4]));
DW_minmax #(8, 16) minmax6  (.a(ED_group[5]),  .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[5]),  .index(ED_index[5]));
DW_minmax #(8, 16) minmax7  (.a(ED_group[6]),  .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[6]),  .index(ED_index[6]));
DW_minmax #(8, 16) minmax8  (.a(ED_group[7]),  .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[7]),  .index(ED_index[7]));
DW_minmax #(8, 16) minmax9  (.a(ED_group[8]),  .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[8]),  .index(ED_index[8]));
DW_minmax #(8, 16) minmax10 (.a(ED_group[9]),  .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[9]),  .index(ED_index[9]));
DW_minmax #(8, 16) minmax11 (.a(ED_group[10]), .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[10]), .index(ED_index[10]));
DW_minmax #(8, 16) minmax12 (.a(ED_group[11]), .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[11]), .index(ED_index[11]));
DW_minmax #(8, 16) minmax13 (.a(ED_group[12]), .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[12]), .index(ED_index[12]));
DW_minmax #(8, 16) minmax14 (.a(ED_group[13]), .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[13]), .index(ED_index[13]));
DW_minmax #(8, 16) minmax15 (.a(ED_group[14]), .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[14]), .index(ED_index[14]));
DW_minmax #(8, 16) minmax16 (.a(ED_group[15]), .tc(1'b0), .min_max(max_min_mode), .value(ED_minmax[15]), .index(ED_index[15]));

//======================================
//      	HIST TABLE Block
//======================================
always@(*) begin
	case(catch_pic_counter)
		2'd0: begin
			temp[0] =  (operation == 2'b01)? kernel[0] + row1[0] : row1[0] - kernel[0];
			temp[1] =  (operation == 2'b01)? kernel[1] + row1[1] : row1[1] - kernel[1];
			temp[2] =  (operation == 2'b01)? kernel[2] + row1[2] : row1[2] - kernel[2];
			temp[3] =  (operation == 2'b01)? kernel[3] + row1[3] : row1[3] - kernel[3];
			temp[4] =  (operation == 2'b01)? kernel[4] + row2[0] : row2[0] - kernel[4];
			temp[5] =  (operation == 2'b01)? kernel[5] + row2[1] : row2[1] - kernel[5];
			temp[6] =  (operation == 2'b01)? kernel[6] + row2[2] : row2[2] - kernel[6];
			temp[7] =  (operation == 2'b01)? kernel[7] + row2[3] : row2[3] - kernel[7];
			temp[8] =  (operation == 2'b01)? kernel[8] + row3[0] : row3[0] - kernel[8];
			temp[9] =  (operation == 2'b01)? kernel[9] + row3[1] : row3[1] - kernel[9];
			temp[10] = (operation == 2'b01)? kernel[10] + row3[2] : row3[2] - kernel[10];
			temp[11] = (operation == 2'b01)? kernel[11] + row3[3] : row3[3] - kernel[11];
			temp[12] = (operation == 2'b01)? kernel[12] + row4[0] : row4[0] - kernel[12];
			temp[13] = (operation == 2'b01)? kernel[13] + row4[1] : row4[1] - kernel[13];
			temp[14] = (operation == 2'b01)? kernel[14] + row4[2] : row4[2] - kernel[14];
			temp[15] = (operation == 2'b01)? kernel[15] + row4[3] : row4[3] - kernel[15];
			temp[16] = (operation == 2'b01)? kernel[0] + row1[1]: row1[1] - kernel[0];
			temp[17] = (operation == 2'b01)? kernel[1] + row1[2]: row1[2] - kernel[1];
			temp[18] = (operation == 2'b01)? kernel[2] + row1[3]: row1[3] - kernel[2];
			temp[19] = (operation == 2'b01)? kernel[3] + row1[4]: row1[4] - kernel[3];
			temp[20] = (operation == 2'b01)? kernel[4] + row2[1]: row2[1] - kernel[4];
			temp[21] = (operation == 2'b01)? kernel[5] + row2[2]: row2[2] - kernel[5];
			temp[22] = (operation == 2'b01)? kernel[6] + row2[3]: row2[3] - kernel[6];
			temp[23] = (operation == 2'b01)? kernel[7] + row2[4]: row2[4] - kernel[7];
			temp[24] = (operation == 2'b01)? kernel[8] + row3[1]: row3[1] - kernel[8];
			temp[25] = (operation == 2'b01)? kernel[9] + row3[2]: row3[2] - kernel[9];
			temp[26] = (operation == 2'b01)? kernel[10] + row3[3]: row3[3] - kernel[10];
			temp[27] = (operation == 2'b01)? kernel[11] + row3[4]: row3[4] - kernel[11];
			temp[28] = (operation == 2'b01)? kernel[12] + row4[1]: row4[1] - kernel[12];
			temp[29] = (operation == 2'b01)? kernel[13] + row4[2]: row4[2] - kernel[13];
			temp[30] = (operation == 2'b01)? kernel[14] + row4[3]: row4[3] - kernel[14];
			temp[31] = (operation == 2'b01)? kernel[15] + row4[4]: row4[4] - kernel[15];
			temp[32] =  (operation == 2'b01)? kernel[0] + row1[2]: row1[2] - kernel[0];
			temp[33] =  (operation == 2'b01)? kernel[1] + row1[3]: row1[3] - kernel[1];
			temp[34] =  (operation == 2'b01)? kernel[2] + row1[4]: row1[4] - kernel[2];
			temp[35] =  (operation == 2'b01)? kernel[3] + row1[5]: row1[5] - kernel[3];
			temp[36] =  (operation == 2'b01)? kernel[4] + row2[2]: row2[2] - kernel[4];
			temp[37] =  (operation == 2'b01)? kernel[5] + row2[3]: row2[3] - kernel[5];
			temp[38] =  (operation == 2'b01)? kernel[6] + row2[4]: row2[4] - kernel[6];
			temp[39] =  (operation == 2'b01)? kernel[7] + row2[5]: row2[5] - kernel[7];
			temp[40] =  (operation == 2'b01)? kernel[8] + row3[2]: row3[2] - kernel[8];
			temp[41] =  (operation == 2'b01)? kernel[9] + row3[3]: row3[3] - kernel[9];
			temp[42] =  (operation == 2'b01)? kernel[10] + row3[4]: row3[4] - kernel[10];
			temp[43] =  (operation == 2'b01)? kernel[11] + row3[5]: row3[5] - kernel[11];
			temp[44] =  (operation == 2'b01)? kernel[12] + row4[2]: row4[2] - kernel[12];
			temp[45] =  (operation == 2'b01)? kernel[13] + row4[3]: row4[3] - kernel[13];
			temp[46] =  (operation == 2'b01)? kernel[14] + row4[4]: row4[4] - kernel[14];
			temp[47] =  (operation == 2'b01)? kernel[15] + row4[5]: row4[5] - kernel[15];
			temp[48] =  (operation == 2'b01)? kernel[0] + row1[3]: row1[3] - kernel[0];
			temp[49] =  (operation == 2'b01)? kernel[1] + row1[4]: row1[4] - kernel[1];
			temp[50] =  (operation == 2'b01)? kernel[2] + row1[5]: row1[5] - kernel[2];
			temp[51] =  (operation == 2'b01)? kernel[3] + row1[6]: row1[6] - kernel[3];
			temp[52] =  (operation == 2'b01)? kernel[4] + row2[3]: row2[3] - kernel[4];
			temp[53] =  (operation == 2'b01)? kernel[5] + row2[4]: row2[4] - kernel[5];
			temp[54] =  (operation == 2'b01)? kernel[6] + row2[5]: row2[5] - kernel[6];
			temp[55] =  (operation == 2'b01)? kernel[7] + row2[6]: row2[6] - kernel[7];
			temp[56] =  (operation == 2'b01)? kernel[8] + row3[3]: row3[3] - kernel[8];
			temp[57] =  (operation == 2'b01)? kernel[9] + row3[4]: row3[4] - kernel[9];
			temp[58] =  (operation == 2'b01)? kernel[10] + row3[5]: row3[5] - kernel[10];
			temp[59] =  (operation == 2'b01)? kernel[11] + row3[6]: row3[6] - kernel[11];
			temp[60] =  (operation == 2'b01)? kernel[12] + row4[3]: row4[3] - kernel[12];
			temp[61] =  (operation == 2'b01)? kernel[13] + row4[4]: row4[4] - kernel[13];
			temp[62] =  (operation == 2'b01)? kernel[14] + row4[5]: row4[5] - kernel[14];
			temp[63] =  (operation == 2'b01)? kernel[15] + row4[6]: row4[6] - kernel[15];
			temp[64] =  (operation == 2'b01)? kernel[0] + row1[4]: row1[4] - kernel[0];
			temp[65] =  (operation == 2'b01)? kernel[1] + row1[5]: row1[5] - kernel[1];
			temp[66] =  (operation == 2'b01)? kernel[2] + row1[6]: row1[6] - kernel[2];
			temp[67] =  (operation == 2'b01)? kernel[3] + row1[7]: row1[7] - kernel[3];
			temp[68] =  (operation == 2'b01)? kernel[4] + row2[4]: row2[4] - kernel[4];
			temp[69] =  (operation == 2'b01)? kernel[5] + row2[5]: row2[5] - kernel[5];
			temp[70] =  (operation == 2'b01)? kernel[6] + row2[6]: row2[6] - kernel[6];
			temp[71] =  (operation == 2'b01)? kernel[7] + row2[7]: row2[7] - kernel[7];
			temp[72] =  (operation == 2'b01)? kernel[8] + row3[4]: row3[4] - kernel[8];
			temp[73] =  (operation == 2'b01)? kernel[9] + row3[5]: row3[5] - kernel[9];
			temp[74] =  (operation == 2'b01)? kernel[10] + row3[6]: row3[6] - kernel[10];
			temp[75] =  (operation == 2'b01)? kernel[11] + row3[7]: row3[7] - kernel[11];
			temp[76] =  (operation == 2'b01)? kernel[12] + row4[4]: row4[4] - kernel[12];
			temp[77] =  (operation == 2'b01)? kernel[13] + row4[5]: row4[5] - kernel[13];
			temp[78] =  (operation == 2'b01)? kernel[14] + row4[6]: row4[6] - kernel[14];
			temp[79] =  (operation == 2'b01)? kernel[15] + row4[7]: row4[7] - kernel[15];
			temp[80] =  (operation == 2'b01)? kernel[0] + row1[5]: row1[5] - kernel[0];
			temp[81] =  (operation == 2'b01)? kernel[1] + row1[6]: row1[6] - kernel[1];
			temp[82] =  (operation == 2'b01)? kernel[2] + row1[7]: row1[7] - kernel[2];
			temp[83] =  (operation == 2'b01)? kernel[3] + row1[8]: row1[8] - kernel[3];
			temp[84] =  (operation == 2'b01)? kernel[4] + row2[5]: row2[5] - kernel[4];
			temp[85] =  (operation == 2'b01)? kernel[5] + row2[6]: row2[6] - kernel[5];
			temp[86] =  (operation == 2'b01)? kernel[6] + row2[7]: row2[7] - kernel[6];
			temp[87] =  (operation == 2'b01)? kernel[7] + row2[8]: row2[8] - kernel[7];
			temp[88] =  (operation == 2'b01)? kernel[8] + row3[5]: row3[5] - kernel[8];
			temp[89] =  (operation == 2'b01)? kernel[9] + row3[6]: row3[6] - kernel[9];
			temp[90] =  (operation == 2'b01)? kernel[10] + row3[7]: row3[7] - kernel[10];
			temp[91] =  (operation == 2'b01)? kernel[11] + row3[8]: row3[8] - kernel[11];
			temp[92] =  (operation == 2'b01)? kernel[12] + row4[5]: row4[5] - kernel[12];
			temp[93] =  (operation == 2'b01)? kernel[13] + row4[6]: row4[6] - kernel[13];
			temp[94] =  (operation == 2'b01)? kernel[14] + row4[7]: row4[7] - kernel[14];
			temp[95] =  (operation == 2'b01)? kernel[15] + row4[8]: row4[8] - kernel[15];
			temp[96] =  (operation == 2'b01)? kernel[0] + row1[6] : row1[6] - kernel[0];
			temp[97] =  (operation == 2'b01)? kernel[1] + row1[7] : row1[7] - kernel[1];
			temp[98] =  (operation == 2'b01)? kernel[2] + row1[8] : row1[8] - kernel[2];
			temp[99] =  (operation == 2'b01)? kernel[3] + row1[9] : row1[9] - kernel[3];
			temp[100] =  (operation == 2'b01)? kernel[4] + row2[6] : row2[6] - kernel[4];
			temp[101] =  (operation == 2'b01)? kernel[5] + row2[7] : row2[7] - kernel[5];
			temp[102] =  (operation == 2'b01)? kernel[6] + row2[8] : row2[8] - kernel[6];
			temp[103] =  (operation == 2'b01)? kernel[7] + row2[9] : row2[9] - kernel[7];
			temp[104] =  (operation == 2'b01)? kernel[8] + row3[6] : row3[6] - kernel[8];
			temp[105] =  (operation == 2'b01)? kernel[9] + row3[7] : row3[7] - kernel[9];
			temp[106] =  (operation == 2'b01)? kernel[10] + row3[8] : row3[8] - kernel[10];
			temp[107] =  (operation == 2'b01)? kernel[11] + row3[9] : row3[9] - kernel[11];
			temp[108] =  (operation == 2'b01)? kernel[12] + row4[6] : row4[6] - kernel[12];
			temp[109] =  (operation == 2'b01)? kernel[13] + row4[7] : row4[7] - kernel[13];
			temp[110] =  (operation == 2'b01)? kernel[14] + row4[8] : row4[8] - kernel[14];
			temp[111] =  (operation == 2'b01)? kernel[15] + row4[9] : row4[9] - kernel[15];
			temp[112] =  (operation == 2'b01)? kernel[0] + row1[7]: row1[7] - kernel[0];
			temp[113] =  (operation == 2'b01)? kernel[1] + row1[8]: row1[8] - kernel[1];
			temp[114] =  (operation == 2'b01)? kernel[2] + row1[9]: row1[9] - kernel[2];
			temp[115] =  (operation == 2'b01)? kernel[3] + row1[10]: row1[10] - kernel[3];
			temp[116] =  (operation == 2'b01)? kernel[4] + row2[7]: row2[7] - kernel[4];
			temp[117] =  (operation == 2'b01)? kernel[5] + row2[8]: row2[8] - kernel[5];
			temp[118] =  (operation == 2'b01)? kernel[6] + row2[9]: row2[9] - kernel[6];
			temp[119] =  (operation == 2'b01)? kernel[7] + row2[10]: row2[10] - kernel[7];
			temp[120] =  (operation == 2'b01)? kernel[8] + row3[7]: row3[7] - kernel[8];
			temp[121] =  (operation == 2'b01)? kernel[9] + row3[8]: row3[8] - kernel[9];
			temp[122] =  (operation == 2'b01)? kernel[10] + row3[9]: row3[9] - kernel[10];
			temp[123] =  (operation == 2'b01)? kernel[11] + row3[10]: row3[10] - kernel[11];
			temp[124] =  (operation == 2'b01)? kernel[12] + row4[7]: row4[7] - kernel[12];
			temp[125] =  (operation == 2'b01)? kernel[13] + row4[8]: row4[8] - kernel[13];
			temp[126] =  (operation == 2'b01)? kernel[14] + row4[9]: row4[9] - kernel[14];
			temp[127] =  (operation == 2'b01)? kernel[15] + row4[10]: row4[10] - kernel[15];
			temp[128] =  (operation == 2'b01)? kernel[0] + row1[8]: row1[8] - kernel[0];
			temp[129] =  (operation == 2'b01)? kernel[1] + row1[9]: row1[9] - kernel[1];
			temp[130] =  (operation == 2'b01)? kernel[2] + row1[10]: row1[10] - kernel[2];
			temp[131] =  (operation == 2'b01)? kernel[3] + row1[11]: row1[11] - kernel[3];
			temp[132] =  (operation == 2'b01)? kernel[4] + row2[8]: row2[8] - kernel[4];
			temp[133] =  (operation == 2'b01)? kernel[5] + row2[9]: row2[9] - kernel[5];
			temp[134] =  (operation == 2'b01)? kernel[6] + row2[10]: row2[10] - kernel[6];
			temp[135] =  (operation == 2'b01)? kernel[7] + row2[11]: row2[11] - kernel[7];
			temp[136] =  (operation == 2'b01)? kernel[8] + row3[8]: row3[8] - kernel[8];
			temp[137] =  (operation == 2'b01)? kernel[9] + row3[9]: row3[9] - kernel[9];
			temp[138] =  (operation == 2'b01)? kernel[10] + row3[10]: row3[10] - kernel[10];
			temp[139] =  (operation == 2'b01)? kernel[11] + row3[11]: row3[11] - kernel[11];
			temp[140] =  (operation == 2'b01)? kernel[12] + row4[8]: row4[8] - kernel[12];
			temp[141] =  (operation == 2'b01)? kernel[13] + row4[9]: row4[9] - kernel[13];
			temp[142] =  (operation == 2'b01)? kernel[14] + row4[10]: row4[10] - kernel[14];
			temp[143] =  (operation == 2'b01)? kernel[15] + row4[11]: row4[11] - kernel[15];
			temp[144] =  (operation == 2'b01)? kernel[0] + row1[9]: row1[9] - kernel[0];
			temp[145] =  (operation == 2'b01)? kernel[1] + row1[10]: row1[10] - kernel[1];
			temp[146] =  (operation == 2'b01)? kernel[2] + row1[11]: row1[11] - kernel[2];
			temp[147] =  (operation == 2'b01)? kernel[3] + row1[12]: row1[12] - kernel[3];
			temp[148] =  (operation == 2'b01)? kernel[4] + row2[9]: row2[9] - kernel[4];
			temp[149] =  (operation == 2'b01)? kernel[5] + row2[10]: row2[10] - kernel[5];
			temp[150] =  (operation == 2'b01)? kernel[6] + row2[11]: row2[11] - kernel[6];
			temp[151] =  (operation == 2'b01)? kernel[7] + row2[12]: row2[12] - kernel[7];
			temp[152] =  (operation == 2'b01)? kernel[8] + row3[9]: row3[9] - kernel[8];
			temp[153] =  (operation == 2'b01)? kernel[9] + row3[10]: row3[10] - kernel[9];
			temp[154] =  (operation == 2'b01)? kernel[10] + row3[11]: row3[11] - kernel[10];
			temp[155] =  (operation == 2'b01)? kernel[11] + row3[12]: row3[12] - kernel[11];
			temp[156] =  (operation == 2'b01)? kernel[12] + row4[9]: row4[9] - kernel[12];
			temp[157] =  (operation == 2'b01)? kernel[13] + row4[10]: row4[10] - kernel[13];
			temp[158] =  (operation == 2'b01)? kernel[14] + row4[11]: row4[11] - kernel[14];
			temp[159] =  (operation == 2'b01)? kernel[15] + row4[12]: row4[12] - kernel[15];
			temp[160] =  (operation == 2'b01)? kernel[0] + row1[10]: row1[10] - kernel[0];
			temp[161] =  (operation == 2'b01)? kernel[1] + row1[11]: row1[11] - kernel[1];
			temp[162] =  (operation == 2'b01)? kernel[2] + row1[12]: row1[12] - kernel[2];
			temp[163] =  (operation == 2'b01)? kernel[3] + row1[13]: row1[13] - kernel[3];
			temp[164] =  (operation == 2'b01)? kernel[4] + row2[10]: row2[10] - kernel[4];
			temp[165] =  (operation == 2'b01)? kernel[5] + row2[11]: row2[11] - kernel[5];
			temp[166] =  (operation == 2'b01)? kernel[6] + row2[12]: row2[12] - kernel[6];
			temp[167] =  (operation == 2'b01)? kernel[7] + row2[13]: row2[13] - kernel[7];
			temp[168] =  (operation == 2'b01)? kernel[8] + row3[10]: row3[10] - kernel[8];
			temp[169] =  (operation == 2'b01)? kernel[9] + row3[11]: row3[11] - kernel[9];
			temp[170] =  (operation == 2'b01)? kernel[10] + row3[12]: row3[12] - kernel[10];
			temp[171] =  (operation == 2'b01)? kernel[11] + row3[13]: row3[13] - kernel[11];
			temp[172] =  (operation == 2'b01)? kernel[12] + row4[10]: row4[10] - kernel[12];
			temp[173] =  (operation == 2'b01)? kernel[13] + row4[11]: row4[11] - kernel[13];
			temp[174] =  (operation == 2'b01)? kernel[14] + row4[12]: row4[12] - kernel[14];
			temp[175] =  (operation == 2'b01)? kernel[15] + row4[13]: row4[13] - kernel[15];
			temp[176] =  (operation == 2'b01)? kernel[0] + row1[11]: row1[11] - kernel[0];
			temp[177] =  (operation == 2'b01)? kernel[1] + row1[12]: row1[12] - kernel[1];
			temp[178] =  (operation == 2'b01)? kernel[2] + row1[13]: row1[13] - kernel[2];
			temp[179] =  (operation == 2'b01)? kernel[3] + row1[14]: row1[14] - kernel[3];
			temp[180] =  (operation == 2'b01)? kernel[4] + row2[11]: row2[11] - kernel[4];
			temp[181] =  (operation == 2'b01)? kernel[5] + row2[12]: row2[12] - kernel[5];
			temp[182] =  (operation == 2'b01)? kernel[6] + row2[13]: row2[13] - kernel[6];
			temp[183] =  (operation == 2'b01)? kernel[7] + row2[14]: row2[14] - kernel[7];
			temp[184] =  (operation == 2'b01)? kernel[8] + row3[11]: row3[11] - kernel[8];
			temp[185] =  (operation == 2'b01)? kernel[9] + row3[12]: row3[12] - kernel[9];
			temp[186] =  (operation == 2'b01)? kernel[10] + row3[13]: row3[13] - kernel[10];
			temp[187] =  (operation == 2'b01)? kernel[11] + row3[14]: row3[14] - kernel[11];
			temp[188] =  (operation == 2'b01)? kernel[12] + row4[11]: row4[11] - kernel[12];
			temp[189] =  (operation == 2'b01)? kernel[13] + row4[12]: row4[12] - kernel[13];
			temp[190] =  (operation == 2'b01)? kernel[14] + row4[13]: row4[13] - kernel[14];
			temp[191] =  (operation == 2'b01)? kernel[15] + row4[14]: row4[14] - kernel[15];
			temp[192] =  (operation == 2'b01)? kernel[0] + row1[12]: row1[12] - kernel[0];
			temp[193] =  (operation == 2'b01)? kernel[1] + row1[13]: row1[13] - kernel[1];
			temp[194] =  (operation == 2'b01)? kernel[2] + row1[14]: row1[14] - kernel[2];
			temp[195] =  (operation == 2'b01)? kernel[3] + row1[15]: row1[15] - kernel[3];
			temp[196] =  (operation == 2'b01)? kernel[4] + row2[12]: row2[12] - kernel[4];
			temp[197] =  (operation == 2'b01)? kernel[5] + row2[13]: row2[13] - kernel[5];
			temp[198] =  (operation == 2'b01)? kernel[6] + row2[14]: row2[14] - kernel[6];
			temp[199] =  (operation == 2'b01)? kernel[7] + row2[15]: row2[15] - kernel[7];
			temp[200] =  (operation == 2'b01)? kernel[8] + row3[12]: row3[12] - kernel[8];
			temp[201] =  (operation == 2'b01)? kernel[9] + row3[13]: row3[13] - kernel[9];
			temp[202] =  (operation == 2'b01)? kernel[10] + row3[14]: row3[14] - kernel[10];
			temp[203] =  (operation == 2'b01)? kernel[11] + row3[15]: row3[15] - kernel[11];
			temp[204] =  (operation == 2'b01)? kernel[12] + row4[12]: row4[12] - kernel[12];
			temp[205] =  (operation == 2'b01)? kernel[13] + row4[13]: row4[13] - kernel[13];
			temp[206] =  (operation == 2'b01)? kernel[14] + row4[14]: row4[14] - kernel[14];
			temp[207] =  (operation == 2'b01)? kernel[15] + row4[15]: row4[15] - kernel[15];
			temp[208] =  (operation == 2'b01)? kernel[0] + row1[13]: row1[13] - kernel[0];
			temp[209] =  (operation == 2'b01)? kernel[1] + row1[14]: row1[14] - kernel[1];
			temp[210] =  (operation == 2'b01)? kernel[2] + row1[15]: row1[15] - kernel[2];
			temp[211] =  (operation == 2'b01)? kernel[3] + row1[16]: row1[16] - kernel[3];
			temp[212] =  (operation == 2'b01)? kernel[4] + row2[13]: row2[13] - kernel[4];
			temp[213] =  (operation == 2'b01)? kernel[5] + row2[14]: row2[14] - kernel[5];
			temp[214] =  (operation == 2'b01)? kernel[6] + row2[15]: row2[15] - kernel[6];
			temp[215] =  (operation == 2'b01)? kernel[7] + row2[16]: row2[16] - kernel[7];
			temp[216] =  (operation == 2'b01)? kernel[8] + row3[13]: row3[13] - kernel[8];
			temp[217] =  (operation == 2'b01)? kernel[9] + row3[14]: row3[14] - kernel[9];
			temp[218] =  (operation == 2'b01)? kernel[10] + row3[15]: row3[15] - kernel[10];
			temp[219] =  (operation == 2'b01)? kernel[11] + row3[16]: row3[16] - kernel[11];
			temp[220] =  (operation == 2'b01)? kernel[12] + row4[13]: row4[13] - kernel[12];
			temp[221] =  (operation == 2'b01)? kernel[13] + row4[14]: row4[14] - kernel[13];
			temp[222] =  (operation == 2'b01)? kernel[14] + row4[15]: row4[15] - kernel[14];
			temp[223] =  (operation == 2'b01)? kernel[15] + row4[16]: row4[16] - kernel[15];
			temp[224] =  (operation == 2'b01)? kernel[0] + row1[14]: row1[14] - kernel[0];
			temp[225] =  (operation == 2'b01)? kernel[1] + row1[15]: row1[15] - kernel[1];
			temp[226] =  (operation == 2'b01)? kernel[2] + row1[16]: row1[16] - kernel[2];
			temp[227] =  (operation == 2'b01)? kernel[3] + row1[17]: row1[17] - kernel[3];
			temp[228] =  (operation == 2'b01)? kernel[4] + row2[14]: row2[14] - kernel[4];
			temp[229] =  (operation == 2'b01)? kernel[5] + row2[15]: row2[15] - kernel[5];
			temp[230] =  (operation == 2'b01)? kernel[6] + row2[16]: row2[16] - kernel[6];
			temp[231] =  (operation == 2'b01)? kernel[7] + row2[17]: row2[17] - kernel[7];
			temp[232] =  (operation == 2'b01)? kernel[8] + row3[14]: row3[14] - kernel[8];
			temp[233] =  (operation == 2'b01)? kernel[9] + row3[15]: row3[15] - kernel[9];
			temp[234] =  (operation == 2'b01)? kernel[10] + row3[16]: row3[16] - kernel[10];
			temp[235] =  (operation == 2'b01)? kernel[11] + row3[17]: row3[17] - kernel[11];
			temp[236] =  (operation == 2'b01)? kernel[12] + row4[14]: row4[14] - kernel[12];
			temp[237] =  (operation == 2'b01)? kernel[13] + row4[15]: row4[15] - kernel[13];
			temp[238] =  (operation == 2'b01)? kernel[14] + row4[16]: row4[16] - kernel[14];
			temp[239] =  (operation == 2'b01)? kernel[15] + row4[17]: row4[17] - kernel[15];
			temp[240] =  (operation == 2'b01)? kernel[0] + row1[15]: row1[15] - kernel[0];
			temp[241] =  (operation == 2'b01)? kernel[1] + row1[16]: row1[16] - kernel[1];
			temp[242] =  (operation == 2'b01)? kernel[2] + row1[17]: row1[17] - kernel[2];
			temp[243] =  (operation == 2'b01)? kernel[3] + row1[18]: row1[18] - kernel[3];
			temp[244] =  (operation == 2'b01)? kernel[4] + row2[15]: row2[15] - kernel[4];
			temp[245] =  (operation == 2'b01)? kernel[5] + row2[16]: row2[16] - kernel[5];
			temp[246] =  (operation == 2'b01)? kernel[6] + row2[17]: row2[17] - kernel[6];
			temp[247] =  (operation == 2'b01)? kernel[7] + row2[18]: row2[18] - kernel[7];
			temp[248] =  (operation == 2'b01)? kernel[8] + row3[15]: row3[15] - kernel[8];
			temp[249] =  (operation == 2'b01)? kernel[9] + row3[16]: row3[16] - kernel[9];
			temp[250] =  (operation == 2'b01)? kernel[10] + row3[17]: row3[17] - kernel[10];
			temp[251] =  (operation == 2'b01)? kernel[11] + row3[18]: row3[18] - kernel[11];
			temp[252] =  (operation == 2'b01)? kernel[12] + row4[15]: row4[15] - kernel[12];
			temp[253] =  (operation == 2'b01)? kernel[13] + row4[16]: row4[16] - kernel[13];
			temp[254] =  (operation == 2'b01)? kernel[14] + row4[17]: row4[17] - kernel[14];
			temp[255] =  (operation == 2'b01)? kernel[15] + row4[18]: row4[18] - kernel[15];
		end		
		2'd1: begin
			temp[0] =  (operation == 2'b01)? kernel[0] + row1[16] : row1[16] - kernel[0];
			temp[1] =  (operation == 2'b01)? kernel[1] + row1[17] : row1[17] - kernel[1];
			temp[2] =  (operation == 2'b01)? kernel[2] + row1[18] : row1[18] - kernel[2];
			temp[3] =  (operation == 2'b01)? kernel[3] + row1[19] : row1[19] - kernel[3];
			temp[4] =  (operation == 2'b01)? kernel[4] + row2[16] : row2[16] - kernel[4];
			temp[5] =  (operation == 2'b01)? kernel[5] + row2[17] : row2[17] - kernel[5];
			temp[6] =  (operation == 2'b01)? kernel[6] + row2[18] : row2[18] - kernel[6];
			temp[7] =  (operation == 2'b01)? kernel[7] + row2[19] : row2[19] - kernel[7];
			temp[8] =  (operation == 2'b01)? kernel[8] + row3[16] : row3[16] - kernel[8];
			temp[9] =  (operation == 2'b01)? kernel[9] + row3[17] : row3[17] - kernel[9];
			temp[10] =  (operation == 2'b01)? kernel[10] + row3[18] : row3[18] - kernel[10];
			temp[11] =  (operation == 2'b01)? kernel[11] + row3[19] : row3[19] - kernel[11];
			temp[12] =  (operation == 2'b01)? kernel[12] + row4[16] : row4[16] - kernel[12];
			temp[13] =  (operation == 2'b01)? kernel[13] + row4[17] : row4[17] - kernel[13];
			temp[14] =  (operation == 2'b01)? kernel[14] + row4[18] : row4[18] - kernel[14];
			temp[15] =  (operation == 2'b01)? kernel[15] + row4[19] : row4[19] - kernel[15];
			temp[16] = (operation == 2'b01)? kernel[0] + row1[17]: row1[17] - kernel[0];
			temp[17] = (operation == 2'b01)? kernel[1] + row1[18]: row1[18] - kernel[1];
			temp[18] = (operation == 2'b01)? kernel[2] + row1[19]: row1[19] - kernel[2];
			temp[19] = (operation == 2'b01)? kernel[3] + row1[20]: row1[20] - kernel[3];
			temp[20] = (operation == 2'b01)? kernel[4] + row2[17]: row2[17] - kernel[4];
			temp[21] = (operation == 2'b01)? kernel[5] + row2[18]: row2[18] - kernel[5];
			temp[22] = (operation == 2'b01)? kernel[6] + row2[19]: row2[19] - kernel[6];
			temp[23] = (operation == 2'b01)? kernel[7] + row2[20]: row2[20] - kernel[7];
			temp[24] = (operation == 2'b01)? kernel[8] + row3[17]: row3[17] - kernel[8];
			temp[25] = (operation == 2'b01)? kernel[9] + row3[18]: row3[18] - kernel[9];
			temp[26] = (operation == 2'b01)? kernel[10] + row3[19]: row3[19] - kernel[10];
			temp[27] = (operation == 2'b01)? kernel[11] + row3[20]: row3[20] - kernel[11];
			temp[28] = (operation == 2'b01)? kernel[12] + row4[17]: row4[17] - kernel[12];
			temp[29] = (operation == 2'b01)? kernel[13] + row4[18]: row4[18] - kernel[13];
			temp[30] = (operation == 2'b01)? kernel[14] + row4[19]: row4[19] - kernel[14];
			temp[31] = (operation == 2'b01)? kernel[15] + row4[20]: row4[20] - kernel[15];
			 temp[32] =  (operation == 2'b01)? kernel[0] + row1[18]: row1[18] - kernel[0];
			 temp[33] =  (operation == 2'b01)? kernel[1] + row1[19]: row1[19] - kernel[1];
			 temp[34] =  (operation == 2'b01)? kernel[2] + row1[20]: row1[20] - kernel[2];
			 temp[35] =  (operation == 2'b01)? kernel[3] + row1[21]: row1[21] - kernel[3];
			 temp[36] =  (operation == 2'b01)? kernel[4] + row2[18]: row2[18] - kernel[4];
			 temp[37] =  (operation == 2'b01)? kernel[5] + row2[19]: row2[19] - kernel[5];
			 temp[38] =  (operation == 2'b01)? kernel[6] + row2[20]: row2[20] - kernel[6];
			 temp[39] =  (operation == 2'b01)? kernel[7] + row2[21]: row2[21] - kernel[7];
			 temp[40] =  (operation == 2'b01)? kernel[8] + row3[18]: row3[18] - kernel[8];
			 temp[41] =  (operation == 2'b01)? kernel[9] + row3[19]: row3[19] - kernel[9];
			 temp[42] =  (operation == 2'b01)? kernel[10] + row3[20]: row3[20] - kernel[10];
			 temp[43] =  (operation == 2'b01)? kernel[11] + row3[21]: row3[21] - kernel[11];
			 temp[44] =  (operation == 2'b01)? kernel[12] + row4[18]: row4[18] - kernel[12];
			 temp[45] =  (operation == 2'b01)? kernel[13] + row4[19]: row4[19] - kernel[13];
			 temp[46] =  (operation == 2'b01)? kernel[14] + row4[20]: row4[20] - kernel[14];
			 temp[47] =  (operation == 2'b01)? kernel[15] + row4[21]: row4[21] - kernel[15];
			 temp[48] =  (operation == 2'b01)? kernel[0] + row1[19]: row1[19] - kernel[0];
			 temp[49] =  (operation == 2'b01)? kernel[1] + row1[20]: row1[20] - kernel[1];
			 temp[50] =  (operation == 2'b01)? kernel[2] + row1[21]: row1[21] - kernel[2];
			 temp[51] =  (operation == 2'b01)? kernel[3] + row1[22]: row1[22] - kernel[3];
			 temp[52] =  (operation == 2'b01)? kernel[4] + row2[19]: row2[19] - kernel[4];
			 temp[53] =  (operation == 2'b01)? kernel[5] + row2[20]: row2[20] - kernel[5];
			 temp[54] =  (operation == 2'b01)? kernel[6] + row2[21]: row2[21] - kernel[6];
			 temp[55] =  (operation == 2'b01)? kernel[7] + row2[22]: row2[22] - kernel[7];
			 temp[56] =  (operation == 2'b01)? kernel[8] + row3[19]: row3[19] - kernel[8];
			 temp[57] =  (operation == 2'b01)? kernel[9] + row3[20]: row3[20] - kernel[9];
			 temp[58] =  (operation == 2'b01)? kernel[10] + row3[21]: row3[21] - kernel[10];
			 temp[59] =  (operation == 2'b01)? kernel[11] + row3[22]: row3[22] - kernel[11];
			 temp[60] =  (operation == 2'b01)? kernel[12] + row4[19]: row4[19] - kernel[12];
			 temp[61] =  (operation == 2'b01)? kernel[13] + row4[20]: row4[20] - kernel[13];
			 temp[62] =  (operation == 2'b01)? kernel[14] + row4[21]: row4[21] - kernel[14];
			 temp[63] =  (operation == 2'b01)? kernel[15] + row4[22]: row4[22] - kernel[15];
			 temp[64] =  (operation == 2'b01)? kernel[0] + row1[20]: row1[20] - kernel[0];
			 temp[65] =  (operation == 2'b01)? kernel[1] + row1[21]: row1[21] - kernel[1];
			 temp[66] =  (operation == 2'b01)? kernel[2] + row1[22]: row1[22] - kernel[2];
			 temp[67] =  (operation == 2'b01)? kernel[3] + row1[23]: row1[23] - kernel[3];
			 temp[68] =  (operation == 2'b01)? kernel[4] + row2[20]: row2[20] - kernel[4];
			 temp[69] =  (operation == 2'b01)? kernel[5] + row2[21]: row2[21] - kernel[5];
			 temp[70] =  (operation == 2'b01)? kernel[6] + row2[22]: row2[22] - kernel[6];
			 temp[71] =  (operation == 2'b01)? kernel[7] + row2[23]: row2[23] - kernel[7];
			 temp[72] =  (operation == 2'b01)? kernel[8] + row3[20]: row3[20] - kernel[8];
			 temp[73] =  (operation == 2'b01)? kernel[9] + row3[21]: row3[21] - kernel[9];
			 temp[74] =  (operation == 2'b01)? kernel[10] + row3[22]: row3[22] - kernel[10];
			 temp[75] =  (operation == 2'b01)? kernel[11] + row3[23]: row3[23] - kernel[11];
			 temp[76] =  (operation == 2'b01)? kernel[12] + row4[20]: row4[20] - kernel[12];
			 temp[77] =  (operation == 2'b01)? kernel[13] + row4[21]: row4[21] - kernel[13];
			 temp[78] =  (operation == 2'b01)? kernel[14] + row4[22]: row4[22] - kernel[14];
			 temp[79] =  (operation == 2'b01)? kernel[15] + row4[23]: row4[23] - kernel[15];
			 temp[80] =  (operation == 2'b01)? kernel[0] + row1[21]: row1[21] - kernel[0];
			 temp[81] =  (operation == 2'b01)? kernel[1] + row1[22]: row1[22] - kernel[1];
			 temp[82] =  (operation == 2'b01)? kernel[2] + row1[23]: row1[23] - kernel[2];
			 temp[83] =  (operation == 2'b01)? kernel[3] + row1[24]: row1[24] - kernel[3];
			 temp[84] =  (operation == 2'b01)? kernel[4] + row2[21]: row2[21] - kernel[4];
			 temp[85] =  (operation == 2'b01)? kernel[5] + row2[22]: row2[22] - kernel[5];
			 temp[86] =  (operation == 2'b01)? kernel[6] + row2[23]: row2[23] - kernel[6];
			 temp[87] =  (operation == 2'b01)? kernel[7] + row2[24]: row2[24] - kernel[7];
			 temp[88] =  (operation == 2'b01)? kernel[8] + row3[21]: row3[21] - kernel[8];
			 temp[89] =  (operation == 2'b01)? kernel[9] + row3[22]: row3[22] - kernel[9];
			 temp[90] =  (operation == 2'b01)? kernel[10] + row3[23]: row3[23] - kernel[10];
			 temp[91] =  (operation == 2'b01)? kernel[11] + row3[24]: row3[24] - kernel[11];
			 temp[92] =  (operation == 2'b01)? kernel[12] + row4[21]: row4[21] - kernel[12];
			 temp[93] =  (operation == 2'b01)? kernel[13] + row4[22]: row4[22] - kernel[13];
			 temp[94] =  (operation == 2'b01)? kernel[14] + row4[23]: row4[23] - kernel[14];
			 temp[95] =  (operation == 2'b01)? kernel[15] + row4[24]: row4[24] - kernel[15];
			 temp[96] =  (operation == 2'b01)? kernel[0] + row1[22] : row1[22] - kernel[0];
			 temp[97] =  (operation == 2'b01)? kernel[1] + row1[23] : row1[23] - kernel[1];
			 temp[98] =  (operation == 2'b01)? kernel[2] + row1[24] : row1[24] - kernel[2];
			 temp[99] =  (operation == 2'b01)? kernel[3] + row1[25] : row1[25] - kernel[3];
			 temp[100] =  (operation == 2'b01)? kernel[4] + row2[22] : row2[22] - kernel[4];
			 temp[101] =  (operation == 2'b01)? kernel[5] + row2[23] : row2[23] - kernel[5];
			 temp[102] =  (operation == 2'b01)? kernel[6] + row2[24] : row2[24] - kernel[6];
			 temp[103] =  (operation == 2'b01)? kernel[7] + row2[25] : row2[25] - kernel[7];
			 temp[104] =  (operation == 2'b01)? kernel[8] + row3[22] : row3[22] - kernel[8];
			 temp[105] =  (operation == 2'b01)? kernel[9] + row3[23] : row3[23] - kernel[9];
			 temp[106] =  (operation == 2'b01)? kernel[10] + row3[24] : row3[24] - kernel[10];
			 temp[107] =  (operation == 2'b01)? kernel[11] + row3[25] : row3[25] - kernel[11];
			 temp[108] =  (operation == 2'b01)? kernel[12] + row4[22] : row4[22] - kernel[12];
			 temp[109] =  (operation == 2'b01)? kernel[13] + row4[23] : row4[23] - kernel[13];
			 temp[110] =  (operation == 2'b01)? kernel[14] + row4[24] : row4[24] - kernel[14];
			 temp[111] =  (operation == 2'b01)? kernel[15] + row4[25] : row4[25] - kernel[15];
			 temp[112] =  (operation == 2'b01)? kernel[0] + row1[23]: row1[23] - kernel[0];
			 temp[113] =  (operation == 2'b01)? kernel[1] + row1[24]: row1[24] - kernel[1];
			 temp[114] =  (operation == 2'b01)? kernel[2] + row1[25]: row1[25] - kernel[2];
			 temp[115] =  (operation == 2'b01)? kernel[3] + row1[26]: row1[26] - kernel[3];
			 temp[116] =  (operation == 2'b01)? kernel[4] + row2[23]: row2[23] - kernel[4];
			 temp[117] =  (operation == 2'b01)? kernel[5] + row2[24]: row2[24] - kernel[5];
			 temp[118] =  (operation == 2'b01)? kernel[6] + row2[25]: row2[25] - kernel[6];
			 temp[119] =  (operation == 2'b01)? kernel[7] + row2[26]: row2[26] - kernel[7];
			 temp[120] =  (operation == 2'b01)? kernel[8] + row3[23]: row3[23] - kernel[8];
			 temp[121] =  (operation == 2'b01)? kernel[9] + row3[24]: row3[24] - kernel[9];
			 temp[122] =  (operation == 2'b01)? kernel[10] + row3[25]: row3[25] - kernel[10];
			 temp[123] =  (operation == 2'b01)? kernel[11] + row3[26]: row3[26] - kernel[11];
			 temp[124] =  (operation == 2'b01)? kernel[12] + row4[23]: row4[23] - kernel[12];
			 temp[125] =  (operation == 2'b01)? kernel[13] + row4[24]: row4[24] - kernel[13];
			 temp[126] =  (operation == 2'b01)? kernel[14] + row4[25]: row4[25] - kernel[14];
			 temp[127] =  (operation == 2'b01)? kernel[15] + row4[26]: row4[26] - kernel[15];
			 temp[128] =  (operation == 2'b01)? kernel[0] + row1[24]: row1[24] - kernel[0];
			 temp[129] =  (operation == 2'b01)? kernel[1] + row1[25]: row1[25] - kernel[1];
			 temp[130] =  (operation == 2'b01)? kernel[2] + row1[26]: row1[26] - kernel[2];
			 temp[131] =  (operation == 2'b01)? kernel[3] + row1[27]: row1[27] - kernel[3];
			 temp[132] =  (operation == 2'b01)? kernel[4] + row2[24]: row2[24] - kernel[4];
			 temp[133] =  (operation == 2'b01)? kernel[5] + row2[25]: row2[25] - kernel[5];
			 temp[134] =  (operation == 2'b01)? kernel[6] + row2[26]: row2[26] - kernel[6];
			 temp[135] =  (operation == 2'b01)? kernel[7] + row2[27]: row2[27] - kernel[7];
			 temp[136] =  (operation == 2'b01)? kernel[8] + row3[24]: row3[24] - kernel[8];
			 temp[137] =  (operation == 2'b01)? kernel[9] + row3[25]: row3[25] - kernel[9];
			 temp[138] =  (operation == 2'b01)? kernel[10] + row3[26]: row3[26] - kernel[10];
			 temp[139] =  (operation == 2'b01)? kernel[11] + row3[27]: row3[27] - kernel[11];
			 temp[140] =  (operation == 2'b01)? kernel[12] + row4[24]: row4[24] - kernel[12];
			 temp[141] =  (operation == 2'b01)? kernel[13] + row4[25]: row4[25] - kernel[13];
			 temp[142] =  (operation == 2'b01)? kernel[14] + row4[26]: row4[26] - kernel[14];
			 temp[143] =  (operation == 2'b01)? kernel[15] + row4[27]: row4[27] - kernel[15];
			 temp[144] =  (operation == 2'b01)? kernel[0] + row1[25]: row1[25] - kernel[0];
			 temp[145] =  (operation == 2'b01)? kernel[1] + row1[26]: row1[26] - kernel[1];
			 temp[146] =  (operation == 2'b01)? kernel[2] + row1[27]: row1[27] - kernel[2];
			 temp[147] =  (operation == 2'b01)? kernel[3] + row1[28]: row1[28] - kernel[3];
			 temp[148] =  (operation == 2'b01)? kernel[4] + row2[25]: row2[25] - kernel[4];
			 temp[149] =  (operation == 2'b01)? kernel[5] + row2[26]: row2[26] - kernel[5];
			 temp[150] =  (operation == 2'b01)? kernel[6] + row2[27]: row2[27] - kernel[6];
			 temp[151] =  (operation == 2'b01)? kernel[7] + row2[28]: row2[28] - kernel[7];
			 temp[152] =  (operation == 2'b01)? kernel[8] + row3[25]: row3[25] - kernel[8];
			 temp[153] =  (operation == 2'b01)? kernel[9] + row3[26]: row3[26] - kernel[9];
			 temp[154] =  (operation == 2'b01)? kernel[10] + row3[27]: row3[27] - kernel[10];
			 temp[155] =  (operation == 2'b01)? kernel[11] + row3[28]: row3[28] - kernel[11];
			 temp[156] =  (operation == 2'b01)? kernel[12] + row4[25]: row4[25] - kernel[12];
			 temp[157] =  (operation == 2'b01)? kernel[13] + row4[26]: row4[26] - kernel[13];
			 temp[158] =  (operation == 2'b01)? kernel[14] + row4[27]: row4[27] - kernel[14];
			 temp[159] =  (operation == 2'b01)? kernel[15] + row4[28]: row4[28] - kernel[15];
			 temp[160] =  (operation == 2'b01)? kernel[0] + row1[26]: row1[26] - kernel[0];
			 temp[161] =  (operation == 2'b01)? kernel[1] + row1[27]: row1[27] - kernel[1];
			 temp[162] =  (operation == 2'b01)? kernel[2] + row1[28]: row1[28] - kernel[2];
			 temp[163] =  (operation == 2'b01)? kernel[3] + row1[29]: row1[29] - kernel[3];
			 temp[164] =  (operation == 2'b01)? kernel[4] + row2[26]: row2[26] - kernel[4];
			 temp[165] =  (operation == 2'b01)? kernel[5] + row2[27]: row2[27] - kernel[5];
			 temp[166] =  (operation == 2'b01)? kernel[6] + row2[28]: row2[28] - kernel[6];
			 temp[167] =  (operation == 2'b01)? kernel[7] + row2[29]: row2[29] - kernel[7];
			 temp[168] =  (operation == 2'b01)? kernel[8] + row3[26]: row3[26] - kernel[8];
			 temp[169] =  (operation == 2'b01)? kernel[9] + row3[27]: row3[27] - kernel[9];
			 temp[170] =  (operation == 2'b01)? kernel[10] + row3[28]: row3[28] - kernel[10];
			 temp[171] =  (operation == 2'b01)? kernel[11] + row3[29]: row3[29] - kernel[11];
			 temp[172] =  (operation == 2'b01)? kernel[12] + row4[26]: row4[26] - kernel[12];
			 temp[173] =  (operation == 2'b01)? kernel[13] + row4[27]: row4[27] - kernel[13];
			 temp[174] =  (operation == 2'b01)? kernel[14] + row4[28]: row4[28] - kernel[14];
			 temp[175] =  (operation == 2'b01)? kernel[15] + row4[29]: row4[29] - kernel[15];
			 temp[176] =  (operation == 2'b01)? kernel[0] + row1[27]: row1[27] - kernel[0];
			 temp[177] =  (operation == 2'b01)? kernel[1] + row1[28]: row1[28] - kernel[1];
			 temp[178] =  (operation == 2'b01)? kernel[2] + row1[29]: row1[29] - kernel[2];
			 temp[179] =  (operation == 2'b01)? kernel[3] + row1[30]: row1[30] - kernel[3];
			 temp[180] =  (operation == 2'b01)? kernel[4] + row2[27]: row2[27] - kernel[4];
			 temp[181] =  (operation == 2'b01)? kernel[5] + row2[28]: row2[28] - kernel[5];
			 temp[182] =  (operation == 2'b01)? kernel[6] + row2[29]: row2[29] - kernel[6];
			 temp[183] =  (operation == 2'b01)? kernel[7] + row2[30]: row2[30] - kernel[7];
			 temp[184] =  (operation == 2'b01)? kernel[8] + row3[27]: row3[27] - kernel[8];
			 temp[185] =  (operation == 2'b01)? kernel[9] + row3[28]: row3[28] - kernel[9];
			 temp[186] =  (operation == 2'b01)? kernel[10] + row3[29]: row3[29] - kernel[10];
			 temp[187] =  (operation == 2'b01)? kernel[11] + row3[30]: row3[30] - kernel[11];
			 temp[188] =  (operation == 2'b01)? kernel[12] + row4[27]: row4[27] - kernel[12];
			 temp[189] =  (operation == 2'b01)? kernel[13] + row4[28]: row4[28] - kernel[13];
			 temp[190] =  (operation == 2'b01)? kernel[14] + row4[29]: row4[29] - kernel[14];
			 temp[191] =  (operation == 2'b01)? kernel[15] + row4[30]: row4[30] - kernel[15];
			 temp[192] =  (operation == 2'b01)? kernel[0] + row1[28]: row1[28] - kernel[0];
			 temp[193] =  (operation == 2'b01)? kernel[1] + row1[29]: row1[29] - kernel[1];
			 temp[194] =  (operation == 2'b01)? kernel[2] + row1[30]: row1[30] - kernel[2];
			 temp[195] =  (operation == 2'b01)? kernel[3] + row1[31]: row1[31] - kernel[3];
			 temp[196] =  (operation == 2'b01)? kernel[4] + row2[28]: row2[28] - kernel[4];
			 temp[197] =  (operation == 2'b01)? kernel[5] + row2[29]: row2[29] - kernel[5];
			 temp[198] =  (operation == 2'b01)? kernel[6] + row2[30]: row2[30] - kernel[6];
			 temp[199] =  (operation == 2'b01)? kernel[7] + row2[31]: row2[31] - kernel[7];
			 temp[200] =  (operation == 2'b01)? kernel[8] + row3[28]: row3[28] - kernel[8];
			 temp[201] =  (operation == 2'b01)? kernel[9] + row3[29]: row3[29] - kernel[9];
			 temp[202] =  (operation == 2'b01)? kernel[10] + row3[30]: row3[30] - kernel[10];
			 temp[203] =  (operation == 2'b01)? kernel[11] + row3[31]: row3[31] - kernel[11];
			 temp[204] =  (operation == 2'b01)? kernel[12] + row4[28]: row4[28] - kernel[12];
			 temp[205] =  (operation == 2'b01)? kernel[13] + row4[29]: row4[29] - kernel[13];
			 temp[206] =  (operation == 2'b01)? kernel[14] + row4[30]: row4[30] - kernel[14];
			 temp[207] =  (operation == 2'b01)? kernel[15] + row4[31]: row4[31] - kernel[15];
			 temp[208] =  (operation == 2'b01)? kernel[0] + row1[29]: row1[29] - kernel[0];
			 temp[209] =  (operation == 2'b01)? kernel[1] + row1[30]: row1[30] - kernel[1];
			 temp[210] =  (operation == 2'b01)? kernel[2] + row1[31]: row1[31] - kernel[2];
			 temp[211] =  (operation == 2'b01)? kernel[3] + row1[32]: row1[32] - kernel[3];
			 temp[212] =  (operation == 2'b01)? kernel[4] + row2[29]: row2[29] - kernel[4];
			 temp[213] =  (operation == 2'b01)? kernel[5] + row2[30]: row2[30] - kernel[5];
			 temp[214] =  (operation == 2'b01)? kernel[6] + row2[31]: row2[31] - kernel[6];
			 temp[215] =  (operation == 2'b01)? kernel[7] + row2[32]: row2[32] - kernel[7];
			 temp[216] =  (operation == 2'b01)? kernel[8] + row3[29]: row3[29] - kernel[8];
			 temp[217] =  (operation == 2'b01)? kernel[9] + row3[30]: row3[30] - kernel[9];
			 temp[218] =  (operation == 2'b01)? kernel[10] + row3[31]: row3[31] - kernel[10];
			 temp[219] =  (operation == 2'b01)? kernel[11] + row3[32]: row3[32] - kernel[11];
			 temp[220] =  (operation == 2'b01)? kernel[12] + row4[29]: row4[29] - kernel[12];
			 temp[221] =  (operation == 2'b01)? kernel[13] + row4[30]: row4[30] - kernel[13];
			 temp[222] =  (operation == 2'b01)? kernel[14] + row4[31]: row4[31] - kernel[14];
			 temp[223] =  (operation == 2'b01)? kernel[15] + row4[32]: row4[32] - kernel[15];
			 temp[224] =  (operation == 2'b01)? kernel[0] + row1[30]: row1[30] - kernel[0];
			 temp[225] =  (operation == 2'b01)? kernel[1] + row1[31]: row1[31] - kernel[1];
			 temp[226] =  (operation == 2'b01)? kernel[2] + row1[32]: row1[32] - kernel[2];
			 temp[227] =  (operation == 2'b01)? kernel[3] + row1[33]: row1[33] - kernel[3];
			 temp[228] =  (operation == 2'b01)? kernel[4] + row2[30]: row2[30] - kernel[4];
			 temp[229] =  (operation == 2'b01)? kernel[5] + row2[31]: row2[31] - kernel[5];
			 temp[230] =  (operation == 2'b01)? kernel[6] + row2[32]: row2[32] - kernel[6];
			 temp[231] =  (operation == 2'b01)? kernel[7] + row2[33]: row2[33] - kernel[7];
			 temp[232] =  (operation == 2'b01)? kernel[8] + row3[30]: row3[30] - kernel[8];
			 temp[233] =  (operation == 2'b01)? kernel[9] + row3[31]: row3[31] - kernel[9];
			 temp[234] =  (operation == 2'b01)? kernel[10] + row3[32]: row3[32] - kernel[10];
			 temp[235] =  (operation == 2'b01)? kernel[11] + row3[33]: row3[33] - kernel[11];
			 temp[236] =  (operation == 2'b01)? kernel[12] + row4[30]: row4[30] - kernel[12];
			 temp[237] =  (operation == 2'b01)? kernel[13] + row4[31]: row4[31] - kernel[13];
			 temp[238] =  (operation == 2'b01)? kernel[14] + row4[32]: row4[32] - kernel[14];
			 temp[239] =  (operation == 2'b01)? kernel[15] + row4[33]: row4[33] - kernel[15];
			 temp[240] =  (operation == 2'b01)? kernel[0] + row1[31]: row1[31] - kernel[0];
			 temp[241] =  (operation == 2'b01)? kernel[1] + row1[32]: row1[32] - kernel[1];
			 temp[242] =  (operation == 2'b01)? kernel[2] + row1[33]: row1[33] - kernel[2];
			 temp[243] =  (operation == 2'b01)? kernel[3] + row1[34]: row1[34] - kernel[3];
			 temp[244] =  (operation == 2'b01)? kernel[4] + row2[31]: row2[31] - kernel[4];
			 temp[245] =  (operation == 2'b01)? kernel[5] + row2[32]: row2[32] - kernel[5];
			 temp[246] =  (operation == 2'b01)? kernel[6] + row2[33]: row2[33] - kernel[6];
			 temp[247] =  (operation == 2'b01)? kernel[7] + row2[34]: row2[34] - kernel[7];
			 temp[248] =  (operation == 2'b01)? kernel[8] + row3[31]: row3[31] - kernel[8];
			 temp[249] =  (operation == 2'b01)? kernel[9] + row3[32]: row3[32] - kernel[9];
			 temp[250] =  (operation == 2'b01)? kernel[10] + row3[33]: row3[33] - kernel[10];
			 temp[251] =  (operation == 2'b01)? kernel[11] + row3[34]: row3[34] - kernel[11];
			 temp[252] =  (operation == 2'b01)? kernel[12] + row4[31]: row4[31] - kernel[12];
			 temp[253] =  (operation == 2'b01)? kernel[13] + row4[32]: row4[32] - kernel[13];
			 temp[254] =  (operation == 2'b01)? kernel[14] + row4[33]: row4[33] - kernel[14];
			 temp[255] =  (operation == 2'b01)? kernel[15] + row4[34]: row4[34] - kernel[15];
		end
		2'd2: begin
			temp[0] =  (operation == 2'b01)? kernel[0] + row1[32] : row1[32] - kernel[0];
			temp[1] =  (operation == 2'b01)? kernel[1] + row1[33] : row1[33] - kernel[1];
			temp[2] =  (operation == 2'b01)? kernel[2] + row1[34] : row1[34] - kernel[2];
			temp[3] =  (operation == 2'b01)? kernel[3] + row1[35] : row1[35] - kernel[3];
			temp[4] =  (operation == 2'b01)? kernel[4] + row2[32] : row2[32] - kernel[4];
			temp[5] =  (operation == 2'b01)? kernel[5] + row2[33] : row2[33] - kernel[5];
			temp[6] =  (operation == 2'b01)? kernel[6] + row2[34] : row2[34] - kernel[6];
			temp[7] =  (operation == 2'b01)? kernel[7] + row2[35] : row2[35] - kernel[7];
			temp[8] =  (operation == 2'b01)? kernel[8] + row3[32] : row3[32] - kernel[8];
			temp[9] =  (operation == 2'b01)? kernel[9] + row3[33] : row3[33] - kernel[9];
			temp[10] =  (operation == 2'b01)? kernel[10] + row3[34] : row3[34] - kernel[10];
			temp[11] =  (operation == 2'b01)? kernel[11] + row3[35] : row3[35] - kernel[11];
			temp[12] =  (operation == 2'b01)? kernel[12] + row4[32] : row4[32] - kernel[12];
			temp[13] =  (operation == 2'b01)? kernel[13] + row4[33] : row4[33] - kernel[13];
			temp[14] =  (operation == 2'b01)? kernel[14] + row4[34] : row4[34] - kernel[14];
			temp[15] =  (operation == 2'b01)? kernel[15] + row4[35] : row4[35] - kernel[15];
			temp[16] = (operation == 2'b01)? kernel[0] + row1[33]: row1[33] - kernel[0];
			temp[17] = (operation == 2'b01)? kernel[1] + row1[34]: row1[34] - kernel[1];
			temp[18] = (operation == 2'b01)? kernel[2] + row1[35]: row1[35] - kernel[2];
			temp[19] = (operation == 2'b01)? kernel[3] + row1[36]: row1[36] - kernel[3];
			temp[20] = (operation == 2'b01)? kernel[4] + row2[33]: row2[33] - kernel[4];
			temp[21] = (operation == 2'b01)? kernel[5] + row2[34]: row2[34] - kernel[5];
			temp[22] = (operation == 2'b01)? kernel[6] + row2[35]: row2[35] - kernel[6];
			temp[23] = (operation == 2'b01)? kernel[7] + row2[36]: row2[36] - kernel[7];
			temp[24] = (operation == 2'b01)? kernel[8] + row3[33]: row3[33] - kernel[8];
			temp[25] = (operation == 2'b01)? kernel[9] + row3[34]: row3[34] - kernel[9];
			temp[26] = (operation == 2'b01)? kernel[10] + row3[35]: row3[35] - kernel[10];
			temp[27] = (operation == 2'b01)? kernel[11] + row3[36]: row3[36] - kernel[11];
			temp[28] = (operation == 2'b01)? kernel[12] + row4[33]: row4[33] - kernel[12];
			temp[29] = (operation == 2'b01)? kernel[13] + row4[34]: row4[34] - kernel[13];
			temp[30] = (operation == 2'b01)? kernel[14] + row4[35]: row4[35] - kernel[14];
			temp[31] = (operation == 2'b01)? kernel[15] + row4[36]: row4[36] - kernel[15];
			 temp[32] =  (operation == 2'b01)? kernel[0] + row1[34]: row1[34] - kernel[0];
			 temp[33] =  (operation == 2'b01)? kernel[1] + row1[35]: row1[35] - kernel[1];
			 temp[34] =  (operation == 2'b01)? kernel[2] + row1[36]: row1[36] - kernel[2];
			 temp[35] =  (operation == 2'b01)? kernel[3] + row1[37]: row1[37] - kernel[3];
			 temp[36] =  (operation == 2'b01)? kernel[4] + row2[34]: row2[34] - kernel[4];
			 temp[37] =  (operation == 2'b01)? kernel[5] + row2[35]: row2[35] - kernel[5];
			 temp[38] =  (operation == 2'b01)? kernel[6] + row2[36]: row2[36] - kernel[6];
			 temp[39] =  (operation == 2'b01)? kernel[7] + row2[37]: row2[37] - kernel[7];
			 temp[40] =  (operation == 2'b01)? kernel[8] + row3[34]: row3[34] - kernel[8];
			 temp[41] =  (operation == 2'b01)? kernel[9] + row3[35]: row3[35] - kernel[9];
			 temp[42] =  (operation == 2'b01)? kernel[10] + row3[36]: row3[36] - kernel[10];
			 temp[43] =  (operation == 2'b01)? kernel[11] + row3[37]: row3[37] - kernel[11];
			 temp[44] =  (operation == 2'b01)? kernel[12] + row4[34]: row4[34] - kernel[12];
			 temp[45] =  (operation == 2'b01)? kernel[13] + row4[35]: row4[35] - kernel[13];
			 temp[46] =  (operation == 2'b01)? kernel[14] + row4[36]: row4[36] - kernel[14];
			 temp[47] =  (operation == 2'b01)? kernel[15] + row4[37]: row4[37] - kernel[15];
			 temp[48] =  (operation == 2'b01)? kernel[0] + row1[35]: row1[35] - kernel[0];
			 temp[49] =  (operation == 2'b01)? kernel[1] + row1[36]: row1[36] - kernel[1];
			 temp[50] =  (operation == 2'b01)? kernel[2] + row1[37]: row1[37] - kernel[2];
			 temp[51] =  (operation == 2'b01)? kernel[3] + row1[38]: row1[38] - kernel[3];
			 temp[52] =  (operation == 2'b01)? kernel[4] + row2[35]: row2[35] - kernel[4];
			 temp[53] =  (operation == 2'b01)? kernel[5] + row2[36]: row2[36] - kernel[5];
			 temp[54] =  (operation == 2'b01)? kernel[6] + row2[37]: row2[37] - kernel[6];
			 temp[55] =  (operation == 2'b01)? kernel[7] + row2[38]: row2[38] - kernel[7];
			 temp[56] =  (operation == 2'b01)? kernel[8] + row3[35]: row3[35] - kernel[8];
			 temp[57] =  (operation == 2'b01)? kernel[9] + row3[36]: row3[36] - kernel[9];
			 temp[58] =  (operation == 2'b01)? kernel[10] + row3[37]: row3[37] - kernel[10];
			 temp[59] =  (operation == 2'b01)? kernel[11] + row3[38]: row3[38] - kernel[11];
			 temp[60] =  (operation == 2'b01)? kernel[12] + row4[35]: row4[35] - kernel[12];
			 temp[61] =  (operation == 2'b01)? kernel[13] + row4[36]: row4[36] - kernel[13];
			 temp[62] =  (operation == 2'b01)? kernel[14] + row4[37]: row4[37] - kernel[14];
			 temp[63] =  (operation == 2'b01)? kernel[15] + row4[38]: row4[38] - kernel[15];
			 temp[64] =  (operation == 2'b01)? kernel[0] + row1[36]: row1[36] - kernel[0];
			 temp[65] =  (operation == 2'b01)? kernel[1] + row1[37]: row1[37] - kernel[1];
			 temp[66] =  (operation == 2'b01)? kernel[2] + row1[38]: row1[38] - kernel[2];
			 temp[67] =  (operation == 2'b01)? kernel[3] + row1[39]: row1[39] - kernel[3];
			 temp[68] =  (operation == 2'b01)? kernel[4] + row2[36]: row2[36] - kernel[4];
			 temp[69] =  (operation == 2'b01)? kernel[5] + row2[37]: row2[37] - kernel[5];
			 temp[70] =  (operation == 2'b01)? kernel[6] + row2[38]: row2[38] - kernel[6];
			 temp[71] =  (operation == 2'b01)? kernel[7] + row2[39]: row2[39] - kernel[7];
			 temp[72] =  (operation == 2'b01)? kernel[8] + row3[36]: row3[36] - kernel[8];
			 temp[73] =  (operation == 2'b01)? kernel[9] + row3[37]: row3[37] - kernel[9];
			 temp[74] =  (operation == 2'b01)? kernel[10] + row3[38]: row3[38] - kernel[10];
			 temp[75] =  (operation == 2'b01)? kernel[11] + row3[39]: row3[39] - kernel[11];
			 temp[76] =  (operation == 2'b01)? kernel[12] + row4[36]: row4[36] - kernel[12];
			 temp[77] =  (operation == 2'b01)? kernel[13] + row4[37]: row4[37] - kernel[13];
			 temp[78] =  (operation == 2'b01)? kernel[14] + row4[38]: row4[38] - kernel[14];
			 temp[79] =  (operation == 2'b01)? kernel[15] + row4[39]: row4[39] - kernel[15];
			 temp[80] =  (operation == 2'b01)? kernel[0] + row1[37]: row1[37] - kernel[0];
			 temp[81] =  (operation == 2'b01)? kernel[1] + row1[38]: row1[38] - kernel[1];
			 temp[82] =  (operation == 2'b01)? kernel[2] + row1[39]: row1[39] - kernel[2];
			 temp[83] =  (operation == 2'b01)? kernel[3] + row1[40]: row1[40] - kernel[3];
			 temp[84] =  (operation == 2'b01)? kernel[4] + row2[37]: row2[37] - kernel[4];
			 temp[85] =  (operation == 2'b01)? kernel[5] + row2[38]: row2[38] - kernel[5];
			 temp[86] =  (operation == 2'b01)? kernel[6] + row2[39]: row2[39] - kernel[6];
			 temp[87] =  (operation == 2'b01)? kernel[7] + row2[40]: row2[40] - kernel[7];
			 temp[88] =  (operation == 2'b01)? kernel[8] + row3[37]: row3[37] - kernel[8];
			 temp[89] =  (operation == 2'b01)? kernel[9] + row3[38]: row3[38] - kernel[9];
			 temp[90] =  (operation == 2'b01)? kernel[10] + row3[39]: row3[39] - kernel[10];
			 temp[91] =  (operation == 2'b01)? kernel[11] + row3[40]: row3[40] - kernel[11];
			 temp[92] =  (operation == 2'b01)? kernel[12] + row4[37]: row4[37] - kernel[12];
			 temp[93] =  (operation == 2'b01)? kernel[13] + row4[38]: row4[38] - kernel[13];
			 temp[94] =  (operation == 2'b01)? kernel[14] + row4[39]: row4[39] - kernel[14];
			 temp[95] =  (operation == 2'b01)? kernel[15] + row4[40]: row4[40] - kernel[15];
			 temp[96] =  (operation == 2'b01)? kernel[0] + row1[38] : row1[38] - kernel[0];
			 temp[97] =  (operation == 2'b01)? kernel[1] + row1[39] : row1[39] - kernel[1];
			 temp[98] =  (operation == 2'b01)? kernel[2] + row1[40] : row1[40] - kernel[2];
			 temp[99] =  (operation == 2'b01)? kernel[3] + row1[41] : row1[41] - kernel[3];
			 temp[100] =  (operation == 2'b01)? kernel[4] + row2[38] : row2[38] - kernel[4];
			 temp[101] =  (operation == 2'b01)? kernel[5] + row2[39] : row2[39] - kernel[5];
			 temp[102] =  (operation == 2'b01)? kernel[6] + row2[40] : row2[40] - kernel[6];
			 temp[103] =  (operation == 2'b01)? kernel[7] + row2[41] : row2[41] - kernel[7];
			 temp[104] =  (operation == 2'b01)? kernel[8] + row3[38] : row3[38] - kernel[8];
			 temp[105] =  (operation == 2'b01)? kernel[9] + row3[39] : row3[39] - kernel[9];
			 temp[106] =  (operation == 2'b01)? kernel[10] + row3[40] : row3[40] - kernel[10];
			 temp[107] =  (operation == 2'b01)? kernel[11] + row3[41] : row3[41] - kernel[11];
			 temp[108] =  (operation == 2'b01)? kernel[12] + row4[38] : row4[38] - kernel[12];
			 temp[109] =  (operation == 2'b01)? kernel[13] + row4[39] : row4[39] - kernel[13];
			 temp[110] =  (operation == 2'b01)? kernel[14] + row4[40] : row4[40] - kernel[14];
			 temp[111] =  (operation == 2'b01)? kernel[15] + row4[41] : row4[41] - kernel[15];
			 temp[112] =  (operation == 2'b01)? kernel[0] + row1[39]: row1[39] - kernel[0];
			 temp[113] =  (operation == 2'b01)? kernel[1] + row1[40]: row1[40] - kernel[1];
			 temp[114] =  (operation == 2'b01)? kernel[2] + row1[41]: row1[41] - kernel[2];
			 temp[115] =  (operation == 2'b01)? kernel[3] + row1[42]: row1[42] - kernel[3];
			 temp[116] =  (operation == 2'b01)? kernel[4] + row2[39]: row2[39] - kernel[4];
			 temp[117] =  (operation == 2'b01)? kernel[5] + row2[40]: row2[40] - kernel[5];
			 temp[118] =  (operation == 2'b01)? kernel[6] + row2[41]: row2[41] - kernel[6];
			 temp[119] =  (operation == 2'b01)? kernel[7] + row2[42]: row2[42] - kernel[7];
			 temp[120] =  (operation == 2'b01)? kernel[8] + row3[39]: row3[39] - kernel[8];
			 temp[121] =  (operation == 2'b01)? kernel[9] + row3[40]: row3[40] - kernel[9];
			 temp[122] =  (operation == 2'b01)? kernel[10] + row3[41]: row3[41] - kernel[10];
			 temp[123] =  (operation == 2'b01)? kernel[11] + row3[42]: row3[42] - kernel[11];
			 temp[124] =  (operation == 2'b01)? kernel[12] + row4[39]: row4[39] - kernel[12];
			 temp[125] =  (operation == 2'b01)? kernel[13] + row4[40]: row4[40] - kernel[13];
			 temp[126] =  (operation == 2'b01)? kernel[14] + row4[41]: row4[41] - kernel[14];
			 temp[127] =  (operation == 2'b01)? kernel[15] + row4[42]: row4[42] - kernel[15];
			 temp[128] =  (operation == 2'b01)? kernel[0] + row1[40]: row1[40] - kernel[0];
			 temp[129] =  (operation == 2'b01)? kernel[1] + row1[41]: row1[41] - kernel[1];
			 temp[130] =  (operation == 2'b01)? kernel[2] + row1[42]: row1[42] - kernel[2];
			 temp[131] =  (operation == 2'b01)? kernel[3] + row1[43]: row1[43] - kernel[3];
			 temp[132] =  (operation == 2'b01)? kernel[4] + row2[40]: row2[40] - kernel[4];
			 temp[133] =  (operation == 2'b01)? kernel[5] + row2[41]: row2[41] - kernel[5];
			 temp[134] =  (operation == 2'b01)? kernel[6] + row2[42]: row2[42] - kernel[6];
			 temp[135] =  (operation == 2'b01)? kernel[7] + row2[43]: row2[43] - kernel[7];
			 temp[136] =  (operation == 2'b01)? kernel[8] + row3[40]: row3[40] - kernel[8];
			 temp[137] =  (operation == 2'b01)? kernel[9] + row3[41]: row3[41] - kernel[9];
			 temp[138] =  (operation == 2'b01)? kernel[10] + row3[42]: row3[42] - kernel[10];
			 temp[139] =  (operation == 2'b01)? kernel[11] + row3[43]: row3[43] - kernel[11];
			 temp[140] =  (operation == 2'b01)? kernel[12] + row4[40]: row4[40] - kernel[12];
			 temp[141] =  (operation == 2'b01)? kernel[13] + row4[41]: row4[41] - kernel[13];
			 temp[142] =  (operation == 2'b01)? kernel[14] + row4[42]: row4[42] - kernel[14];
			 temp[143] =  (operation == 2'b01)? kernel[15] + row4[43]: row4[43] - kernel[15];
			 temp[144] =  (operation == 2'b01)? kernel[0] + row1[41]: row1[41] - kernel[0];
			 temp[145] =  (operation == 2'b01)? kernel[1] + row1[42]: row1[42] - kernel[1];
			 temp[146] =  (operation == 2'b01)? kernel[2] + row1[43]: row1[43] - kernel[2];
			 temp[147] =  (operation == 2'b01)? kernel[3] + row1[44]: row1[44] - kernel[3];
			 temp[148] =  (operation == 2'b01)? kernel[4] + row2[41]: row2[41] - kernel[4];
			 temp[149] =  (operation == 2'b01)? kernel[5] + row2[42]: row2[42] - kernel[5];
			 temp[150] =  (operation == 2'b01)? kernel[6] + row2[43]: row2[43] - kernel[6];
			 temp[151] =  (operation == 2'b01)? kernel[7] + row2[44]: row2[44] - kernel[7];
			 temp[152] =  (operation == 2'b01)? kernel[8] + row3[41]: row3[41] - kernel[8];
			 temp[153] =  (operation == 2'b01)? kernel[9] + row3[42]: row3[42] - kernel[9];
			 temp[154] =  (operation == 2'b01)? kernel[10] + row3[43]: row3[43] - kernel[10];
			 temp[155] =  (operation == 2'b01)? kernel[11] + row3[44]: row3[44] - kernel[11];
			 temp[156] =  (operation == 2'b01)? kernel[12] + row4[41]: row4[41] - kernel[12];
			 temp[157] =  (operation == 2'b01)? kernel[13] + row4[42]: row4[42] - kernel[13];
			 temp[158] =  (operation == 2'b01)? kernel[14] + row4[43]: row4[43] - kernel[14];
			 temp[159] =  (operation == 2'b01)? kernel[15] + row4[44]: row4[44] - kernel[15];
			 temp[160] =  (operation == 2'b01)? kernel[0] + row1[42]: row1[42] - kernel[0];
			 temp[161] =  (operation == 2'b01)? kernel[1] + row1[43]: row1[43] - kernel[1];
			 temp[162] =  (operation == 2'b01)? kernel[2] + row1[44]: row1[44] - kernel[2];
			 temp[163] =  (operation == 2'b01)? kernel[3] + row1[45]: row1[45] - kernel[3];
			 temp[164] =  (operation == 2'b01)? kernel[4] + row2[42]: row2[42] - kernel[4];
			 temp[165] =  (operation == 2'b01)? kernel[5] + row2[43]: row2[43] - kernel[5];
			 temp[166] =  (operation == 2'b01)? kernel[6] + row2[44]: row2[44] - kernel[6];
			 temp[167] =  (operation == 2'b01)? kernel[7] + row2[45]: row2[45] - kernel[7];
			 temp[168] =  (operation == 2'b01)? kernel[8] + row3[42]: row3[42] - kernel[8];
			 temp[169] =  (operation == 2'b01)? kernel[9] + row3[43]: row3[43] - kernel[9];
			 temp[170] =  (operation == 2'b01)? kernel[10] + row3[44]: row3[44] - kernel[10];
			 temp[171] =  (operation == 2'b01)? kernel[11] + row3[45]: row3[45] - kernel[11];
			 temp[172] =  (operation == 2'b01)? kernel[12] + row4[42]: row4[42] - kernel[12];
			 temp[173] =  (operation == 2'b01)? kernel[13] + row4[43]: row4[43] - kernel[13];
			 temp[174] =  (operation == 2'b01)? kernel[14] + row4[44]: row4[44] - kernel[14];
			 temp[175] =  (operation == 2'b01)? kernel[15] + row4[45]: row4[45] - kernel[15];
			 temp[176] =  (operation == 2'b01)? kernel[0] + row1[43]: row1[43] - kernel[0];
			 temp[177] =  (operation == 2'b01)? kernel[1] + row1[44]: row1[44] - kernel[1];
			 temp[178] =  (operation == 2'b01)? kernel[2] + row1[45]: row1[45] - kernel[2];
			 temp[179] =  (operation == 2'b01)? kernel[3] + row1[46]: row1[46] - kernel[3];
			 temp[180] =  (operation == 2'b01)? kernel[4] + row2[43]: row2[43] - kernel[4];
			 temp[181] =  (operation == 2'b01)? kernel[5] + row2[44]: row2[44] - kernel[5];
			 temp[182] =  (operation == 2'b01)? kernel[6] + row2[45]: row2[45] - kernel[6];
			 temp[183] =  (operation == 2'b01)? kernel[7] + row2[46]: row2[46] - kernel[7];
			 temp[184] =  (operation == 2'b01)? kernel[8] + row3[43]: row3[43] - kernel[8];
			 temp[185] =  (operation == 2'b01)? kernel[9] + row3[44]: row3[44] - kernel[9];
			 temp[186] =  (operation == 2'b01)? kernel[10] + row3[45]: row3[45] - kernel[10];
			 temp[187] =  (operation == 2'b01)? kernel[11] + row3[46]: row3[46] - kernel[11];
			 temp[188] =  (operation == 2'b01)? kernel[12] + row4[43]: row4[43] - kernel[12];
			 temp[189] =  (operation == 2'b01)? kernel[13] + row4[44]: row4[44] - kernel[13];
			 temp[190] =  (operation == 2'b01)? kernel[14] + row4[45]: row4[45] - kernel[14];
			 temp[191] =  (operation == 2'b01)? kernel[15] + row4[46]: row4[46] - kernel[15];
			 temp[192] =  (operation == 2'b01)? kernel[0] + row1[44]: row1[44] - kernel[0];
			 temp[193] =  (operation == 2'b01)? kernel[1] + row1[45]: row1[45] - kernel[1];
			 temp[194] =  (operation == 2'b01)? kernel[2] + row1[46]: row1[46] - kernel[2];
			 temp[195] =  (operation == 2'b01)? kernel[3] + row1[47]: row1[47] - kernel[3];
			 temp[196] =  (operation == 2'b01)? kernel[4] + row2[44]: row2[44] - kernel[4];
			 temp[197] =  (operation == 2'b01)? kernel[5] + row2[45]: row2[45] - kernel[5];
			 temp[198] =  (operation == 2'b01)? kernel[6] + row2[46]: row2[46] - kernel[6];
			 temp[199] =  (operation == 2'b01)? kernel[7] + row2[47]: row2[47] - kernel[7];
			 temp[200] =  (operation == 2'b01)? kernel[8] + row3[44]: row3[44] - kernel[8];
			 temp[201] =  (operation == 2'b01)? kernel[9] + row3[45]: row3[45] - kernel[9];
			 temp[202] =  (operation == 2'b01)? kernel[10] + row3[46]: row3[46] - kernel[10];
			 temp[203] =  (operation == 2'b01)? kernel[11] + row3[47]: row3[47] - kernel[11];
			 temp[204] =  (operation == 2'b01)? kernel[12] + row4[44]: row4[44] - kernel[12];
			 temp[205] =  (operation == 2'b01)? kernel[13] + row4[45]: row4[45] - kernel[13];
			 temp[206] =  (operation == 2'b01)? kernel[14] + row4[46]: row4[46] - kernel[14];
			 temp[207] =  (operation == 2'b01)? kernel[15] + row4[47]: row4[47] - kernel[15];
			 temp[208] =  (operation == 2'b01)? kernel[0] + row1[45]: row1[45] - kernel[0];
			 temp[209] =  (operation == 2'b01)? kernel[1] + row1[46]: row1[46] - kernel[1];
			 temp[210] =  (operation == 2'b01)? kernel[2] + row1[47]: row1[47] - kernel[2];
			 temp[211] =  (operation == 2'b01)? kernel[3] + row1[48]: row1[48] - kernel[3];
			 temp[212] =  (operation == 2'b01)? kernel[4] + row2[45]: row2[45] - kernel[4];
			 temp[213] =  (operation == 2'b01)? kernel[5] + row2[46]: row2[46] - kernel[5];
			 temp[214] =  (operation == 2'b01)? kernel[6] + row2[47]: row2[47] - kernel[6];
			 temp[215] =  (operation == 2'b01)? kernel[7] + row2[48]: row2[48] - kernel[7];
			 temp[216] =  (operation == 2'b01)? kernel[8] + row3[45]: row3[45] - kernel[8];
			 temp[217] =  (operation == 2'b01)? kernel[9] + row3[46]: row3[46] - kernel[9];
			 temp[218] =  (operation == 2'b01)? kernel[10] + row3[47]: row3[47] - kernel[10];
			 temp[219] =  (operation == 2'b01)? kernel[11] + row3[48]: row3[48] - kernel[11];
			 temp[220] =  (operation == 2'b01)? kernel[12] + row4[45]: row4[45] - kernel[12];
			 temp[221] =  (operation == 2'b01)? kernel[13] + row4[46]: row4[46] - kernel[13];
			 temp[222] =  (operation == 2'b01)? kernel[14] + row4[47]: row4[47] - kernel[14];
			 temp[223] =  (operation == 2'b01)? kernel[15] + row4[48]: row4[48] - kernel[15];
			 temp[224] =  (operation == 2'b01)? kernel[0] + row1[46]: row1[46] - kernel[0];
			 temp[225] =  (operation == 2'b01)? kernel[1] + row1[47]: row1[47] - kernel[1];
			 temp[226] =  (operation == 2'b01)? kernel[2] + row1[48]: row1[48] - kernel[2];
			 temp[227] =  (operation == 2'b01)? kernel[3] + row1[49]: row1[49] - kernel[3];
			 temp[228] =  (operation == 2'b01)? kernel[4] + row2[46]: row2[46] - kernel[4];
			 temp[229] =  (operation == 2'b01)? kernel[5] + row2[47]: row2[47] - kernel[5];
			 temp[230] =  (operation == 2'b01)? kernel[6] + row2[48]: row2[48] - kernel[6];
			 temp[231] =  (operation == 2'b01)? kernel[7] + row2[49]: row2[49] - kernel[7];
			 temp[232] =  (operation == 2'b01)? kernel[8] + row3[46]: row3[46] - kernel[8];
			 temp[233] =  (operation == 2'b01)? kernel[9] + row3[47]: row3[47] - kernel[9];
			 temp[234] =  (operation == 2'b01)? kernel[10] + row3[48]: row3[48] - kernel[10];
			 temp[235] =  (operation == 2'b01)? kernel[11] + row3[49]: row3[49] - kernel[11];
			 temp[236] =  (operation == 2'b01)? kernel[12] + row4[46]: row4[46] - kernel[12];
			 temp[237] =  (operation == 2'b01)? kernel[13] + row4[47]: row4[47] - kernel[13];
			 temp[238] =  (operation == 2'b01)? kernel[14] + row4[48]: row4[48] - kernel[14];
			 temp[239] =  (operation == 2'b01)? kernel[15] + row4[49]: row4[49] - kernel[15];
			 temp[240] =  (operation == 2'b01)? kernel[0] + row1[47]: row1[47] - kernel[0];
			 temp[241] =  (operation == 2'b01)? kernel[1] + row1[48]: row1[48] - kernel[1];
			 temp[242] =  (operation == 2'b01)? kernel[2] + row1[49]: row1[49] - kernel[2];
			 temp[243] =  (operation == 2'b01)? kernel[3] + row1[50]: row1[50] - kernel[3];
			 temp[244] =  (operation == 2'b01)? kernel[4] + row2[47]: row2[47] - kernel[4];
			 temp[245] =  (operation == 2'b01)? kernel[5] + row2[48]: row2[48] - kernel[5];
			 temp[246] =  (operation == 2'b01)? kernel[6] + row2[49]: row2[49] - kernel[6];
			 temp[247] =  (operation == 2'b01)? kernel[7] + row2[50]: row2[50] - kernel[7];
			 temp[248] =  (operation == 2'b01)? kernel[8] + row3[47]: row3[47] - kernel[8];
			 temp[249] =  (operation == 2'b01)? kernel[9] + row3[48]: row3[48] - kernel[9];
			 temp[250] =  (operation == 2'b01)? kernel[10] + row3[49]: row3[49] - kernel[10];
			 temp[251] =  (operation == 2'b01)? kernel[11] + row3[50]: row3[50] - kernel[11];
			 temp[252] =  (operation == 2'b01)? kernel[12] + row4[47]: row4[47] - kernel[12];
			 temp[253] =  (operation == 2'b01)? kernel[13] + row4[48]: row4[48] - kernel[13];
			 temp[254] =  (operation == 2'b01)? kernel[14] + row4[49]: row4[49] - kernel[14];
			 temp[255] =  (operation == 2'b01)? kernel[15] + row4[50]: row4[50] - kernel[15];
		end
		2'd3: begin
			temp[0] =  (operation == 2'b01)? kernel[0] + row1[48] : row1[48] - kernel[0];
			temp[1] =  (operation == 2'b01)? kernel[1] + row1[49] : row1[49] - kernel[1];
			temp[2] =  (operation == 2'b01)? kernel[2] + row1[50] : row1[50] - kernel[2];
			temp[3] =  (operation == 2'b01)? kernel[3] + row1[51] : row1[51] - kernel[3];
			temp[4] =  (operation == 2'b01)? kernel[4] + row2[48] : row2[48] - kernel[4];
			temp[5] =  (operation == 2'b01)? kernel[5] + row2[49] : row2[49] - kernel[5];
			temp[6] =  (operation == 2'b01)? kernel[6] + row2[50] : row2[50] - kernel[6];
			temp[7] =  (operation == 2'b01)? kernel[7] + row2[51] : row2[51] - kernel[7];
			temp[8] =  (operation == 2'b01)? kernel[8] + row3[48] : row3[48] - kernel[8];
			temp[9] =  (operation == 2'b01)? kernel[9] + row3[49] : row3[49] - kernel[9];
			temp[10] =  (operation == 2'b01)? kernel[10] + row3[50] : row3[50] - kernel[10];
			temp[11] =  (operation == 2'b01)? kernel[11] + row3[51] : row3[51] - kernel[11];
			temp[12] =  (operation == 2'b01)? kernel[12] + row4[48] : row4[48] - kernel[12];
			temp[13] =  (operation == 2'b01)? kernel[13] + row4[49] : row4[49] - kernel[13];
			temp[14] =  (operation == 2'b01)? kernel[14] + row4[50] : row4[50] - kernel[14];
			temp[15] =  (operation == 2'b01)? kernel[15] + row4[51] : row4[51] - kernel[15];
			temp[16] = (operation == 2'b01)? kernel[0] + row1[49]: row1[49] - kernel[0];
			temp[17] = (operation == 2'b01)? kernel[1] + row1[50]: row1[50] - kernel[1];
			temp[18] = (operation == 2'b01)? kernel[2] + row1[51]: row1[51] - kernel[2];
			temp[19] = (operation == 2'b01)? kernel[3] + row1[52]: row1[52] - kernel[3];
			temp[20] = (operation == 2'b01)? kernel[4] + row2[49]: row2[49] - kernel[4];
			temp[21] = (operation == 2'b01)? kernel[5] + row2[50]: row2[50] - kernel[5];
			temp[22] = (operation == 2'b01)? kernel[6] + row2[51]: row2[51] - kernel[6];
			temp[23] = (operation == 2'b01)? kernel[7] + row2[52]: row2[52] - kernel[7];
			temp[24] = (operation == 2'b01)? kernel[8] + row3[49]: row3[49] - kernel[8];
			temp[25] = (operation == 2'b01)? kernel[9] + row3[50]: row3[50] - kernel[9];
			temp[26] = (operation == 2'b01)? kernel[10] + row3[51]: row3[51] - kernel[10];
			temp[27] = (operation == 2'b01)? kernel[11] + row3[52]: row3[52] - kernel[11];
			temp[28] = (operation == 2'b01)? kernel[12] + row4[49]: row4[49] - kernel[12];
			temp[29] = (operation == 2'b01)? kernel[13] + row4[50]: row4[50] - kernel[13];
			temp[30] = (operation == 2'b01)? kernel[14] + row4[51]: row4[51] - kernel[14];
			temp[31] = (operation == 2'b01)? kernel[15] + row4[52]: row4[52] - kernel[15];
			 temp[32] =  (operation == 2'b01)? kernel[0] + row1[50]: row1[50] - kernel[0];
			 temp[33] =  (operation == 2'b01)? kernel[1] + row1[51]: row1[51] - kernel[1];
			 temp[34] =  (operation == 2'b01)? kernel[2] + row1[52]: row1[52] - kernel[2];
			 temp[35] =  (operation == 2'b01)? kernel[3] + row1[53]: row1[53] - kernel[3];
			 temp[36] =  (operation == 2'b01)? kernel[4] + row2[50]: row2[50] - kernel[4];
			 temp[37] =  (operation == 2'b01)? kernel[5] + row2[51]: row2[51] - kernel[5];
			 temp[38] =  (operation == 2'b01)? kernel[6] + row2[52]: row2[52] - kernel[6];
			 temp[39] =  (operation == 2'b01)? kernel[7] + row2[53]: row2[53] - kernel[7];
			 temp[40] =  (operation == 2'b01)? kernel[8] + row3[50]: row3[50] - kernel[8];
			 temp[41] =  (operation == 2'b01)? kernel[9] + row3[51]: row3[51] - kernel[9];
			 temp[42] =  (operation == 2'b01)? kernel[10] + row3[52]: row3[52] - kernel[10];
			 temp[43] =  (operation == 2'b01)? kernel[11] + row3[53]: row3[53] - kernel[11];
			 temp[44] =  (operation == 2'b01)? kernel[12] + row4[50]: row4[50] - kernel[12];
			 temp[45] =  (operation == 2'b01)? kernel[13] + row4[51]: row4[51] - kernel[13];
			 temp[46] =  (operation == 2'b01)? kernel[14] + row4[52]: row4[52] - kernel[14];
			 temp[47] =  (operation == 2'b01)? kernel[15] + row4[53]: row4[53] - kernel[15];
			 temp[48] =  (operation == 2'b01)? kernel[0] + row1[51]: row1[51] - kernel[0];
			 temp[49] =  (operation == 2'b01)? kernel[1] + row1[52]: row1[52] - kernel[1];
			 temp[50] =  (operation == 2'b01)? kernel[2] + row1[53]: row1[53] - kernel[2];
			 temp[51] =  (operation == 2'b01)? kernel[3] + row1[54]: row1[54] - kernel[3];
			 temp[52] =  (operation == 2'b01)? kernel[4] + row2[51]: row2[51] - kernel[4];
			 temp[53] =  (operation == 2'b01)? kernel[5] + row2[52]: row2[52] - kernel[5];
			 temp[54] =  (operation == 2'b01)? kernel[6] + row2[53]: row2[53] - kernel[6];
			 temp[55] =  (operation == 2'b01)? kernel[7] + row2[54]: row2[54] - kernel[7];
			 temp[56] =  (operation == 2'b01)? kernel[8] + row3[51]: row3[51] - kernel[8];
			 temp[57] =  (operation == 2'b01)? kernel[9] + row3[52]: row3[52] - kernel[9];
			 temp[58] =  (operation == 2'b01)? kernel[10] + row3[53]: row3[53] - kernel[10];
			 temp[59] =  (operation == 2'b01)? kernel[11] + row3[54]: row3[54] - kernel[11];
			 temp[60] =  (operation == 2'b01)? kernel[12] + row4[51]: row4[51] - kernel[12];
			 temp[61] =  (operation == 2'b01)? kernel[13] + row4[52]: row4[52] - kernel[13];
			 temp[62] =  (operation == 2'b01)? kernel[14] + row4[53]: row4[53] - kernel[14];
			 temp[63] =  (operation == 2'b01)? kernel[15] + row4[54]: row4[54] - kernel[15];
			 temp[64] =  (operation == 2'b01)? kernel[0] + row1[52]: row1[52] - kernel[0];
			 temp[65] =  (operation == 2'b01)? kernel[1] + row1[53]: row1[53] - kernel[1];
			 temp[66] =  (operation == 2'b01)? kernel[2] + row1[54]: row1[54] - kernel[2];
			 temp[67] =  (operation == 2'b01)? kernel[3] + row1[55]: row1[55] - kernel[3];
			 temp[68] =  (operation == 2'b01)? kernel[4] + row2[52]: row2[52] - kernel[4];
			 temp[69] =  (operation == 2'b01)? kernel[5] + row2[53]: row2[53] - kernel[5];
			 temp[70] =  (operation == 2'b01)? kernel[6] + row2[54]: row2[54] - kernel[6];
			 temp[71] =  (operation == 2'b01)? kernel[7] + row2[55]: row2[55] - kernel[7];
			 temp[72] =  (operation == 2'b01)? kernel[8] + row3[52]: row3[52] - kernel[8];
			 temp[73] =  (operation == 2'b01)? kernel[9] + row3[53]: row3[53] - kernel[9];
			 temp[74] =  (operation == 2'b01)? kernel[10] + row3[54]: row3[54] - kernel[10];
			 temp[75] =  (operation == 2'b01)? kernel[11] + row3[55]: row3[55] - kernel[11];
			 temp[76] =  (operation == 2'b01)? kernel[12] + row4[52]: row4[52] - kernel[12];
			 temp[77] =  (operation == 2'b01)? kernel[13] + row4[53]: row4[53] - kernel[13];
			 temp[78] =  (operation == 2'b01)? kernel[14] + row4[54]: row4[54] - kernel[14];
			 temp[79] =  (operation == 2'b01)? kernel[15] + row4[55]: row4[55] - kernel[15];
			 temp[80] =  (operation == 2'b01)? kernel[0] + row1[53]: row1[53] - kernel[0];
			 temp[81] =  (operation == 2'b01)? kernel[1] + row1[54]: row1[54] - kernel[1];
			 temp[82] =  (operation == 2'b01)? kernel[2] + row1[55]: row1[55] - kernel[2];
			 temp[83] =  (operation == 2'b01)? kernel[3] + row1[56]: row1[56] - kernel[3];
			 temp[84] =  (operation == 2'b01)? kernel[4] + row2[53]: row2[53] - kernel[4];
			 temp[85] =  (operation == 2'b01)? kernel[5] + row2[54]: row2[54] - kernel[5];
			 temp[86] =  (operation == 2'b01)? kernel[6] + row2[55]: row2[55] - kernel[6];
			 temp[87] =  (operation == 2'b01)? kernel[7] + row2[56]: row2[56] - kernel[7];
			 temp[88] =  (operation == 2'b01)? kernel[8] + row3[53]: row3[53] - kernel[8];
			 temp[89] =  (operation == 2'b01)? kernel[9] + row3[54]: row3[54] - kernel[9];
			 temp[90] =  (operation == 2'b01)? kernel[10] + row3[55]: row3[55] - kernel[10];
			 temp[91] =  (operation == 2'b01)? kernel[11] + row3[56]: row3[56] - kernel[11];
			 temp[92] =  (operation == 2'b01)? kernel[12] + row4[53]: row4[53] - kernel[12];
			 temp[93] =  (operation == 2'b01)? kernel[13] + row4[54]: row4[54] - kernel[13];
			 temp[94] =  (operation == 2'b01)? kernel[14] + row4[55]: row4[55] - kernel[14];
			 temp[95] =  (operation == 2'b01)? kernel[15] + row4[56]: row4[56] - kernel[15];
			 temp[96] =  (operation == 2'b01)? kernel[0] + row1[54] : row1[54] - kernel[0];
			 temp[97] =  (operation == 2'b01)? kernel[1] + row1[55] : row1[55] - kernel[1];
			 temp[98] =  (operation == 2'b01)? kernel[2] + row1[56] : row1[56] - kernel[2];
			 temp[99] =  (operation == 2'b01)? kernel[3] + row1[57] : row1[57] - kernel[3];
			 temp[100] =  (operation == 2'b01)? kernel[4] + row2[54] : row2[54] - kernel[4];
			 temp[101] =  (operation == 2'b01)? kernel[5] + row2[55] : row2[55] - kernel[5];
			 temp[102] =  (operation == 2'b01)? kernel[6] + row2[56] : row2[56] - kernel[6];
			 temp[103] =  (operation == 2'b01)? kernel[7] + row2[57] : row2[57] - kernel[7];
			 temp[104] =  (operation == 2'b01)? kernel[8] + row3[54] : row3[54] - kernel[8];
			 temp[105] =  (operation == 2'b01)? kernel[9] + row3[55] : row3[55] - kernel[9];
			 temp[106] =  (operation == 2'b01)? kernel[10] + row3[56] : row3[56] - kernel[10];
			 temp[107] =  (operation == 2'b01)? kernel[11] + row3[57] : row3[57] - kernel[11];
			 temp[108] =  (operation == 2'b01)? kernel[12] + row4[54] : row4[54] - kernel[12];
			 temp[109] =  (operation == 2'b01)? kernel[13] + row4[55] : row4[55] - kernel[13];
			 temp[110] =  (operation == 2'b01)? kernel[14] + row4[56] : row4[56] - kernel[14];
			 temp[111] =  (operation == 2'b01)? kernel[15] + row4[57] : row4[57] - kernel[15];
			 temp[112] =  (operation == 2'b01)? kernel[0] + row1[55]: row1[55] - kernel[0];
			 temp[113] =  (operation == 2'b01)? kernel[1] + row1[56]: row1[56] - kernel[1];
			 temp[114] =  (operation == 2'b01)? kernel[2] + row1[57]: row1[57] - kernel[2];
			 temp[115] =  (operation == 2'b01)? kernel[3] + row1[58]: row1[58] - kernel[3];
			 temp[116] =  (operation == 2'b01)? kernel[4] + row2[55]: row2[55] - kernel[4];
			 temp[117] =  (operation == 2'b01)? kernel[5] + row2[56]: row2[56] - kernel[5];
			 temp[118] =  (operation == 2'b01)? kernel[6] + row2[57]: row2[57] - kernel[6];
			 temp[119] =  (operation == 2'b01)? kernel[7] + row2[58]: row2[58] - kernel[7];
			 temp[120] =  (operation == 2'b01)? kernel[8] + row3[55]: row3[55] - kernel[8];
			 temp[121] =  (operation == 2'b01)? kernel[9] + row3[56]: row3[56] - kernel[9];
			 temp[122] =  (operation == 2'b01)? kernel[10] + row3[57]: row3[57] - kernel[10];
			 temp[123] =  (operation == 2'b01)? kernel[11] + row3[58]: row3[58] - kernel[11];
			 temp[124] =  (operation == 2'b01)? kernel[12] + row4[55]: row4[55] - kernel[12];
			 temp[125] =  (operation == 2'b01)? kernel[13] + row4[56]: row4[56] - kernel[13];
			 temp[126] =  (operation == 2'b01)? kernel[14] + row4[57]: row4[57] - kernel[14];
			 temp[127] =  (operation == 2'b01)? kernel[15] + row4[58]: row4[58] - kernel[15];
			 temp[128] =  (operation == 2'b01)? kernel[0] + row1[56]: row1[56] - kernel[0];
			 temp[129] =  (operation == 2'b01)? kernel[1] + row1[57]: row1[57] - kernel[1];
			 temp[130] =  (operation == 2'b01)? kernel[2] + row1[58]: row1[58] - kernel[2];
			 temp[131] =  (operation == 2'b01)? kernel[3] + row1[59]: row1[59] - kernel[3];
			 temp[132] =  (operation == 2'b01)? kernel[4] + row2[56]: row2[56] - kernel[4];
			 temp[133] =  (operation == 2'b01)? kernel[5] + row2[57]: row2[57] - kernel[5];
			 temp[134] =  (operation == 2'b01)? kernel[6] + row2[58]: row2[58] - kernel[6];
			 temp[135] =  (operation == 2'b01)? kernel[7] + row2[59]: row2[59] - kernel[7];
			 temp[136] =  (operation == 2'b01)? kernel[8] + row3[56]: row3[56] - kernel[8];
			 temp[137] =  (operation == 2'b01)? kernel[9] + row3[57]: row3[57] - kernel[9];
			 temp[138] =  (operation == 2'b01)? kernel[10] + row3[58]: row3[58] - kernel[10];
			 temp[139] =  (operation == 2'b01)? kernel[11] + row3[59]: row3[59] - kernel[11];
			 temp[140] =  (operation == 2'b01)? kernel[12] + row4[56]: row4[56] - kernel[12];
			 temp[141] =  (operation == 2'b01)? kernel[13] + row4[57]: row4[57] - kernel[13];
			 temp[142] =  (operation == 2'b01)? kernel[14] + row4[58]: row4[58] - kernel[14];
			 temp[143] =  (operation == 2'b01)? kernel[15] + row4[59]: row4[59] - kernel[15];
			 temp[144] =  (operation == 2'b01)? kernel[0] + row1[57]: row1[57] - kernel[0];
			 temp[145] =  (operation == 2'b01)? kernel[1] + row1[58]: row1[58] - kernel[1];
			 temp[146] =  (operation == 2'b01)? kernel[2] + row1[59]: row1[59] - kernel[2];
			 temp[147] =  (operation == 2'b01)? kernel[3] + row1[60]: row1[60] - kernel[3];
			 temp[148] =  (operation == 2'b01)? kernel[4] + row2[57]: row2[57] - kernel[4];
			 temp[149] =  (operation == 2'b01)? kernel[5] + row2[58]: row2[58] - kernel[5];
			 temp[150] =  (operation == 2'b01)? kernel[6] + row2[59]: row2[59] - kernel[6];
			 temp[151] =  (operation == 2'b01)? kernel[7] + row2[60]: row2[60] - kernel[7];
			 temp[152] =  (operation == 2'b01)? kernel[8] + row3[57]: row3[57] - kernel[8];
			 temp[153] =  (operation == 2'b01)? kernel[9] + row3[58]: row3[58] - kernel[9];
			 temp[154] =  (operation == 2'b01)? kernel[10] + row3[59]: row3[59] - kernel[10];
			 temp[155] =  (operation == 2'b01)? kernel[11] + row3[60]: row3[60] - kernel[11];
			 temp[156] =  (operation == 2'b01)? kernel[12] + row4[57]: row4[57] - kernel[12];
			 temp[157] =  (operation == 2'b01)? kernel[13] + row4[58]: row4[58] - kernel[13];
			 temp[158] =  (operation == 2'b01)? kernel[14] + row4[59]: row4[59] - kernel[14];
			 temp[159] =  (operation == 2'b01)? kernel[15] + row4[60]: row4[60] - kernel[15];
			 temp[160] =  (operation == 2'b01)? kernel[0] + row1[58]: row1[58] - kernel[0];
			 temp[161] =  (operation == 2'b01)? kernel[1] + row1[59]: row1[59] - kernel[1];
			 temp[162] =  (operation == 2'b01)? kernel[2] + row1[60]: row1[60] - kernel[2];
			 temp[163] =  (operation == 2'b01)? kernel[3] + row1[61]: row1[61] - kernel[3];
			 temp[164] =  (operation == 2'b01)? kernel[4] + row2[58]: row2[58] - kernel[4];
			 temp[165] =  (operation == 2'b01)? kernel[5] + row2[59]: row2[59] - kernel[5];
			 temp[166] =  (operation == 2'b01)? kernel[6] + row2[60]: row2[60] - kernel[6];
			 temp[167] =  (operation == 2'b01)? kernel[7] + row2[61]: row2[61] - kernel[7];
			 temp[168] =  (operation == 2'b01)? kernel[8] + row3[58]: row3[58] - kernel[8];
			 temp[169] =  (operation == 2'b01)? kernel[9] + row3[59]: row3[59] - kernel[9];
			 temp[170] =  (operation == 2'b01)? kernel[10] + row3[60]: row3[60] - kernel[10];
			 temp[171] =  (operation == 2'b01)? kernel[11] + row3[61]: row3[61] - kernel[11];
			 temp[172] =  (operation == 2'b01)? kernel[12] + row4[58]: row4[58] - kernel[12];
			 temp[173] =  (operation == 2'b01)? kernel[13] + row4[59]: row4[59] - kernel[13];
			 temp[174] =  (operation == 2'b01)? kernel[14] + row4[60]: row4[60] - kernel[14];
			 temp[175] =  (operation == 2'b01)? kernel[15] + row4[61]: row4[61] - kernel[15];
			 temp[176] =  (operation == 2'b01)? kernel[0] + row1[59]: row1[59] - kernel[0];
			 temp[177] =  (operation == 2'b01)? kernel[1] + row1[60]: row1[60] - kernel[1];
			 temp[178] =  (operation == 2'b01)? kernel[2] + row1[61]: row1[61] - kernel[2];
			 temp[179] =  (operation == 2'b01)? kernel[3] + row1[62]: row1[62] - kernel[3];
			 temp[180] =  (operation == 2'b01)? kernel[4] + row2[59]: row2[59] - kernel[4];
			 temp[181] =  (operation == 2'b01)? kernel[5] + row2[60]: row2[60] - kernel[5];
			 temp[182] =  (operation == 2'b01)? kernel[6] + row2[61]: row2[61] - kernel[6];
			 temp[183] =  (operation == 2'b01)? kernel[7] + row2[62]: row2[62] - kernel[7];
			 temp[184] =  (operation == 2'b01)? kernel[8] + row3[59]: row3[59] - kernel[8];
			 temp[185] =  (operation == 2'b01)? kernel[9] + row3[60]: row3[60] - kernel[9];
			 temp[186] =  (operation == 2'b01)? kernel[10] + row3[61]: row3[61] - kernel[10];
			 temp[187] =  (operation == 2'b01)? kernel[11] + row3[62]: row3[62] - kernel[11];
			 temp[188] =  (operation == 2'b01)? kernel[12] + row4[59]: row4[59] - kernel[12];
			 temp[189] =  (operation == 2'b01)? kernel[13] + row4[60]: row4[60] - kernel[13];
			 temp[190] =  (operation == 2'b01)? kernel[14] + row4[61]: row4[61] - kernel[14];
			 temp[191] =  (operation == 2'b01)? kernel[15] + row4[62]: row4[62] - kernel[15];
			 temp[192] =  (operation == 2'b01)? kernel[0] + row1[60]: row1[60] - kernel[0];
			 temp[193] =  (operation == 2'b01)? kernel[1] + row1[61]: row1[61] - kernel[1];
			 temp[194] =  (operation == 2'b01)? kernel[2] + row1[62]: row1[62] - kernel[2];
			 temp[195] =  (operation == 2'b01)? kernel[3] + row1[63]: row1[63] - kernel[3];
			 temp[196] =  (operation == 2'b01)? kernel[4] + row2[60]: row2[60] - kernel[4];
			 temp[197] =  (operation == 2'b01)? kernel[5] + row2[61]: row2[61] - kernel[5];
			 temp[198] =  (operation == 2'b01)? kernel[6] + row2[62]: row2[62] - kernel[6];
			 temp[199] =  (operation == 2'b01)? kernel[7] + row2[63]: row2[63] - kernel[7];
			 temp[200] =  (operation == 2'b01)? kernel[8] + row3[60]: row3[60] - kernel[8];
			 temp[201] =  (operation == 2'b01)? kernel[9] + row3[61]: row3[61] - kernel[9];
			 temp[202] =  (operation == 2'b01)? kernel[10] + row3[62]: row3[62] - kernel[10];
			 temp[203] =  (operation == 2'b01)? kernel[11] + row3[63]: row3[63] - kernel[11];
			 temp[204] =  (operation == 2'b01)? kernel[12] + row4[60]: row4[60] - kernel[12];
			 temp[205] =  (operation == 2'b01)? kernel[13] + row4[61]: row4[61] - kernel[13];
			 temp[206] =  (operation == 2'b01)? kernel[14] + row4[62]: row4[62] - kernel[14];
			 temp[207] =  (operation == 2'b01)? kernel[15] + row4[63]: row4[63] - kernel[15];
			 temp[208] =  (operation == 2'b01)? kernel[0] + row1[61]: row1[61] - kernel[0];
			 temp[209] =  (operation == 2'b01)? kernel[1] + row1[62]: row1[62] - kernel[1];
			 temp[210] =  (operation == 2'b01)? kernel[2] + row1[63]: row1[63] - kernel[2];
			 temp[211] =  (operation == 2'b01)? kernel[3] :                   0;
			 temp[212] =  (operation == 2'b01)? kernel[4] + row2[61]: row2[61] - kernel[4];
			 temp[213] =  (operation == 2'b01)? kernel[5] + row2[62]: row2[62] - kernel[5];
			 temp[214] =  (operation == 2'b01)? kernel[6] + row2[63]: row2[63] - kernel[6];
			 temp[215] =  (operation == 2'b01)? kernel[7] :                   0;
			 temp[216] =  (operation == 2'b01)? kernel[8] + row3[61]: row3[61] - kernel[8];
			 temp[217] =  (operation == 2'b01)? kernel[9] + row3[62]: row3[62] - kernel[9];
			 temp[218] =  (operation == 2'b01)? kernel[10] + row3[63]: row3[63] - kernel[10];
			 temp[219] =  (operation == 2'b01)? kernel[11] :                   0;
			 temp[220] =  (operation == 2'b01)? kernel[12] + row4[61]: row4[61] - kernel[12];
			 temp[221] =  (operation == 2'b01)? kernel[13] + row4[62]: row4[62] - kernel[13];
			 temp[222] =  (operation == 2'b01)? kernel[14] + row4[63]: row4[63] - kernel[14];
			 temp[223] =  (operation == 2'b01)? kernel[15] :                   0;
			 temp[224] =  (operation == 2'b01)? kernel[0] + row1[62]: row1[62] - kernel[0];
			 temp[225] =  (operation == 2'b01)? kernel[1] + row1[63]: row1[63] - kernel[1];
			 temp[226] =  (operation == 2'b01)? kernel[2] :                   0;
			 temp[227] =  (operation == 2'b01)? kernel[3] :                   0;
			 temp[228] =  (operation == 2'b01)? kernel[4] + row2[62]: row2[62] - kernel[4];
			 temp[229] =  (operation == 2'b01)? kernel[5] + row2[63]: row2[63] - kernel[5];
			 temp[230] =  (operation == 2'b01)? kernel[6] :                   0;
			 temp[231] =  (operation == 2'b01)? kernel[7] :                   0;
			 temp[232] =  (operation == 2'b01)? kernel[8] + row3[62]: row3[62] - kernel[8];
			 temp[233] =  (operation == 2'b01)? kernel[9] + row3[63]: row3[63] - kernel[9];
			 temp[234] =  (operation == 2'b01)? kernel[10] :                   0;
			 temp[235] =  (operation == 2'b01)? kernel[11] :                   0;
			 temp[236] =  (operation == 2'b01)? kernel[12] + row4[62]: row4[62] - kernel[12];
			 temp[237] =  (operation == 2'b01)? kernel[13] + row4[63]: row4[63] - kernel[13];
			 temp[238] =  (operation == 2'b01)? kernel[14] :                   0;
			 temp[239] =  (operation == 2'b01)? kernel[15] :                   0;
			 temp[240] =  (operation == 2'b01)? kernel[0] + row1[63]: row1[63] - kernel[0];
			 temp[241] =  (operation == 2'b01)? kernel[1] :                   0;
			 temp[242] =  (operation == 2'b01)? kernel[2] :                   0;
			 temp[243] =  (operation == 2'b01)? kernel[3] :                   0;
			 temp[244] =  (operation == 2'b01)? kernel[4] + row2[63]: row2[63] - kernel[4];
			 temp[245] =  (operation == 2'b01)? kernel[5] :                   0;
			 temp[246] =  (operation == 2'b01)? kernel[6] :                   0;
			 temp[247] =  (operation == 2'b01)? kernel[7] :                   0;
			 temp[248] =  (operation == 2'b01)? kernel[8] + row3[63]: row3[63] - kernel[8];
			 temp[249] =  (operation == 2'b01)? kernel[9] :                   0;
			 temp[250] =  (operation == 2'b01)? kernel[10] :                   0;
			 temp[251] =  (operation == 2'b01)? kernel[11] :                   0;
			 temp[252] =  (operation == 2'b01)? kernel[12] + row4[63]: row4[63] - kernel[12];
			 temp[253] =  (operation == 2'b01)? kernel[13] :                   0;
			 temp[254] =  (operation == 2'b01)? kernel[14] :                   0;
			 temp[255] =  (operation == 2'b01)? kernel[15] :                   0;
		end
	endcase
end
always@(*) begin
	if(c_state == HIST_C) temp_quotient = quotient;
	else temp_quotient = 0;
end
genvar a, b;
generate
	for(a=0;a<16;a=a+1) begin
		for(b=0;b<256;b=b+1) begin
			always@(*) begin
				if(rdata_m_inf[a*8+7:a*8] <= b) record[a][b] = 1;
				else record[a][b] = 0;
			end
		end
	end
endgenerate
genvar c;
generate
	for(c=0;c<255;c=c+1) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) cdf_table[c] <= 0;
			else begin
				if((c_state == READ_PIC_DATA)||(c_state == DILA_A)||(c_state == EROS)) begin
					if(operation == 2'b10 && rvalid_m_inf) begin
						cdf_table[c] <= cdf_table[c]+record[0][c]+record[1][c]+record[2][c]+record[3][c]
									    +record[4][c]+record[5][c]+record[6][c]+record[7][c]+record[8][c]
										+record[9][c]+record[10][c]+record[11][c]+record[12][c]+record[13][c]
										+record[14][c]+record[15][c];
					end
					else if(operation != 2'b10 && row_counter>3) begin
						if(operation == 2'b01) begin
							cdf_table[c] <= (temp[c]>20'd255)? 20'd255 : temp[c]; 
						end
						else if(operation == 2'b00) begin
							cdf_table[c] <= (temp[c][12]==1)? 0 : temp[c];
						end
						else cdf_table[c] <= cdf_table[c];
					end
					else cdf_table[c] <= cdf_table[c];
				end
				else if((c_state == HIST_C)) begin
					if(div_counter == 0) cdf_table[c] <= ((cdf_table[c]-min)<<8)-(cdf_table[c]-min);
					else  begin
						cdf_table[c] <= cdf_table[c+1];
					end
				end
				else if(c_state == IDLE) cdf_table[c] <= 0;
			end		
		end	
	end
endgenerate
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) cdf_table[255] <= 0;
	else begin
		if((c_state == READ_PIC_DATA)||(c_state == DILA_A)||(c_state == DILA_B)||(c_state == EROS)) begin
			if(operation == 2'b10 && rvalid_m_inf) begin
				cdf_table[255] <= cdf_table[255]+record[0][255]+record[1][255]+record[2][255]+record[3][255]
								+record[4][255]+record[5][255]+record[6][255]+record[7][255]+record[8][255]
								+record[9][255]+record[10][255]+record[11][255]+record[12][255]+record[13][255]
								+record[14][255]+record[15][255];
			end
			else if(operation != 2'b10 && row_counter>3) begin
				if(operation == 2'b01) begin
					cdf_table[255] <= (temp[255]>20'd255)? 20'd255 : temp[255]; 
				end
				else if(operation == 2'b00) begin
					cdf_table[255] <= (temp[255][12]==1)? 0 : temp[255];
				end
				else cdf_table[255] <= cdf_table[255];
			end
			else cdf_table[255] <= cdf_table[255];
		end
		else if((c_state == HIST_C)) begin
			if(div_counter == 0) cdf_table[255] <= ((cdf_table[255]-min)<<8)-(cdf_table[255]-min);
			else  begin
				if(div_counter >1) cdf_table[255]<= temp_quotient;
				else cdf_table[255] <= 0;
			end
		end
		else if(c_state == IDLE) cdf_table[255] <= 0;
	end		
end	

//======================================
//      	DIV Block
//======================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) hist_div <= 0;
	else begin
		if(c_state == HIST_C) begin
			if(div_counter>0) hist_div <= cdf_table[0];
			else hist_div <= 0;
		end
		else hist_div <= 0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) hist_div_b <= 1;
	else begin
		if(c_state == HIST_C) begin
			hist_div_b <= 13'd4096-min;
		end
		else hist_div_b <= hist_div_b;
	end
end
DW_div #(20, 12, 0, 1) DIV0 (.a(hist_div), .b(hist_div_b), .quotient(quotient), .remainder(remainder), .divide_by_0(pin));

//======================================
//      	HIST MIN Block
//======================================
DW_minmax #(8, 16) hist1 (.a(write_data), .tc(1'b0), .min_max(1'b0), .value(temp_min), .index(index_min));
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) min <= 0;
	else begin
		if(c_state == IDLE) min <= 4095;
		else if((c_state == READ_PIC_DATA)) begin
			if(pic_counter > 0 ) begin
				if(min>temp_min) min <= temp_min;
				else min <= min;
			end
			else min <= min;
		end
		else if(c_state == HIST_A) begin
			if(min>temp_min) min <= temp_min;
			else min <= min;
		end
		else if(c_state == HIST_B) begin
			min <= cdf_table[min];
		end
		else min <= min;
	end
end



//======================================
//      	OUTPUT Block
//======================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) busy <= 0;
	else begin
		busy <= (c_state != IDLE)?1:0;
	end
end
endmodule