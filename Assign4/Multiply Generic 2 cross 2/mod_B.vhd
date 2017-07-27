----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:25:41 04/14/2017 
-- Design Name: 
-- Module Name:    mod_B - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity mod_B is
	port(
		Clk : in std_logic;

		slide_sw_in : in integer range 0 to 255;
		debug_data : out std_logic_vector(7 downto 0);

		mod_en : in integer range 0 to 2;

		d_i : in std_logic_vector(7 downto 0);

		mod_num  : in integer range 0 to 2
	);
end mod_B;

architecture Behavioral of mod_B is

signal count : integer range 0 to 2 := 0;
signal d_o : std_logic_vector(7 downto 0) := x"00";
signal we : std_logic;
signal mul_en : std_logic;

begin

PROCESS(Clk)
BEGIN
	if(rising_edge(Clk)) then
		if(pr_en = '1') then
			count <= 1;
			mul_en <= '1';
		end if;
		if(mul_en = '1') then
			if(count /= 0) then
				sum <= std_logic_vector( to_unsigned( to_integer(unsigned(sum)) + to_integer(unsigned(d_o))*to_integer(unsigned(bij)) ,d_o'length ) );
			else
				sum <= x"00";
			end if;
			count <= count + 1;
		end if;
	end if;
END PROCESS;

	we <= '1' when mod_en = mod_num else '0';

	ram: entity work.ram
		port map(
			Clk => clk,
			r_address => count,
			w_address => col_send,
			we => we,
			data_i => d_i,
			data_o => d_o,
			
			debug_read => slide_sw_in,
			debug_data => debug_data
		);

end Behavioral;

