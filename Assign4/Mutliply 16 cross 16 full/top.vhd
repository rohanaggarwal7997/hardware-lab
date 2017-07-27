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
	signal debug_o4  : std_logic_vector(7 downto 0);
	signal debug_o5  : std_logic_vector(7 downto 0);
	signal debug_o6  : std_logic_vector(7 downto 0);
	signal debug_o7  : std_logic_vector(7 downto 0);
	signal debug_o8  : std_logic_vector(7 downto 0);
	signal debug_o9  : std_logic_vector(7 downto 0);
	signal debug_o10  : std_logic_vector(7 downto 0);
	signal debug_o11  : std_logic_vector(7 downto 0);
	signal debug_o12  : std_logic_vector(7 downto 0);
	signal debug_o13  : std_logic_vector(7 downto 0);
	signal debug_o14  : std_logic_vector(7 downto 0);
	signal debug_o15  : std_logic_vector(7 downto 0);
	signal debug_o16  : std_logic_vector(7 downto 0);
	signal debug_oB  : std_logic_vector(7 downto 0);
	signal d_o1  : std_logic_vector(7 downto 0);
	signal d_o2  : std_logic_vector(7 downto 0);
	signal d_o3  : std_logic_vector(7 downto 0);
	signal d_o4  : std_logic_vector(7 downto 0);
	signal d_o5  : std_logic_vector(7 downto 0);
	signal d_o6  : std_logic_vector(7 downto 0);
	signal d_o7  : std_logic_vector(7 downto 0);
	signal d_o8  : std_logic_vector(7 downto 0);
	signal d_o9  : std_logic_vector(7 downto 0);
	signal d_o10 : std_logic_vector(7 downto 0);
	signal d_o11 : std_logic_vector(7 downto 0);
	signal d_o12 : std_logic_vector(7 downto 0);
	signal d_o13 : std_logic_vector(7 downto 0);
	signal d_o14 : std_logic_vector(7 downto 0);
	signal d_o15 : std_logic_vector(7 downto 0);
	signal d_o16 : std_logic_vector(7 downto 0);
	
	signal module_enable  : integer range 0 to 63 := 0;
	signal module_enable_send  : integer range 0 to 63 := 0;
	signal col : integer range 0 to 63 := 0;
	signal col_send : integer range 0 to 63 := 0;
	signal num_b : integer range 0 to 511 := 511;
	signal ben_we  : std_logic := '0';
	
	signal processing_enable  : std_logic := '0';
	signal processing_stop  : std_logic := '0';
	signal fetch  : std_logic := '0';
	signal multiply  : std_logic := '0';
	signal store_data  : std_logic := '0';
	signal fetch_count  : integer range 0 to 511 := 0;
	signal multiply_count  : integer range 0 to 511 := 0;
	signal store_data_count  : integer range 0 to 255:= 0;
	signal col_read  : integer range 0 to 255 := 0;
	
	signal shared_sum1  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum2  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum3  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum4  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum5  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum6  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum7  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum8  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum9  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum10  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum11  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum12  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum13  : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum14 : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum15 : std_logic_vector(7 downto 0) := x"03";
	signal shared_sum16 : std_logic_vector(7 downto 0) := x"03";
	signal sh1  : std_logic_vector(7 downto 0);
	signal sh2  : std_logic_vector(7 downto 0);
	signal sh3  : std_logic_vector(7 downto 0);
	signal sh4  : std_logic_vector(7 downto 0);
	signal sh5  : std_logic_vector(7 downto 0);
	signal sh6  : std_logic_vector(7 downto 0);
	signal sh7  : std_logic_vector(7 downto 0);
	signal sh8  : std_logic_vector(7 downto 0);
	signal sh9  : std_logic_vector(7 downto 0);
	signal sh10  : std_logic_vector(7 downto 0);
	signal sh11 : std_logic_vector(7 downto 0);
	signal sh12 : std_logic_vector(7 downto 0);
	signal sh13 : std_logic_vector(7 downto 0);
	signal sh14 : std_logic_vector(7 downto 0);
	signal sh15 : std_logic_vector(7 downto 0);
	signal sh16 : std_logic_vector(7 downto 0);
	signal s_o1  : std_logic_vector(7 downto 0);
	signal s_o2  : std_logic_vector(7 downto 0);
	signal s_o3  : std_logic_vector(7 downto 0);
	signal s_o4  : std_logic_vector(7 downto 0);
	signal s_o5  : std_logic_vector(7 downto 0);
	signal s_o6  : std_logic_vector(7 downto 0);
	signal s_o7  : std_logic_vector(7 downto 0);
	signal s_o8  : std_logic_vector(7 downto 0);
	signal s_o9  : std_logic_vector(7 downto 0);
	signal s_o10  : std_logic_vector(7 downto 0);
	signal s_o11  : std_logic_vector(7 downto 0);
	signal s_o12  : std_logic_vector(7 downto 0);
	signal s_o13  : std_logic_vector(7 downto 0);
	signal s_o14 : std_logic_vector(7 downto 0);
	signal s_o15  : std_logic_vector(7 downto 0);
	signal s_o16 : std_logic_vector(7 downto 0);
	signal store_enable  : std_logic;
	signal s1_count : integer range 0 to 255 := 2;
	signal s2_count : integer range 0 to 255 := 2;
	signal s3_count : integer range 0 to 255 := 2;
	signal s4_count : integer range 0 to 255 := 2;
	signal s5_count : integer range 0 to 255 := 2;
	signal s6_count : integer range 0 to 255 := 2;
	signal s7_count : integer range 0 to 255 := 2;
	signal s8_count : integer range 0 to 255 := 2;
	signal s9_count : integer range 0 to 255 := 2;
	signal s10_count : integer range 0 to 255 := 2;
	signal s11_count : integer range 0 to 255 := 2;
	signal s12_count : integer range 0 to 255 := 2;
	signal s13_count : integer range 0 to 255 := 2;
	signal s14_count : integer range 0 to 255 := 2;
	signal s15_count : integer range 0 to 255 := 2;
	signal s16_count : integer range 0 to 255 := 2;
	--signal const_2  : std_logic_vector(7 downto 0):=x"02";
	
	signal Arow1_count : integer range 0 to 255 := 1;
	signal Arow2_count : integer range 0 to 255 := 1;
	signal Arow3_count : integer range 0 to 255 := 1;
	signal Arow4_count : integer range 0 to 255 := 1;
	signal Arow5_count : integer range 0 to 255 := 1;
	signal Arow6_count : integer range 0 to 255 := 1;
	signal Arow7_count : integer range 0 to 255 := 1;
	signal Arow8_count : integer range 0 to 255 := 1;
	signal Arow9_count : integer range 0 to 255 := 1;
	signal Arow10_count : integer range 0 to 255 := 1;
	signal Arow11_count : integer range 0 to 255 := 1;
	signal Arow12_count : integer range 0 to 255 := 1;
	signal Arow13_count : integer range 0 to 255 := 1;
	signal Arow14_count : integer range 0 to 255 := 1;
	signal Arow15_count : integer range 0 to 255 := 1;
	signal Arow16_count : integer range 0 to 255 := 1;
	signal B_count : integer range 0 to 511 := 1;
		
begin
	
	-- Infer registers
	process(fx2Clk_in)
	begin
		if(rising_edge(fx2Clk_in)) then
			reg0 <= reg0_next;
			
			if(h2fValid = '1') then
				if(module_enable <= 15) then
					if(col = 15) then
						col <= 0;
						module_enable <= module_enable + 1;
					else
						col <= col + 1;
					end if;
					col_send<=col;
				end if;
				
				if(module_enable = 16) then
					
					if(num_b = 511) then
						num_b <= 0;
					else
						if (num_b = 254) then
							module_enable <= 17;
						end if;						
						num_b <= num_b + 1;
					end if;
				end if;
				
				if(module_enable = 17) then
					if(num_b = 255) then
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
						if(multiply_count mod 16 = 15) then
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
						sh3 <= shared_sum3;
						sh4 <= shared_sum4;
						sh5 <= shared_sum5;
						sh6 <= shared_sum6;
						sh7 <= shared_sum7;
						sh8 <= shared_sum8;
						sh9 <= shared_sum9;
						sh10 <= shared_sum10;
						sh11 <= shared_sum11;
						sh12 <= shared_sum12;
						sh13 <= shared_sum13;
						sh14 <= shared_sum14;
						sh15 <= shared_sum15;
						sh16 <= shared_sum16;
						
						if (store_data_count = 15) then								
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
					if(chanAddr = "0000101") then
						s3_count <= s3_count + 1;
					end if;
					if(chanAddr = "0000110") then
						s4_count <= s4_count + 1;
					end if;
					if(chanAddr = "0000111") then
						s5_count <= s5_count + 1;
					end if;
					if(chanAddr = "0001000") then
						s6_count <= s6_count + 1;
					end if;
					if(chanAddr = "0001001") then
						s7_count <= s7_count + 1;
					end if;
					if(chanAddr = "0001010") then
						s8_count <= s8_count + 1;
					end if;
					if(chanAddr = "0001011") then
						s9_count <= s9_count + 1;
					end if;
					if(chanAddr = "0001100") then
						s10_count <= s10_count + 1;
					end if;
					if(chanAddr = "0001101") then
						s11_count <= s11_count + 1;
					end if;
					if(chanAddr = "0001110") then
						s12_count <= s12_count + 1;
					end if;
					if(chanAddr = "0001111") then
						s13_count <= s13_count + 1;
					end if;
					if(chanAddr = "0010000") then
						s14_count <= s14_count + 1;
					end if;
					if(chanAddr = "0010001") then
						s15_count <= s15_count + 1;
					end if;
					if(chanAddr = "0010010") then
						s16_count <= s16_count + 1;
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
		s_o3				when "0000101",
		s_o4				when "0000110",
		s_o5				when "0000111",
		s_o6				when "0001000",
		s_o7				when "0001001",
		s_o8				when "0001010",
		s_o9				when "0001011",
		s_o10				when "0001100",
		s_o11				when "0001101",
		s_o12				when "0001110",
		s_o13				when "0001111",
		s_o14				when "0010000",
		s_o15				when "0010001",
		s_o16				when "0010010",
		shared_sum1				when "0010011",
		shared_sum2				when "0010100",
		d_o1				when "0010101",
		d_o2				when "0010110",
		d_oB				when "0010111",
		--std_logic_vector(to_unsigned(fetch_count,d_oB'length))		when "0001100",
		--std_logic_vector(to_unsigned(multiply_count,d_oB'length)) when "0001101",
		--std_logic_vector(to_unsigned(store_data_count,d_oB'length)) 	when "0001110",
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

	r3: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow3_count,
					debug_data => debug_o3,
					d_o => d_o3,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum3,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 2
		 );

	r4: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow4_count,
					debug_data => debug_o4,
					d_o => d_o4,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum4,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 3
		 );

	r5: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow5_count,
					debug_data => debug_o5,
					d_o => d_o5,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum5,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 4
		 );

	r6: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow6_count,
					debug_data => debug_o6,
					d_o => d_o6,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum6,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 5
		 );

	r7: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow7_count,
					debug_data => debug_o7,
					d_o => d_o7,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum7,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 6
		 );

	r8: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow8_count,
					debug_data => debug_o8,
					d_o => d_o8,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum8,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 7
		 );

	r9: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow9_count,
					debug_data => debug_o9,
					d_o => d_o9,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum9,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 8
		 );

	r10: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow10_count,
					debug_data => debug_o10,
					d_o => d_o10,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum10,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 9
		 );

	r11: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow11_count,
					debug_data => debug_o11,
					d_o => d_o11,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum11,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 10
		 );

	r12: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow12_count,
					debug_data => debug_o12,
					d_o => d_o12,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum12,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 11
		 );

	r13: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow13_count,
					debug_data => debug_o13,
					d_o => d_o13,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum13,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 12
		 );

	r14: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow14_count,
					debug_data => debug_o14,
					d_o => d_o14,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum14,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 13
		 );

	r15: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow15_count,
					debug_data => debug_o15,
					d_o => d_o15,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum15,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 14
		 );

	r16: entity work.A_row
		 port map(
					Clk => clk,
					fx2Clk_in => fx2Clk_in,

					slide_sw_in => Arow16_count,
					debug_data => debug_o16,
					d_o => d_o16,

					col_send => col_send,
					mod_en => module_enable_send,
					d_i => reg0,

					bij => d_oB,
					sum => shared_sum16,

					col_read => col_read,
					multiply => multiply,
					store_data => store_data,

					mod_num => 15
		 );
	
	ben_we <= '1' when module_enable_send = 16  else '0';
	rB: entity work.ramB
		port map(
			Clk => clk,
			r_address => fetch_count,
			w_address => num_b,
			we => ben_we,
			data_i => reg0,
			data_o => d_oB,
			
			debug_read => B_count,
			debug_data => debug_oB
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

	s3: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s3_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh3,
				 data_o => s_o3
	  );

	s4: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s4_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh4,
				 data_o => s_o4
	  );

	s5: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s5_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh5,
				 data_o => s_o5
	  );

	s6: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s6_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh6,
				 data_o => s_o6
	  );

	s7: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s7_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh7,
				 data_o => s_o7
	  );

	s8: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s8_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh8,
				 data_o => s_o8
	  );

	s9: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s9_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh9,
				 data_o => s_o9
	  );

	s10: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s10_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh10,
				 data_o => s_o10
	  );

	s11: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s11_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh11,
				 data_o => s_o11
	  );

	s12: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s12_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh12,
				 data_o => s_o12
	  );

	s13: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s13_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh13,
				 data_o => s_o13
	  );

	s14: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s14_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh14,
				 data_o => s_o14
	  );

	s15: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s15_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh15,
				 data_o => s_o15
	  );

	s16: entity work.ram_store
	  port map(
				 Clk => clk,
				 r_address => s16_count,
				 w_address => store_data_count,
				 we => store_enable,
				 data_i => sh16,
				 data_o => s_o16
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

