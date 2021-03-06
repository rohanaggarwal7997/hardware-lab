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

entity ram_mod_B is
port (Clk : in std_logic;
        r_address : in integer range 0 to 255;
		  w_address : in integer range 0 to 255;
        we : in std_logic;
        data_i : in std_logic_vector(7 downto 0);
		  data_o : out std_logic_vector(7 downto 0)
     );
end ram_mod_B;

architecture Behavioral of ram_mod_B is

--Declaration of type and signal of a 256 element RAM
--with each element being 8 bit wide.
type ram_t is array (0 to 255) of std_logic_vector(7 downto 0);
signal ram : ram_t := (others => (others => '0'));

begin

--process for read and write operation.
PROCESS(Clk)
BEGIN
    if(rising_edge(Clk)) then
        if(we = '1') then
				ram(w_address) <= data_i;
		  end if;
        data_o <= ram(r_address);
    end if;
END PROCESS;

end Behavioral;
