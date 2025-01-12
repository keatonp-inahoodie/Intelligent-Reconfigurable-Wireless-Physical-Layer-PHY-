`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIITD
// Engineer:Neelam Singh
// Design Name: OFDM
// Project Name: Reconfigurable PHY
// Target Devices:ZYNQ-7 ZC706 Evaluation Board (xc7z045ffg900-2)
// Module Name:    Multiplierless_Correlator 

//
//////////////////////////////////////////////////////////////////////////////////
module Signed_Correlator(
	input 	clk,rst,
	input 	ena,
	input 	[1:0] CR_in,	//[1] :signed bit of imaginary part, [0] :signed bit of real part,
	output   [6:0] CR_out_Re, CR_out_Im
   );
 
 
reg [1:0]Synch[63:0]; //[1] :signed bit of imaginary part, [0] :signed bit of real part,

//$readmemh("D:/Imp_PR/Pr_Reading_Text/Pr_Reading_Text/RTL_OFDM_TX_bit_symbols.txt", datin);
initial 
//begin
$readmemh("E:/neelam/Text_File/Synch_known_coeff_802_11.txt", Synch);
//end
//D:\Imp_PR\Integration\Integration_channel_Mult
// 


wire 	[1:0] iCR_in = CR_in;
wire 			iena   = ena;

//=============================================

wire [1:0] tap_out_Re 	 [63:0];		
wire [1:0] tap_out_Im 	 [63:0];		
genvar ML_cnt;
generate
   for (ML_cnt=0; ML_cnt < 64; ML_cnt = ML_cnt + 1) 
   begin: ML_assign
			Signed_Mult_tap Signed_Mult_tap_ins(
				.rxin(iCR_in), 	//[1:0]
				.preamble(Synch[ML_cnt][1:0]), //[1:0]
				.mult_out_Re(tap_out_Re[ML_cnt]), //[1:0]
				.mult_out_Im(tap_out_Im[ML_cnt])	//[1:0]
				);				
   end
endgenerate	

//=============================================
wire [6:0] 	add_out_Re 	 [63:0];		//Add 
wire [6:0] 	add_out_Im 	 [63:0];		//Add 

assign 		add_out_Re[0] = {{5{tap_out_Re[0][1]}}, tap_out_Re[0]};
assign 		add_out_Im[0] = {{5{tap_out_Im[0][1]}}, tap_out_Im[0]};

wire [6:0] reg_out_Re [62:0];			//Add Register 
wire [6:0] reg_out_Im [62:0];			//Add Register 

genvar cnt;
generate
   for (cnt=0; cnt < 63; cnt = cnt + 1) 
   begin: AddCmpReg_ins				
			Delay_reg #(.WIDTH(7)) CR_Re_D(
					.clk(clk), 							.rst(rst),						.ena(iena),
					.dat_in(add_out_Re[cnt][6:0]),    		
					.dat_out(reg_out_Re[cnt][6:0])
					);		
			
			Delay_reg #(.WIDTH(7)) CR_Im_D(
					.clk(clk), 							.rst(rst),						.ena(iena),
					.dat_in(add_out_Im[cnt][6:0]),    		
					.dat_out(reg_out_Im[cnt][6:0])
					);					
			
			assign add_out_Re[cnt+1] = reg_out_Re[cnt] + {{5{tap_out_Re[cnt+1][1]}}, tap_out_Re[cnt+1]};
			assign add_out_Im[cnt+1] = reg_out_Im[cnt] + {{5{tap_out_Im[cnt+1][1]}}, tap_out_Im[cnt+1]};
   end
endgenerate	


assign CR_out_Re = add_out_Re[63][6:0];		
assign CR_out_Im = add_out_Im[63][6:0];	

endmodule
