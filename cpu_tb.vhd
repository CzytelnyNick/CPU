library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- =============================================================
-- TESTBENCH POZIOMU SYSTEMU dla CPU
--
-- Sprawdza:
--   1) tryb demonstratora ALU (SW9=0),
--   2) pierwsze pobranie instrukcji w trybie procesora (SW9=1).
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
    constant SEG2 : std_logic_vector(6 downto 0) := "0100100";
    constant SEG4 : std_logic_vector(6 downto 0) := "0011001";
    constant SEG7 : std_logic_vector(6 downto 0) := "1111000";
    constant SEG9 : std_logic_vector(6 downto 0) := "0010000";
    constant SEGF : std_logic_vector(6 downto 0) := "0001110";

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

        procedure tick is
        begin
            KEY(0) <= '0';
            wait for 10 ns;
            KEY(0) <= '1';
            wait for 10 ns;
        end procedure;

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
    begin
        -- Tryb ALU demo: SW9=0, preset 00, ADD 7+2 = 0009.
        SW <= "0000000000";
        wait for 20 ns;
        chk_hex(HEX0, SEG9, "ALU demo ADD 7+2 = 0009 HEX0");
        chk_hex(HEX1, SEG0, "ALU demo ADD 7+2 = 0009 HEX1");

        -- Tryb procesora: SW9=1, SW[7:6]=00 pokazuje IR.
        SW <= "1000000000";
        KEY(1) <= '0';
        wait for 20 ns;
        KEY(1) <= '1';
        wait for 20 ns;

        tick; -- f0: fetch z PC=0
        tick; -- f1: IR <= MEM[0] = 4407
        wait for 20 ns;

        chk_hex(HEX0, SEG7, "CPU IR low nibble po fetch = 7");
        chk_hex(HEX3, SEG4, "CPU IR high nibble po fetch = 4");

        -- Dokoncz LDI rA, LDI rB, ADD, MUL, STORE i LOAD.
        -- Po 28 taktach od resetu LOAD wpisal juz wynik z MEM[0x20] do DI/rC.
        for i in 3 to 28 loop
            tick;
        end loop;
        SW <= "1010000000"; -- SW9=1, SW[7:6]=10: podglad DI z pamieci
        wait for 20 ns;
        chk_hex(HEX0, SEG2, "CPU LOAD DI low nibble = 2");
        chk_hex(HEX1, SEG1, "CPU LOAD DI high nibble = 1, czyli 0x0012");

        -- Ostatnia instrukcja programu to HLT pod adresem 006.
        SW <= "1000000000"; -- podglad IR
        tick; -- fetch HLT
        tick; -- IR <= 1F00
        tick; -- decode -> halt
        wait for 20 ns;
        chk_hex(HEX3, SEG1, "CPU HLT IR high nibble = 1");
        chk_hex(HEX2, SEGF, "CPU HLT IR nibble = F");
        chk_hex(HEX5, SEGF, "CPU state halt = F na HEX5");

        if errcnt = 0 then
            report "=== CPU_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== CPU_TB: LICZBA BLEDOW = " & integer'image(errcnt) & " ===" severity error;
        end if;

        wait;
    end process;

end architecture;
