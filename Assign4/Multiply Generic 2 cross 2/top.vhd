 ----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:02:14 04/11/2017 
-- Design Name: 
-- Module Name:    top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
port(
		-- FX2 interface -----------------------------------------------------------------------------
		fx2Clk_in     : in    std_logic;                    -- 48MHz clock from FX2
		fx2Addr_out   : out   std_logic_vector(1 downto 0); -- select FIFO: "10" for EP6OUT, "11" for EP8IN
		fx2Data_io    : inout std_logic_vector(7 downto 0); -- 8-bit data to/from FX2

		-- When EP6OUT selected:
		fx2Read_out   : out   std_logic;                    -- asserted (active-low) when reading from FX2
		fx2OE_out     : out   std_logic;                    -- asserted (active-low) to tell FX2 to drive bus
		fx2GotData_in : in    std_logic;                    -- asserted (active-high) when FX2 has data for us

		-- When EP8IN selected:
		fx2Write_out  : out   std_logic;                    -- asserted (active-low) when writing to FX2
		fx2GotRoom_in : in    std_logic;                    -- asserted (active-high) when FX2 has room for more data from us
		fx2PktEnd_out : out   std_logic;                    -- asserted (active-low) when a host read needs to be committed early

		-- Onboard peripherals -----------------------------------------------------------------------
		led_out       : out   std_logic_vector(7 downto 0); -- eight LEDs
		slide_sw_in   : in    std_logic_vector(7 downto 0); -- eight slide switches
		
		clk : in std_logic
	);
end top;

	architecture Behavioral of top is

	-- Channel read/write interface -----------------------------------------------------------------
	signal chanAddr  : std_logic_vector(6 downto 0);  -- the selected channel (0-127)

	-- Host >> FPGA pipe:
	signal h2fData   : std_logic_vector(7 downto 0);  -- data lines used when the host writes to a channel
	signal h2fValid  : std_logic;                     -- '1' means "on the next clock rising edge, please accept the data on h2fData"
	signal h2fReady  : std_logic;                     -- channel logic can drive this low to say "I'm not ready for more data yet"

	-- Host << FPGA pipe:
	signal f2hData   : std_logic_vector(7 downto 0);  -- data lines used when the host reads from a channel
	signal f2hValid  : std_logic;                     -- channel logic can drive this low to say "I don't have data ready for you"
	signal f2hReady  : std_logic;                     -- '1' means "on the next clock rising edge, put your next byte of data on f2hData"
	-- ----------------------------------------------------------------------------------------------

	-- Needed so that the comm_fpga_fx2 module can drive both fx2Read_out and fx2OE_out
	signal fx2Read                 : std_logic;
	
	-- Registers implementing the channels
	signal reg0, reg0_next         : std_logic_vector(7 downto 0)  := x"00";

	signal d_oB  : std_logic_vector(7 downto 0);
	
	signal debug_o1  : std_logic_vector(7 downto 0);
	signal debug_o2  : std_logic_vector(7 downto 0);
	signal debug_o3  : std_logic_vector(7 downto 0);
	signal d_o1  : std_logic_vector(7 downto 0);
	signal d_o2  : std_logic_vector(7 downto 0);
	
	signal module_enable  : integer range 0 to 3 := 0;
	signal module_enable_send  : integer range 0 to 3 := 0;
	signal col : integer range 0 to 2 := 0;
	signal col_send : integer range 0 to 2 := 0;
	signal num_b : integer range 0 to 7 := 7;
	signal ben_we  : std_logic := '0';
	
	signal processing_enable  : std_logic := '0';
	signal processing_stop  : std_logic := '0';
	signal fetch  : std_logic := '0';
	signal multiply  : std_logic := '0';
	signal store_data  : std_logic := '0';
	signal fetch_count  : integer range 0 to 255 := 0;
	signal multiply_count  : integer range 0 to 255 := 0;
	signal store_data_count  : integer range 0 to 255:= 0;
	signal col_read  : integer range 0 to 255 := 0;
	
	signal shared_sum1  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum2  : std_logic_vector(7 downto 0) := x"03";
	signal sh1  : std_logic_vector(7 downto 0);
	signal sh2  : std_logic_vector(7 downto 0);
	signal s_o1  : std_logic_vector(7 downto 0);
	signal s_o2  : std_logic_vector(7 downto 0);
	signal store_enable  : std_logic;
	signal s1_count : integer range 0 to 255 := 2;
	signal s2_count : integer range 0 to 255 := 2;
	--signal const_2  : std_logic_vector(7 downto 0):=x"02";
	
	signal Arow1_count : integer range 0 to 255 := 1;
	signal Arow2_count : integer range 0 to 255 := 1;
	signal B_count : integer range 0 to 255 := 1;
		
begin
	
	-- Infer registers
	process(fx2Clk_in)
	begin
		if(rising_edge(fx2Clk_in)) then
			reg0 <= reg0_next;
			
			if(h2fValid = '1') then
				if(module_enable <= 1) then
					if(col = 1) then
						col <= 0;
						module_enable <= module_enable + 1;
					else
						col <= col + 1;
					end if;
					col_send<=col;
				end if;
				
				if(module_enable = 2) then
					
					if(num_b = 7) then
						num_b <= 0;
					else
						if (num_b = 2) then
							module_enable <= 3;
						end if;						
						num_b <= num_b + 1;
					end if;
				end if;
				
				if(module_enable = 3) then
					if(num_b = 3) then
							processing_enable <= '1';
					end if;
					num_b <= num_b + 1;
				end if;
				
				module_enable_send <= module_enable;
			end if;
			
			if(processing_enable = '1' and processing_stop = '0') then
					fetch <= '1';
					if(fetch = '1') then
						fetch_count <= fetch_count + 1;
						col_read <= col_read + 1;
						multiply <= '1';
					end if;
					--multiply has delay 1 w.r.t fetch
					if(multiply = '1') then
						multiply_count <= multiply_count + 1;
						if(multiply_count = 1 or multiply_count = 3) then
							col_read <= 0;
							store_data <= '1';
							multiply <= '0';
							fetch <= '0';
							fetch_count <= fetch_count;
						end if;
					end if;
					
					if(store_data = '1') then
						sh1 <= shared_sum1;
						sh2 <= shared_sum2;
						
						if (store_data_count = 1) then								
								processing_stop <= '1';
						end if;
						
						fetch <= '1';
						store_data <= '0';
						store_data_count <= store_data_count + 1;
					end if;
					
				end if;

				if(f2hReady = '1') then
					if(chanAddr = "0000000") then
						Arow1_count <= Arow1_count + 1;
					end if;
					if(chanAddr = "0000001") then
						Arow2_count <= Arow2_count + 1;
					end if;
					if(chanAddr = "0000010") then
						B_count <= B_count + 1;
					end if;
					if(chanAddr = "0000011") then
						s1_count <= s1_count + 1;
					end if;
					if(chanAddr = "0000100") then
						s2_count <= s2_count + 1;
					end if;
				end if;
		end if;
	end process;
	
	-- Drive register inputs for each channel when the host is writing
	reg0_next <= h2fData when chanAddr = "0000000" and h2fValid = '1' else reg0;
	
	with chanAddr select f2hData <=
		slide_sw_in 	when "1000000", -- return status of slide switches when reading R0
		debug_o1				when "0000000",
		debug_o2				when "0000001",
		debug_o3				when "0000010",
		s_o1				when "0000011",
		s_o2				when "0000100",
		shared_sum1				when "0000111",
		shared_sum2				when "0001000",
		d_o1				when "0001001",
		d_o2				when "0001010",
		d_oB				when "0001011",
		std_logic_vector(to_unsigned(fetch_count,d_oB'length))		when "0001100",
		std_logic_vector(to_unsigned(multiply_count,d_oB'length)) when "0001101",
		std_logic_vector(to_unsigned(store_data_count,d_oB'length)) 	when "0001110",
		x"00" 			when others;


	r1: entity work.A_row
		port map(
			Clk => clk,
			fx2Clk_in => fx2Clk_in,
			
			slide_sw_in => Arow1_count,
			debug_data => debug_o1,
			d_o => d_o1,
			
			col_send => col_send,
			mod_en => module_enable_send,
			d_i => reg0,
			
			bij => d_oB,
			sum => shared_sum1,
			
			col_read => col_read,
			multiply => multiply,
			store_data => store_data,
			
			mod_num => 0
		);
		
	r2: entity work.A_row
		port map(
			Clk => clk,
			fx2Clk_in => fx2Clk_in,
			
			slide_sw_in => Arow2_count,
			debug_data => debug_o2,
			d_o => d_o2,
			
			col_send => col_send,
			mod_en => module_enable_send,
			d_i => reg0,
			
			bij => d_oB,
			sum => shared_sum2,
			
			col_read => col_read,
			multiply => multiply,
			store_data => store_data,
			
			mod_num => 1
		);
	
	ben_we <= '1' when module_enable_send = 2  else '0';
	r3: entity work.ram
		port map(
			Clk => clk,
			r_address => fetch_count,
			w_address => num_b,
			we => ben_we,
			data_i => reg0,
			data_o => d_oB,
			
			debug_read => B_count,
			debug_data => debug_o3
		);

	store_enable <= '1' when processing_enable = '1' else '0';
	s1: entity work.ram_store
		port map(
			Clk => clk,
			r_address => s1_count,
			w_address => store_data_count,
			we => store_enable,
			data_i => sh1,
			data_o => s_o1
		);
		
	s2: entity work.ram_store
		port map(
			Clk => clk,
			r_address => s2_count,
			w_address => store_data_count,
			we => store_enable,
			data_i => sh2,
			data_o => s_o2
		);

	--led_out <= reg0;
	led_out(0) <= fetch;
	led_out(1) <= multiply;
	led_out(2) <= store_data;
	led_out(3) <= processing_enable;
	led_out(4) <= processing_stop;
	
	-- Assert that there's always data for reading, and always room for writing
	f2hValid <= '1';
	h2fReady <= '1';								--END_SNIPPET(registers)

	-- CommFPGA module
	fx2Read_out <= fx2Read;
	fx2OE_out <= fx2Read;
	fx2Addr_out(1) <= '1';  -- Use EP6OUT/EP8IN, not EP2OUT/EP4IN.
	comm_fpga_fx2 : entity work.comm_fpga_fx2
		port map(
			-- FX2 interface
			fx2Clk_in      => fx2Clk_in,
			fx2FifoSel_out => fx2Addr_out(0),
			fx2Data_io     => fx2Data_io,
			fx2Read_out    => fx2Read,
			fx2GotData_in  => fx2GotData_in,
			fx2Write_out   => fx2Write_out,
			fx2GotRoom_in  => fx2GotRoom_in,
			fx2PktEnd_out  => fx2PktEnd_out,

			-- Channel read/write interface
			chanAddr_out   => chanAddr,
			h2fData_out    => h2fData,
			h2fValid_out   => h2fValid,
			h2fReady_in    => h2fReady,
			f2hData_in     => f2hData,
			f2hValid_in    => f2hValid,
			f2hReady_out   => f2hReady
		);


end Behavioral;

