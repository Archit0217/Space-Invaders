-----------------------------------
-- Author: Shabbir Hussain
-- Email: shabbir.hussain@mail.mcgill.ca

-- This module handles the synchronization and timing of the VGA output

-- Horizontal Sync
-- Configuration   | Resolution | Sync    | Back  Porch | RGB      | Front porch | Clock
-- 640x480(60Hz)   | 640x480    | 1.0us   |    2.3us    | 11.9 us  |    0.4us    | 25.175 MHz
--                                96 pix      48 pix      640 pix       16 pix 
-- Total pixels = sync+bp+rgb+fp = 800

-- Veritcal sync
-- Configuration   | Resolution | Sync    | Back  Porch |  RGB       | Front porch    | Clock
-- 640x480(60Hz)   | 640x480    |  2 line |    31 line  |  480 line  |    11 line     | 25.175 MHz
--
-- Total lines = 524

----------------------------------- 
-- Import the necessary libraries
library ieee;
use ieee.std_logic_1164.all;


-- Declare entity
entity vga_controller is
    Generic(
        MAX_H : integer := 800;
        S_H   : integer := 96;
        BP_H  : integer := 48;
        RGB_H : integer := 640;
        FP_H  : integer := 16;

        MAX_V : integer := 525;
        S_V   : integer := 2;
        BP_V  : integer := 33;
        RGB_V : integer := 480;
        FP_V  : integer := 10;

        PIXLS : integer := 307200 -- Total num Pixels = 640 x 480
           );
    Port (
    --Inputs
    clk         : in std_logic; -- VGA clock
    rst         : in std_logic;

    -- Outputs
	 pixel_x     : out integer;
	 pixel_y		 : out integer;
    vga_blank   : out std_logic;


    vga_hs      : out std_logic;
    vga_vs      : out std_logic;


    vga_clk     : out std_logic;
    vga_sync    : out std_logic	 
    );

end vga_controller;


architecture behaviour of vga_controller is
     signal hpos : integer range 0 to MAX_H := 0;
     signal vpos : integer range 0 to MAX_V := 0;
	 
	 signal vga_hsr : std_logic; -- Temp registers for 
	 signal vga_vsr : std_logic; -- Hsync and Vsync

    signal pixel_xr : integer := 0; -- Pixel position register
	 signal pixel_yr : integer := 0; -- Pixel position register

begin

    -- Map to DAC (digital to analog converter)
    vga_clk <= clk;
	 vga_hs <= vga_hsr;
	 vga_vs <= vga_vsr;
	 vga_sync <= (vga_hsr and vga_vsr);
	 pixel_x <= pixel_xr;
	 pixel_y <= pixel_yr;
	    
    process(clk)
    begin
        if(rst = '1') then
            hpos <= 0;
            vpos <= 0;

            pixel_xr <= 0;
				pixel_yr <= 0;

        elsif rising_edge(clk) then

            -- Hpos Vpos counter
            if( hpos < MAX_H) then
                hpos <= hpos + 1;
            else
                hpos <= 0;
                if( vpos <  MAX_V ) then
                    vpos <= vpos + 1;
                else 
                    vpos <= 0;
                end if;
            end if; -- end hpos < max_h

            -- Set sync
            if( hpos < S_H) then
                vga_hsr <= '0';
            else
                vga_hsr <= '1';
            end if;
            if( vpos < S_V) then
                vga_vsr <= '0';
            else
                vga_vsr <= '1';    
            end if;

            -- Back and front porch
            if( (hpos < S_H+BP_H) or
				    (hpos>=S_H+BP_H+RGB_H) or 
					 (vpos < S_V+BP_V) or 
					 (vpos>=S_V+BP_V+RGB_V)) then
                -- Set blank active low during FP and BP
                vga_blank <= '0';
            else
               
					-- Update pixel count
					if( pixel_xr < RGB_H-1) then
						pixel_xr <= pixel_xr + 1;
					else
						pixel_xr <= 0;					
						if (pixel_yr < RGB_V-1) then
							pixel_yr <= pixel_yr + 1;
						else
							pixel_yr <= 0;
						end if;
					end if;
					
                vga_blank <= '1';
            end if;
				
        end if;
    end process;
end behaviour;
