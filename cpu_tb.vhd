library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- =============================================================
-- TESTBENCH POZIOMU SYSTEMU (end-to-end) dla demonstratora DE1-SoC
--
-- Steruje portami zewnetrznymi SW/KEY i sprawdza wyjscia HEX/LEDR
-- zgodnie z mapowaniem opisanym w CPU.vhd oraz README.md.
-- =============================================================

entity cpu_tb is
end entity;

architecture behavior of cpu_tb is

    component CPU
        port (
            SW   : in  std_logic_vector(9 downto 0);
            KEY  : in  std_logic_vector(1 downto 0);
            LEDR : out std_logic_vector(9 downto 0);
            HEX0 : out std_logic_vector(6 downto 0);
            HEX1 : out std_logic_vector(6 downto 0);
            HEX2 : out std_logic_vector(6 downto 0);
            HEX3 : out std_logic_vector(6 downto 0);
            HEX4 : out std_logic_vector(6 downto 0);
            HEX5 : out std_logic_vector(6 downto 0)
        );
    end component;

    signal SW   : std_logic_vector(9 downto 0) := (others => '0');
    signal KEY  : std_logic_vector(1 downto 0) := (others => '1');
    signal LEDR : std_logic_vector(9 downto 0);
    signal HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : std_logic_vector(6 downto 0);

    constant SEG0 : std_logic_vector(6 downto 0) := "1000000";
    constant SEG1 : std_logic_vector(6 downto 0) := "1111001";
    constant SEG5 : std_logic_vector(6 downto 0) := "0010010";
    constant SEG6 : std_logic_vector(6 downto 0) := "0000010";
    constant SEG9 : std_logic_vector(6 downto 0) := "0010000";
    constant SEGE : std_logic_vector(6 downto 0) := "0000110";

begin

    uut: CPU
        port map (
            SW   => SW,
            KEY  => KEY,
            LEDR => LEDR,
            HEX0 => HEX0,
            HEX1 => HEX1,
            HEX2 => HEX2,
            HEX3 => HEX3,
            HEX4 => HEX4,
            HEX5 => HEX5
        );

    process
        variable errcnt : integer := 0;

        procedure chk_hex(signal got : in std_logic_vector(6 downto 0);
                          exp        : in std_logic_vector(6 downto 0);
                          name       : in string) is
        begin
            if got /= exp then
                report "FAIL: " & name severity error;
                errcnt := errcnt + 1;
            else
                report "PASS: " & name severity note;
            end if;
        end procedure;

        procedure chk_bit(signal got : in std_logic;
                          exp        : in std_logic;
                          name       : in string) is
        begin
            if got /= exp then
                report "FAIL: " & name severity error;
                errcnt := errcnt + 1;
            else
                report "PASS: " & name severity note;
            end if;
        end procedure;
    begin
        SW <= "0000000000";  -- ADD, preset 00: 0007 + 0002 = 0009
        wait for 20 ns;
        chk_hex(HEX0, SEG9, "ADD 7+2 = 0009 (HEX0)");
        chk_hex(HEX1, SEG0, "ADD 7+2 = 0009 (HEX1)");
        chk_hex(HEX2, SEG0, "ADD 7+2 = 0009 (HEX2)");
        chk_hex(HEX3, SEG0, "ADD 7+2 = 0009 (HEX3)");
        chk_bit(LEDR(0), '1', "ADD flaga P = 1");
        chk_bit(LEDR(3), '0', "ADD flaga C = 0");

        SW <= "0000000001";  -- SUB, wynik 0005
        wait for 20 ns;
        chk_hex(HEX0, SEG5, "SUB 7-2 = 0005 (HEX0)");

        SW <= "0000000010";  -- MUL, wynik 000E
        wait for 20 ns;
        chk_hex(HEX0, SEGE, "MUL 7*2 = 000E (HEX0)");

        SW <= "0000000110";  -- DEC, wynik 0006
        wait for 20 ns;
        chk_hex(HEX0, SEG6, "DEC 7 = 0006 (HEX0)");

        SW <= "0000010101";  -- CMP_GT, 7 > 2 => 0001
        wait for 20 ns;
        chk_hex(HEX0, SEG1, "CMP_GT 7>2 = 0001 (HEX0)");
        chk_bit(LEDR(4), '1', "CMP_GT piaty bit opcode = 1");

        SW <= "1000010101";  -- SWAP, CMP_GT, 2 > 7 => 0000
        wait for 20 ns;
        chk_hex(HEX0, SEG0, "SWAP CMP_GT 2>7 = 0000 (HEX0)");
        chk_bit(LEDR(9), '1', "SWAP LED = 1");

        SW <= "0100000000";  -- S_F=1, ADD flags C/Z/S/P = 0001
        wait for 20 ns;
        chk_hex(HEX0, SEG1, "S_F pokazuje flagi ADD jako 0001 (HEX0)");
        chk_hex(HEX1, SEG0, "S_F pokazuje flagi ADD jako 0001 (HEX1)");

        if errcnt = 0 then
            report "=== CPU_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== CPU_TB: LICZBA BLEDOW = " & integer'image(errcnt) & " ===" severity error;
        end if;

        wait;
    end process;

end architecture;
