																
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIITD
// Engineer:Neelam Singh
// Design Name: OFDM
// Project Name: Reconfigurable PHY
// Target Devices:ZYNQ-7 ZC706 Evaluation Board (xc7z045ffg900-2) 
// Module Name:    Pilots_Insert 
// Project Name: 

// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Pilots_Insert(
input             CLK_I, RST_I,
input [31:0]     DAT_I,
input             CYC_I, WE_I, STB_I, 
output            ACK_O,
output [5:0]    dataCount,

output [31:0]    DAT_O,
output reg        CYC_O, STB_O,
output            WE_O,
input                ACK_I    
);
parameter P_P = 16'h7fff;    // +1 in Q1.15
parameter P_N = 16'h8001;    // -1 in Q1.15 
//reg [0:127] Pil=128'b01000100010001001011101110110100101110111011101101000100101101001011101101000100101101000100101101000100010001000100010010110100;   // signed bit of real part of pilots,
reg 		 Pil 	 [0:127];  
initial $readmemh("E:/neelam/Text_File/Pilot_seq.txt", Pil);

//D:\Imp_PR\Integration\OFDM_DPR\QAM_DPR  
reg [31:0]	idat;
reg [31:0]  odat;
reg			ival;	
wire 			out_halt, ena;
wire			datout_ack;


reg [5:0]	dat_cnt;
reg [6:0]	pilot_cnt;
reg			pil_insert_ena;
reg			nul_insert_ena;		//inserting null symbol for guarding.
wire[15:0]  pil_Re;


assign 	out_halt   = STB_O & (~ACK_I);
assign 	datout_ack = STB_O & ACK_I;
assign 	ena 		= CYC_I & STB_I & WE_I;
assign 	ACK_O 	= ena & (~out_halt) & (~pil_insert_ena) & (~nul_insert_ena);

always @(posedge CLK_I) begin
	if(RST_I) 			idat<= 2'b00;
	else if(ACK_O) 	idat <= DAT_I;
end
always @(posedge CLK_I) begin
	if(RST_I) 		ival <= 1'b0;
	else if(ena)	ival <= 1'b1;
	else				ival <= 1'b0;
end

always @(posedge CLK_I)
begin
	if(RST_I)	STB_O <= 1'b0;
	else if(ival|pil_insert_ena|nul_insert_ena)	STB_O <= 1'b1;
	else if(~ival) 										STB_O <= 1'b0;
end

always @(posedge CLK_I)
begin
	if(RST_I)													odat <= 32'b0;
	else if(ival & (~out_halt) & (~nul_insert_ena))	odat <= (pil_insert_ena)? {16'd0, pil_Re} : idat;	
end

reg icyc;
always @(posedge CLK_I)
begin
	if(RST_I)		icyc <= 1'b0;		
	else				icyc <= CYC_I;	
end
always @(posedge CLK_I)
begin
	if(RST_I)		CYC_O	<= icyc;			
	else 				CYC_O	<= icyc;
end
assign DAT_O = (nul_insert_ena)? 32'd0: odat;
assign WE_O  = STB_O;	 

always@(posedge CLK_I)
begin
	if(RST_I)										dat_cnt	<= 6'd0;		
	else if(CYC_I & (~icyc))					dat_cnt	<= 6'd0;
	else if(datout_ack)						   dat_cnt	<= dat_cnt + 1'b1;
end

always@(posedge CLK_I)
begin
	if(RST_I)										pilot_cnt	<= 7'd0;			
	else if(CYC_I & (~icyc))					pilot_cnt	<= 7'd0;
	else if(pil_insert_ena & (~out_halt))	pilot_cnt	<= pilot_cnt + 1'b1;
end

assign pil_Re = (Pil[pilot_cnt])? P_N : P_P;

always@(dat_cnt) begin
	pil_insert_ena  = 1'b0;
//	nul_insert_ena  = 1'b0;
	case (dat_cnt)
		//8'd0:								nul_insert_ena  = 1'b1;
		6'd6, 6'd20, 6'd42, 6'd56: 	pil_insert_ena  = 1'b1;
		
		default: begin
					pil_insert_ena  = 1'b0;
					//nul_insert_ena  = 1'b0;
					end
	endcase
end 

always@(posedge CLK_I)
begin
	if(RST_I)													nul_insert_ena  = 1'b0;		
	else if(CYC_I & (~icyc))								nul_insert_ena  = 1'b0;	
	else if(icyc & (~CYC_O))								nul_insert_ena  = 1'b1;
	else if(datout_ack & (dat_cnt == 6'd0))			nul_insert_ena  = 1'b0;
	else if(datout_ack & (dat_cnt == 6'd26))			nul_insert_ena  = 1'b1;	
	else if(datout_ack & (dat_cnt == 6'd37))			nul_insert_ena  = 1'b0;	
	else if(icyc & datout_ack & (dat_cnt == 8'd63)) nul_insert_ena  = 1'b1;	
end


endmodule 


