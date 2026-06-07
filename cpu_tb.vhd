library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- TESTBENCH procesora (end-to-end)
--
-- Program w ram_init.mif:
--   LDI rA, 7  ->  LDI rB, 2  ->  ADD rA,rA,rB  ->  HLT
-- Oczekiwany wynik: rA = 9, stan HLT (LEDR[9:6] = 1111)
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

    -- wyswietlacz 7-seg (aktywny niski) - zgodne z hex_display.vhd
    constant SEG0 : std_logic_vector(6 downto 0) := "1000000";
    constant SEG9 : std_logic_vector(6 downto 0) := "0010000";

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

        procedure chk_hex(signal got : std_logic_vector(6 downto 0);
                          exp        : std_logic_vector(6 downto 0);
                          name       : string) is
        begin
            if got /= exp then
                report "FAIL: " & name severity error;
                errcnt := errcnt + 1;
            else
                report "PASS: " & name severity note;
            end if;
        end procedure;

        procedure chk_vec(signal got : std_logic_vector;
                          exp        : std_logic_vector;
                          name       : string) is
        begin
            if got /= exp then
                report "FAIL: " & name severity error;
                errcnt := errcnt + 1;
            else
                report "PASS: " & name severity note;
            end if;
        end procedure;
    begin
        ----------------------------------------------------------------
        -- RESET (SW[1:0]=00 -> wyswietl rA)
        ----------------------------------------------------------------
        SW <= "0000000000";
        KEY(1) <= '0';
        wait for 20 ns;
        KEY(1) <= '1';
        wait for 20 ns;

        ----------------------------------------------------------------
        -- Wykonaj program (4 instr. x ~4 cykle stanow + zapas)
        ----------------------------------------------------------------
        for i in 1 to 40 loop
            tick;
        end loop;

        wait for 30 ns;

        ----------------------------------------------------------------
        -- Weryfikacja przez porty wyjsciowe
        -- SW=00: HEX3..0 = rA = 9 => 0009
        ----------------------------------------------------------------
        chk_hex(HEX0, SEG9, "rA = 9 (HEX0)");
        chk_hex(HEX1, SEG0, "rA = 0009 (HEX1)");
        chk_hex(HEX2, SEG0, "rA = 0009 (HEX2)");
        chk_hex(HEX3, SEG0, "rA = 0009 (HEX3)");

        -- LEDR[9:6] = state_dbg; HLT = 1111
        chk_vec(LEDR(9 downto 6), "1111", "stan HLT (state_dbg)");

        ----------------------------------------------------------------
        if errcnt = 0 then
            report "=== CPU_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== CPU_TB: LICZBA BLEDOW = " & integer'image(errcnt) & " ===" severity error;
        end if;

        wait;
    end process;

end architecture behavior;
