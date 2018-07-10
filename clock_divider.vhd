-----------------------------------
-- Author: Shabbir Hussain
-- Email: shabbir.hussain@mail.mcgill.ca
--
-- This is a module to slow down the clock to human speeds
-----------------------------------

-- Import the necessary libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare entity
entity clock_divider is
    Generic(
            slow_factor : integer := 10000000 -- 1 million times slower
           );
    Port (
        clk             : in std_logic; -- Clock for the system
        rst             : in std_logic; -- Reset counter
        slow_clk        : out std_logic -- Slow clock value
         );
end clock_divider;

architecture behaviour of clock_divider is
begin
    process(clk)
        --Internal Variable
        variable counter_reg : integer := 0;
        variable clk_reg     : std_logic;
    begin
        if(rst = '1') then
            counter_reg := 0;
            clk_reg := '0';
        elsif (clk'event and clk = '1') then
            counter_reg := counter_reg + 1;
            
            if (counter_reg = slow_factor) then
                clk_reg := '1';
                counter_reg := 0;
				else
					 clk_reg := '0';
            end if;

            slow_clk <= clk_reg;
        end if;
    end process;

end behaviour;


