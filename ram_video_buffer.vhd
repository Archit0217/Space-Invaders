-----------------------------------
-- Author: Shabbir Hussain
-- Email: shabbir.hussain@mail.mcgill.ca
-- Description: This entity is a dual port synchronous memory
--              it holds the values of each pixel
--              it is written to by the game controller
--              it is read by the VGA controller
-----------------------------------

-- Import the necessary libraries
library ieee;
use ieee.std_logic_1164.all;


-- Declare entity
entity ram_video_buffer is
    -- This Generic statement allows our entity to have paramers of variable lengths
    -- In this design we make the Address length and the data length variable
    -- The value written below is the default value that will be used if
    -- no other value is used during instantiation
    Generic(
	    DATA_ELEMENTS : integer := 1;
            DATA_WIDTH    : integer := 3;
            ADDRESS_WIDTH : integer := 32
           );
    Port (
            clk         : in std_logic; -- Clk for the system
            rst         : in std_logic; -- Resets the buffer
            clr         : in std_logic; -- Sets the memory to zero

            -- Inputs
            write_en        : in std_logic; -- Enables write to memory
            address_read    : in integer;
            address_write   : in integer;
            data_write      : in std_logic_vector(DATA_WIDTH-1 downto 0);

            -- Outputs
            data_read       : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
end ram_video_buffer;

architecture behaviour of ram_video_buffer is
    type memory_array is array(DATA_ELEMENTS-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal memory : Memory_array;
	 
	 signal color : integer := 0;
begin

    -- Read Process
    process(clk,rst)
    begin

        if(rst = '1') then
            -- Write zero to the data_out port
            data_read <= (others => '0');
			color <= 0;
        elsif rising_edge(clk) then
            -- Write stored value to data_out port
            data_read <= memory(address_read);
				
				--color <= color +1;
				--if color >= 3 then
				--	color <= 0;
				--end if;
        end if;

    end process;

    -- Write Process
    process(clk, rst, write_en, clr)
    begin
        if(rst = '1') then
            -- Reset internal registers
            for i in memory'Range loop
                memory(i) <= (others => '0');
            end loop;		
				
				--memory(0) <= "001";
				--memory(1) <= "010";
				--memory(2) <= "100";

        elsif rising_edge(clk) and write_en ='1' then
            -- Write new data to memrory
            memory(address_write) <= data_write;
        elsif rising_edge(clk) and clr ='1' then
            -- Clear all memory
            for i in memory'Range loop
                memory(i) <= (others => '0');
            end loop;		
        end if;
    end process;

end behaviour;
