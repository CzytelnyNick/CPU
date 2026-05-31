library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================
-- TESTBENCH POZIOMU SYSTEMU (end-to-end) dla CPU
--
-- Steruje wylacznie portami zewnetrznymi (SW, KEY) i sprawdza
-- wyjscia HEX/LEDR - dokladnie tak jak na plytce.
--
-- Tryby (SW[9:8]): 00=ALU, 01=RAM WRITE, 10=RAM READ, 11=INSPECT.
--
-- Scenariusze:
--   1) ALU: rA=7, rB=2, ADD => HEX=0009, zapis wyniku do rA.
--      Liczby budujemy metoda CLR + INC (SW[3:0] to jednoczesnie
--      kod operacji i dana DI, wiec nie da sie wpisac liczby wprost).
--      W trybie ALU KEY[0] zapisuje wynik do rejestru wskazanego
--      przez Sbb (SW[5:4]).
--   2) RAM: zapis wartosci pod adres i odczyt z powrotem.
--
-- Testbench jest samosprawdzajacy (assert) i na koncu wypisuje
-- liczbe bledow.
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
    signal KEY  : std_logic_vector(1 downto 0) := (others => '1'); -- aktywne niskim
    signal LEDR : std_logic_vector(9 downto 0);
    signal HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : std_logic_vector(6 downto 0);

    -- Kody wyswietlacza 7-seg (aktywne niskim) - zgodne z hex_display.vhd
    constant SEG0 : std_logic_vector(6 downto 0) := "1000000";
    constant SEG2 : std_logic_vector(6 downto 0) := "0100100";
    constant SEG4 : std_logic_vector(6 downto 0) := "0011001";
    constant SEG5 : std_logic_vector(6 downto 0) := "0010010";
    constant SEG7 : std_logic_vector(6 downto 0) := "1111000";
    constant SEG9 : std_logic_vector(6 downto 0) := "0010000";

begin

    uut: CPU
        port map (
            SW   => SW,
            KEY  => KEY,
            LEDR => LEDR,
            HEX0 => HEX0, HEX1 => HEX1, HEX2 => HEX2,
            HEX3 => HEX3, HEX4 => HEX4, HEX5 => HEX5
        );

    process
        variable errcnt : integer := 0;

        -- jeden impuls zegara: KEY0 1->0->1 (clk = not KEY0, zbocze rosnace gdy KEY0=0)
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
        ----------------------------------------------------------------
        -- RESET
        ----------------------------------------------------------------
        KEY(1) <= '0';  wait for 20 ns;
        KEY(1) <= '1';  wait for 20 ns;

        ----------------------------------------------------------------
        -- rA = 7  (tryb ALU: CLR, potem INC x7; Sbb=rA => cel zapisu rA)
        ----------------------------------------------------------------
        SW <= "0000001010";  -- mode=ALU, Sbb=rA, ALU=CLR
        wait for 10 ns; tick;            -- rA <- 0

        SW <= "0000001101";  -- mode=ALU, Sbb=rA, ALU=INC
        wait for 10 ns;
        for i in 1 to 7 loop tick; end loop;

        SW <= "0000000000";  -- podglad rA (PASS BB, Sbb=rA)
        wait for 20 ns;
        chk_hex(HEX0, SEG7, "rA = 7 (HEX0)");
        chk_hex(HEX1, SEG0, "rA = 0007 (HEX1)");

        ----------------------------------------------------------------
        -- rB = 2  (Sbb=rB => cel zapisu rB)
        ----------------------------------------------------------------
        SW <= "0000011010";  -- mode=ALU, Sbb=rB, ALU=CLR
        wait for 10 ns; tick;            -- rB <- 0

        SW <= "0000011101";  -- mode=ALU, Sbb=rB, ALU=INC
        wait for 10 ns; tick; tick;      -- rB <- 2

        SW <= "0000010000";  -- podglad rB (PASS BB, Sbb=rB)
        wait for 20 ns;
        chk_hex(HEX0, SEG2, "rB = 2 (HEX0)");

        ----------------------------------------------------------------
        -- Podglad ADD: rA + rB = 7 + 2 = 9 (bez zapisu)
        ----------------------------------------------------------------
        SW <= "0001000010";  -- mode=ALU, Sbc=rB, Sbb=rA, ALU=ADD
        wait for 50 ns;
        chk_hex(HEX0, SEG9, "ADD = 9 (HEX0)");
        chk_hex(HEX1, SEG0, "ADD = 0009 (HEX1)");
        chk_hex(HEX2, SEG0, "ADD = 0009 (HEX2)");
        chk_hex(HEX3, SEG0, "ADD = 0009 (HEX3)");
        chk_bit(LEDR(0), '1', "ADD flaga P = 1");
        chk_bit(LEDR(1), '0', "ADD flaga S = 0");
        chk_bit(LEDR(2), '0', "ADD flaga Z = 0");
        chk_bit(LEDR(3), '0', "ADD flaga C = 0");

        ----------------------------------------------------------------
        -- Zapis wyniku ADD do rA (KEY[0] w trybie ALU), potem podglad
        ----------------------------------------------------------------
        SW <= "0001000010";  -- Sbb=rA => cel zapisu rA
        wait for 10 ns; tick;            -- rA <- 9

        SW <= "0000000000";  -- podglad rA
        wait for 20 ns;
        chk_hex(HEX0, SEG9, "rA po zapisie = 9 (HEX0)");

        ----------------------------------------------------------------
        -- RAM: zapis 0x42 pod adres 0x42, potem odczyt
        ----------------------------------------------------------------
        SW <= "0101000010";  -- mode=WRITE, SW[7:0]=0x42 (adres=dana)
        wait for 10 ns; tick;            -- RAM[0x42] <- 0x0042

        SW <= "1001000010";  -- mode=READ, SW[7:0]=0x42
        wait for 30 ns;
        chk_hex(HEX0, SEG2, "RAM[42] low nibble = 2 (HEX0)");
        chk_hex(HEX1, SEG4, "RAM[42] = 0042 (HEX1)");
        chk_hex(HEX5, SEG4, "adres fizyczny [7:4] = 4 (HEX5)");
        chk_hex(HEX4, SEG2, "adres fizyczny [3:0] = 2 (HEX4)");
        chk_bit(LEDR(9), '1', "RD aktywny (LEDR[9])");

        ----------------------------------------------------------------
        -- RAM: zapis 0x05 pod adres 0x05, odczyt
        ----------------------------------------------------------------
        SW <= "0100000101";  -- mode=WRITE, SW[7:0]=0x05
        wait for 10 ns; tick;            -- RAM[5] <- 0x0005

        SW <= "1000000101";  -- mode=READ, SW[7:0]=0x05
        wait for 30 ns;
        chk_hex(HEX0, SEG5, "RAM[5] = 5 (HEX0)");

        ----------------------------------------------------------------
        -- PODSUMOWANIE
        ----------------------------------------------------------------
        if errcnt = 0 then
            report "=== CPU_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== CPU_TB: LICZBA BLEDOW = " & integer'image(errcnt) & " ===" severity error;
        end if;

        wait;
    end process;

end architecture;
