----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:03:29 04/11/2017 
-- Design Name: 
-- Module Name:    ram - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity A_row is
	port(
		Clk : in std_logic;
		fx2Clk_in : in std_logic;

		slide_sw_in : in integer range 0 to 255;
		debug_data : out std_logic_vector(7 downto 0);
		d_o : inout std_logic_vector(7 downto 0);

		col_send : in integer range 0 to 255;
		mod_en : in integer range 0 to 63;
		d_i : in std_logic_vector(7 downto 0);

		bij : in std_logic_vector(7 downto 0);
		sum : inout std_logic_vector(7 downto 0);
		
		col_read : in integer range 0 to 255;
		multiply  : in std_logic;
		store_data  : in std_logic;

		mod_num  : in integer range 0 to 63
	);
end A_row;

architecture Behavioral of A_row is

signal we : std_logic;
signal sum_next : std_logic_vector(7 downto 0) := x"AB";

begin

PROCESS(fx2Clk_in)
BEGIN
	if(rising_edge(fx2Clk_in)) then
		if(multiply = '1') then
			sum <= std_logic_vector(to_unsigned(to_integer(unsigned(sum))+to_integer(unsigned(d_o))*to_integer(unsigned(bij)),d_o'length));
			--sum <= d_o;
		end if;
		if(store_data = '1') then
			sum <= x"00";
		end if;
		--sum <= sum_next;
	end if;
END PROCESS;

	we <= '1' when mod_en = mod_num else '0';
	--sum_next <= std_logic_vector(to_unsigned(to_integer(unsigned(sum))+to_integer(unsigned(d_o))+to_integer(unsigned(bij)),d_o'length)) when multiply = '1' else 
	--				x"00" when store_data = '1' else sum;


	ram: entity work.ram
		port map(
			Clk => clk,
			r_address => col_read,
			w_address => col_send,
			we => we,
			data_i => d_i,
			data_o => d_o,
			
			debug_read => slide_sw_in,
			debug_data => debug_data
		);

end Behavioral;
