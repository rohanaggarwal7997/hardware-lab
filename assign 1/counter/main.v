`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:15:05 01/17/2017 
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
module main( input clk, output [3:0] count
	 );
	 
	 reg [3:0] count;
	 
	 always @(posedge (clk))
	 begin
	 if(count == 15)
		count <= 0;
	 else
		count <= count + 1;
	 end

endmodule
