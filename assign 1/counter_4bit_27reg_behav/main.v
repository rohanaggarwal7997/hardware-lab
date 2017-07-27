`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:01:11 01/26/2017 
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

module main( input clk, output reg [3:0] count,input clr
	 );
	
	/*//This is the Input Global Clock buffer
	wire clk_ibufg;
	IBUFG clk_ibufg_inst (.I(clk), .O(clk_ibufg));
	
	clkdivider inst_1(
	.clk(clk_ibufg),
	.reducedclk(rclk)
	);
	
	//This is the Global clock buffer for the slower clock generated
	wire clk_int;
	BUFG clk_bufg_inst (.I(rclk), .O(clk_int));*/
	

	always @(posedge (clk))
	begin
		if(clr==0) //Do when clr is 0
			begin
			if(count == 15) //When count becomes 15 then make it zero and continue
				count <= 0;
			else
				count <= count + 1; //When count < 15 then increment it every clock cycle
			end
		else 
			count <= 0; //When clr is 1 simply output low on all leds
	end
endmodule

//Reduced Speed of the clock by 2^26-1 times i.e. 100000000/67108863 Hz is the new clock speed
//This is roughly equal to 1.5 Hz which is desirable
module clkdivider(input clk, output reducedclk);
	 
	//When same clock is being used in multiple modules the different clocks might have a time delay between them
	//So to get rid of the lags a clock buffer is used
	
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
