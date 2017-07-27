`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:19:19 01/26/2017 
// Design Name: 
// Module Name:    main 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

/*module d_flip_flop_edge_triggered(D,C, Q, Qn);
   output Q;
   output Qn;
   input  C;
   input  D;

   wire   Cn;   // Control input to the D latch.
   wire   Cnn;  // Control input to the SR latch.
   wire   DQ;   // Output from the D latch, input to the gated SR latch.
   wire   DQn;  // Output from the D latch, input to the gated SR latch.
   
   not(Cn, C);
   not(Cnn, Cn);   
   d_latch dl(DQ, DQn, Cn, D);
   sr_latch_gated sr(Q, Qn, Cnn, DQ, DQn);   
endmodule // d_flip_flop_edge_triggered

module d_latch(Q, Qn, G, D);
   output Q;
   output Qn;
   input  G;   
   input  D;

   wire   Dn; 
   wire   D1;
   wire   Dn1;

   not(Dn, D);   
   and(D1, G, D);
   and(Dn1, G, Dn);   
   nor(Qn, D1, Q);
   nor(Q, Dn1, Qn);
endmodule // d_latch

module sr_latch_gated(Q, Qn, G, S, R);
   output Q;
   output Qn;
   input  G;   
   input  S;
   input  R;

   wire   S1;
   wire   R1;
   
   and(S1, G, S);
   and(R1, G, R);   
   nor(Qn, S1, Q);
   nor(Q, R1, Qn);
endmodule // sr_latch_gated*/

module d_flip_flop_edge_triggered(D,clk,Q,Qn);
	input clk,D;
	output reg Q;
	output reg Qn;
	always @(posedge clk)
	begin
		Q<=D;
		Qn<=~D;
	end

endmodule

module main(
	input clk, en,
	output q0,q1,q2,q3
    );
	
	//When same clock is being used in multiple modules the different clocks might have a time delay between them
	//So to get rid of the lags a clock buffer is used
	
	//This is the Input Global Clock buffer
	wire clk_ibufg;
	IBUFG clk_ibufg_inst (.I(clk), .O(clk_ibufg));
	
	wire myclk; 
	clkdivider clkgen(
	.clk(clk_ibufg),
	.reducedclk(rclk)
	);
	
	//This is the Global clock buffer for the slower clock generated
	wire clk_int;
	BUFG clk_bufg_inst (.I(rclk), .O(clk_int));
	
	//The standard logic for D Flip Flop based Synchronous Up counter with enable
	d_flip_flop_edge_triggered inst1(en^q0,clk_int,q0,q0bar);
	d_flip_flop_edge_triggered inst2((en&q0)^q1,clk_int,q1,q1bar);
	d_flip_flop_edge_triggered inst3((en&q0&q1)^q2,clk_int,q2,q2bar);
	d_flip_flop_edge_triggered inst4((en&q0&q1&q2)^q3,clk_int,q3,q2bar);
	

endmodule

//Reduced Speed of the clock by 2^26-1 times i.e. 100000000/67108863 Hz is the new clock speed
//This is roughly equal to 1.5 Hz which is desirable
module clkdivider(input clk, output reducedclk);
	
	reg [25:0] re;
	reg reducedclk = 1'b0;
	
	always @(posedge clk)
	begin
		re <= re+1;
		if(re == 26'b11111111111111111111111111)
			begin
			re <= 0;
			reducedclk <= ~reducedclk;
			end
	end

endmodule
