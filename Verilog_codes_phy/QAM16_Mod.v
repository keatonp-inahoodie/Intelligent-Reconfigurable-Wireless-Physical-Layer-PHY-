// Company: IIITD
// Engineer:Neelam Singh
// Design Name: OFDM
//Module Name: Modulation
// Project Name: Reconfigurable PHY
// Target Devices:ZYNQ-7 ZC706 Evaluation Board (xc7z045ffg900-2)
`define Qn3 16'h8692
`define Qn1 16'hD786
`define Qp1 16'h287A
`define Qp3 16'h796E

module QAM16_Mod(
	input 			CLK_I,clk4, RST_I,
	input [3:0] 	DAT_I,
	input [1:0] DAT_IQ,
	input 			CYC_I, WE_I, STB_I, 
	output			ACK_O,
	input checkflag,
	output reg [31:0]	DAT_O,
	input QAM,
	input QPSK,
	output reg			CYC_O, STB_O,
	output				WE_O,
	input					ACK_I	
    );//9315009155
reg [3:0]	idat;
reg			ival;	
wire 			out_halt, ena;

reg [15:0] 	datout_Re, datout_Im;

assign 	out_halt = STB_O & (~ACK_I);
assign 	ena 		= CYC_I & STB_I & WE_I;
assign 	ACK_O 	= ena &(~out_halt);


	
always @(posedge CLK_I) begin
	if(RST_I) 			idat<= 4'b0000;
	else if(ACK_O) 	idat <= DAT_I[3:0];
end

always @(posedge CLK_I) begin
	if(RST_I) 			ival <= 1'b0;
	else if(ena)		ival <= 1'b1;
	else					ival <= 1'b0;
end

always @(posedge CLK_I)
begin
	if(RST_I)	begin
		STB_O <= 1'b0;
		DAT_O <= 32'b0;
		end
	else if(ival & (~out_halt)) begin	
		DAT_O <= {datout_Im, datout_Re};	
		STB_O <= 1'b1;
		end	
	else if(~ival) begin	
		STB_O <= 1'b0;
		end
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

assign WE_O = STB_O;

always @(*) begin
	case (idat[3:2])
        2'b00  : datout_Im = `Qn3; //0
      	2'b01  : datout_Im = `Qp1; //1
		2'b10  : datout_Im = `Qn1; //2
		2'b11  : datout_Im = `Qp3; //3
		default: datout_Im = 16'd0;
	endcase
end

always @(*) begin
	case (idat[1:0])
      2'b00  : datout_Re = `Qn3;
      2'b01  : datout_Re = `Qp1;
	  2'b10  : datout_Re = `Qn1;
	  2'b11  : datout_Re = `Qp3;	
		default: datout_Re = 16'd0;
	endcase
end

endmodule
