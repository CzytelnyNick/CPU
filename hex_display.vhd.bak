library ieee;
use ieee.std_logic_1164.all;

-- =============================================================
-- Dekoder wyswietlacza 7-segmentowego (hex)
--
-- Wejscie:  hex_in  - 4-bitowa cyfra szesnastkowa (0x0..0xF)
-- Wyjscie:  seg_out - 7 segmentow aktywnych NISKIM stanem
--                     (standard plyt DE1-SoC / DE2i-150)
--
-- Uklad segmentow:
--      aaa
--     f   b
--     f   b
--      ggg
--     e   c
--     e   c
--      ddd
--
-- seg_out = (g, f, e, d, c, b, a)  -- bit 6..0
-- =============================================================

entity hex_display is
    port (
        hex_in  : in  std_logic_vector(3 downto 0);
        seg_out : out std_logic_vector(6 downto 0)
    );
end entity hex_display;

architecture rtl of hex_display is
begin
    process(hex_in)
    begin
        case hex_in is
            --                    gfedcba
            when "0000" => seg_out <= "1000000";  -- 0
            when "0001" => seg_out <= "1111001";  -- 1
            when "0010" => seg_out <= "0100100";  -- 2
            when "0011" => seg_out <= "0110000";  -- 3
            when "0100" => seg_out <= "0011001";  -- 4
            when "0101" => seg_out <= "0010010";  -- 5
            when "0110" => seg_out <= "0000010";  -- 6
            when "0111" => seg_out <= "1111000";  -- 7
            when "1000" => seg_out <= "0000000";  -- 8
            when "1001" => seg_out <= "0010000";  -- 9
            when "1010" => seg_out <= "0001000";  -- A
            when "1011" => seg_out <= "0000011";  -- b
            when "1100" => seg_out <= "1000110";  -- C
            when "1101" => seg_out <= "0100001";  -- d
            when "1110" => seg_out <= "0000110";  -- E
            when "1111" => seg_out <= "0001110";  -- F
            when others => seg_out <= "1111111";  -- wylaczony
        end case;
    end process;
end architecture rtl;