`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:13:41 01/26/2017 
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
`timescale 1ns / 1ps 

module main(
	input wire clk,
	input wire clear,
	output reg [3:0] count
);

wire clk_ibufg;
wire clk_int;
IBUFG clk_ibufg_inst (.I(clk), .O(clk_ibufg));
BUFG clk_bufg_inst (.I(clk_ibufg), .O(clk_int));


reg [26:0] delay = 0;

//Delay help reduce clock speed from 100 MHz to 1.5 Hz
always @(posedge clk_int)
begin
	delay <= delay +1;
	if( delay == 27'b111111111111111111111111111 )
	begin
		count[0]<=count[0]^1&~clear;
		count[1]<=count[1]^count[0]&~clear;
		count[2]<=count[2]^(count[1]&count[0])&~clear;
		count[3]<=count[3]^(count[2]&count[1]&count[0])&~clear;
		delay <= 0;
	end
end

endmodule
