-- 32 bit pseudorandom sequence generator.
-- expanded to 256 bits by replication, but only the first 32 are independent bits
--
-- revision 1.0
-- Designer: James J. Clark
-- November 12, 2002
--

library ieee;
use ieee.std_logic_1164.all;

entity random_32bit is
 port ( clk, rst  : in std_logic; 
        random     : out std_logic_vector(255 downto 0)); 
end random_32bit;

architecture behaviour of random_32bit is
signal randout : std_logic_vector(31 downto 0);
begin
    process (clk, rst)
    begin
    if rst = '1' then
        randout <= "00010001100011010001000111010010";
    elsif clk = '1' and clk'EVENT then
        randout <= randout(30 downto 0) & not ((randout(31) xor  randout(21)) xor (randout(1) xor randout(0)));
        random(31 downto 0) <= randout xor "10110111000100110110101101000110";
        random(63 downto 32) <= randout xor "10111101010010101011111010100111";
        random(95 downto 64) <= randout xor "00100101010111000001111010101010";
        random(127 downto 96) <= randout xor "11110101010010111011001110011101";
        random(159 downto 128) <= randout xor "00000011101010101001011110011101";
        random(191 downto 160) <= randout xor "01010001010101001111000010101010";
        random(223 downto 192) <= randout xor "10110111000100110110101101000110";
        random(255 downto 224) <= randout xor "10111011010010100101010101010101";

    end if;
    end process;
end behaviour;
