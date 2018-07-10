-----------------------------------
-- Author: Shabbir Hussain
-- Email: shabbir.hussain@mail.mcgill.ca
-- Description: This entity decodes a 4 bit number to color vectors for the VGA
-----------------------------------

-- Import the necessary libraries
library ieee;
use ieee.std_logic_1164.all;


-- Declare entity
entity color_decoder is
    Port (
            -- Inputs
            color    : in std_logic_vector(2 downto 0); 
            
            -- Outputs
				r       : out std_logic_vector(7 downto 0);
				g       : out std_logic_vector(7 downto 0);
				b       : out std_logic_vector(7 downto 0)
        );
end color_decoder;

architecture behaviour of color_decoder is

begin
	process(color)
	begin
		case color is
		when "000" =>
			r <= (others => '0');
			g <= (others => '0');
			b <= (others => '0');
		when "001" =>
			r <= (others => '0');
			g <= (others => '0');
			b <= (others => '1');
		when "010" =>
			r <= (others => '0');
			g <= (others => '1');
			b <= (others => '0');
		when "011" =>
			r <= (others => '0');
			g <= (others => '1');
			b <= (others => '1');
		when "100" =>
			r <= (others => '1');
			g <= (others => '0');
			b <= (others => '0');
		when "101" =>
			r <= (others => '1');
			g <= (others => '0');
			b <= (others => '1');
		when "110" =>
			r <= (others => '1');
			g <= (others => '1');
			b <= (others => '0');
		when "111" =>
			r <= (others => '1');
			g <= (others => '1');
			b <= (others => '1');
		end case;
	end process;
end behaviour;
