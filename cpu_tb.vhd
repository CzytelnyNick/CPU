library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================
-- TESTBENCH POZIOMU SYSTEMU (end-to-end) dla CPU
--
-- Steruje wylacznie portami zewnetrznymi (SW, KEY) i sprawdza
-- wyjscia HEX/LEDR - dokladnie tak jak na plytce.
--
-- WAZNE: nie da sie wpisac liczby bezposrednio przez SW, bo
-- SW[3:0] pelni JEDNOCZESNIE role kodu operacji ALU i wartosci DI.
-- Dlatego (zgodnie z README.md) liczby budujemy metoda CLR + INC.
--
-- Scenariusz: rA = 7, rB = 2, podglad ADD => HEX = 0009.
-- Testbench jest samosprawdzajacy (assert) i na koncu wypisuje
-- podsumowanie liczby bledow.
--
-- WAZNE: wynik ALU jest zatrzaskiwany w rejestrze wyniku na zboczu
-- zegara (klikniecie KEY[0]). Dlatego KAZDE sprawdzenie HEX jest
-- poprzedzone jednym impulsem zegara (tick), ktory zatrzaskuje wynik
-- na wyswietlaczu - dokladnie tak jak na plytce.
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

    -- Sygnaly testowe
    signal SW   : std_logic_vector(9 downto 0) := (others => '0');
    signal KEY  : std_logic_vector(1 downto 0) := (others => '1'); -- aktywne niskim
    signal LEDR : std_logic_vector(9 downto 0);
    signal HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : std_logic_vector(6 downto 0);

    -- Kody wyswietlacza 7-seg (aktywne niskim) - zgodne z hex_display.vhd
    constant SEG0 : std_logic_vector(6 downto 0) := "1000000";
    constant SEG2 : std_logic_vector(6 downto 0) := "0100100";
    constant SEG7 : std_logic_vector(6 downto 0) := "1111000";
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
        KEY(1) <= '0';  -- reset aktywny
        wait for 20 ns;
        KEY(1) <= '1';  -- zwolnienie resetu
        wait for 20 ns;

        ----------------------------------------------------------------
        -- rA = 7  (CLR, potem INC x7)
        ----------------------------------------------------------------
        SW <= "0100001010";  -- DST=rA, WEN=1, Sbb=rA, ALU=1010 (CLR)
        wait for 10 ns;
        tick;                -- rA <- 0

        SW <= "0100001101";  -- DST=rA, WEN=1, Sbb=rA, ALU=1101 (INC)
        wait for 10 ns;
        for i in 1 to 7 loop
            tick;            -- rA <- rA + 1
        end loop;

        -- Podglad rA (PASS BB, Sbb=rA, WEN=0): HEX0 powinno = 7
        -- Wynik pojawia sie na HEX dopiero po zatrzasnieciu (tick).
        SW <= "0000000000";
        wait for 20 ns;
        tick;                -- zatrzask wyniku na wyswietlacz
        chk_hex(HEX0, SEG7, "rA = 7 (HEX0)");
        chk_hex(HEX1, SEG0, "rA high nibble = 0 (HEX1)");

        ----------------------------------------------------------------
        -- rB = 2  (CLR, potem INC x2)
        ----------------------------------------------------------------
        SW <= "1100001010";  -- DST=rB, WEN=1, Sbb=rA, ALU=1010 (CLR)
        wait for 10 ns;
        tick;                -- rB <- 0

        SW <= "1100011101";  -- DST=rB, WEN=1, Sbb=rB, ALU=1101 (INC)
        wait for 10 ns;
        tick;
        tick;                -- rB <- 2

        -- Podglad rB (PASS BB, Sbb=rB, WEN=0): HEX0 powinno = 2
        SW <= "0000010000";
        wait for 20 ns;
        tick;                -- zatrzask wyniku na wyswietlacz
        chk_hex(HEX0, SEG2, "rB = 2 (HEX0)");

        ----------------------------------------------------------------
        -- Podglad ADD: rA + rB = 7 + 2 = 9 (bez zapisu)
        -- WEN=0, wiec klikniecie tylko zatrzaskuje wynik na HEX,
        -- nie zapisuje go do zadnego rejestru.
        ----------------------------------------------------------------
        SW <= "0001000010";  -- WEN=0, Sbc=rB, Sbb=rA, ALU=0010 (ADD)
        wait for 50 ns;
        tick;                -- zatrzask wyniku na wyswietlacz

        chk_hex(HEX0, SEG9, "ADD wynik low nibble = 9 (HEX0)");
        chk_hex(HEX1, SEG0, "ADD wynik = 0009 (HEX1)");
        chk_hex(HEX2, SEG0, "ADD wynik = 0009 (HEX2)");
        chk_hex(HEX3, SEG0, "ADD wynik = 0009 (HEX3)");

        -- flagi: LEDR(0)=P, LEDR(1)=S, LEDR(2)=Z, LEDR(3)=C
        chk_bit(LEDR(0), '1', "ADD flaga P = 1");
        chk_bit(LEDR(1), '0', "ADD flaga S = 0");
        chk_bit(LEDR(2), '0', "ADD flaga Z = 0");
        chk_bit(LEDR(3), '0', "ADD flaga C = 0");

        ----------------------------------------------------------------
        -- Zapis wyniku ADD do rA, a potem podglad => rA = 9
        ----------------------------------------------------------------
        SW <= "0101000010";  -- WEN=1, DST=rA, Sbc=rB, Sbb=rA, ALU=ADD
        wait for 10 ns;
        tick;                -- rA <- 9 (zapis) i zatrzask wyniku na HEX

        SW <= "0000000000";  -- podglad rA (PASS BB)
        wait for 20 ns;
        tick;                -- zatrzask wyniku na wyswietlacz
        chk_hex(HEX0, SEG9, "rA po zapisie = 9 (HEX0)");

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
