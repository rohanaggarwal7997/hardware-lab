`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:13:52 02/12/2017 
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

module sync_reset #(
    parameter N=2 // depth of synchronizer
)(
    input wire clk,
    input wire rst,
    output wire sync_reset_out
);

reg [N-1:0] sync_reg = {N{1'b1}};

assign sync_reset_out = sync_reg[N-1];

always @(posedge clk or posedge rst) begin
    if (rst)
        sync_reg <= {N{1'b1}};
    else
        sync_reg <= {sync_reg[N-2:0], 1'b0};
end

endmodule

module debounce_switch  #(
    parameter WIDTH=1, // width of the input and output signals
    parameter N=3, // length of shift register
    parameter RATE=125000 // clock division factor
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] out
);

reg [23:0] cnt_reg = 24'd0;

reg [N-1:0] debounce_reg[WIDTH-1:0];

reg [WIDTH-1:0] state;

/*
 * The synchronized output is the state register
 */
assign out = state;

integer k;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt_reg <= 0;
        state <= 0;
        
        for (k = 0; k < WIDTH; k = k + 1) begin
            debounce_reg[k] <= 0;
        end
    end else begin
        if (cnt_reg < RATE) begin
            cnt_reg <= cnt_reg + 24'd1;
        end else begin
            cnt_reg <= 24'd0;
        end
        
        if (cnt_reg == 24'd0) begin
            for (k = 0; k < WIDTH; k = k + 1) begin
                debounce_reg[k] <= {debounce_reg[k][N-2:0], in[k]};
            end
        end
        
        for (k = 0; k < WIDTH; k = k + 1) begin
            if (|debounce_reg[k] == 0) begin
                state[k] <= 0;
            end else if (&debounce_reg[k] == 1) begin
                state[k] <= 1;
            end else begin
                state[k] <= state[k];
            end
        end
    end
end

endmodule

module main (
    /*
     * Clock: 100MHz
     * Reset: Push button, active low
     */
    input  wire       clk,
    input  wire       reset_n,
    /*
     * GPIO
     */
    input  wire       btnu,
    input  wire       btnl,
    input  wire       btnd,
    input  wire       btnr,
    input  wire       btnc,
    input  wire [7:0] sw,
    output wire [7:0] led
    
);

// Clock and reset

wire clk_ibufg;
wire clk_bufg;
wire clk_dcm_out;

// Internal 125 MHz clock
wire clk_int;
wire rst_int;

wire dcm_rst;
wire [7:0] dcm_status;
wire dcm_locked;
wire dcm_clkfx_stopped = dcm_status[2];

assign dcm_rst = ~reset_n | (dcm_clkfx_stopped & ~dcm_locked);

IBUFG
clk_ibufg_inst(
    .I(clk),
    .O(clk_ibufg)
);

DCM_SP #(
    .CLKIN_PERIOD(10),
    .CLK_FEEDBACK("NONE"),
    .CLKDV_DIVIDE(2.0),
    .CLKFX_MULTIPLY(5.0),
    .CLKFX_DIVIDE(4.0),
    .PHASE_SHIFT(0),
    .CLKOUT_PHASE_SHIFT("NONE"),
    .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
    .STARTUP_WAIT("FALSE"),
    .CLKIN_DIVIDE_BY_2("FALSE")
)
clk_dcm_inst (
    .CLKIN(clk_ibufg),
    .CLKFB(1'b0),
    .RST(dcm_rst),
    .PSEN(1'b0),
    .PSINCDEC(1'b0),
    .PSCLK(1'b0),
    .CLK0(),
    .CLK90(),
    .CLK180(),
    .CLK270(),
    .CLK2X(),
    .CLK2X180(),
    .CLKDV(),
    .CLKFX(clk_dcm_out),
    .CLKFX180(),
    .STATUS(dcm_status),
    .LOCKED(dcm_locked),
    .PSDONE()
);

BUFG
clk_bufg_inst (
    .I(clk_dcm_out),
    .O(clk_int)
);

sync_reset #(
    .N(4)
)
sync_reset_inst (
    .clk(clk_int),
    .rst(~dcm_locked),
    .sync_reset_out(rst_int)
);

// GPIO
wire btnu_int;
wire btnl_int;
wire btnd_int;
wire btnr_int;
wire btnc_int;
wire [7:0] sw_int;

debounce_switch #(
    .WIDTH(13),
    .N(4),
    .RATE(125000)
)
debounce_switch_inst (
    .clk(clk_int),
    .rst(rst_int),
    .in({btnu,
        btnl,
        btnd,
        btnr,
        btnc,
        sw}),
    .out({btnu_int,
        btnl_int,
        btnd_int,
        btnr_int,
        btnc_int,
        sw_int})
);


action
starting (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    clk_int,
    rst_int,
    /*
     * GPIO
     */
    btnu_int,
    btnl_int,
    btnd_int,
    btnr_int,
    btnc_int,
    sw_int,
    led
    
);

endmodule





module action (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input wire clk,
    input wire rst,
    /*
     * GPIO
     */
    input wire btnu,
    input wire btnl,
    input wire btnd,
    input wire btnr,
    input wire btnc,
    input wire [7:0] sw,
    output reg [7:0] led
    
);

reg [30:0] N = 31'b0000000000000000000000000000000;
reg [30:0] storeN = 31'b0000000000000000000000000000000;
reg [30:0] A[0:12];

reg [30:0] SUM;
reg [30:0] AVG;
reg [30:0] SUMSQ;
reg [30:0] STD;
reg [30:0] temp = 31'b0000000000000000000000000000000;

reg [30:0] i =  31'b0000000000000000000000000000001;
reg [30:0] op = 31'b0000000000000000000000000000001;

always @(posedge btnc)
begin
	if(N==0)
		begin
			N <= sw;
			storeN <= sw;
			SUM <= 0;
			SUMSQ <= 0;
			AVG <= 0;
			//STD = 0;
		end
	else
		begin
			A[N] <= sw;
			SUM <= SUM + sw;
			SUMSQ <= SUMSQ + sw*sw;
			
			if(N == 1) begin 
				AVG <= (AVG+sw)/storeN;
				//
				/*for(temp=0;temp<=127;temp = temp+1) begin
					if(temp*temp <= (storeN*(SUMSQ+sw*sw) - (SUM+sw)*(SUM+sw))/(storeN*storeN) ) STD = temp;	
				end*/
			end	
					
			else
				AVG <= AVG + sw;
				
			N <= N - 1;
		end
end

always @(posedge clk)
begin
	if(temp == 127) temp = 0;
	else begin
		if(temp*temp <= (storeN*(SUMSQ) - (SUM)*(SUM))/(storeN*storeN) ) 
		begin
			if((temp+1)*(temp+1) > (storeN*(SUMSQ) - (SUM)*(SUM))/(storeN*storeN))
				STD = temp;
		end
		temp = temp + 1;
	end
end

always @(posedge btnr)
begin
	if(sw[0] == 0 && sw[1] == 0) begin
		led <= SUM;
	end
	
	
	if(sw[0] == 1 && sw[1] == 0) begin
		led <= AVG;
	end

	if(sw[0] == 0 && sw[1] == 1) begin
		led <= SUMSQ;
	end
	
	if(sw[0] == 1 && sw[1] == 1) begin
		
		led <= STD;
	end
	
end


endmodule


