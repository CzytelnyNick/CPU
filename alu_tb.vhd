library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================
-- TESTBENCH JEDNOSTKOWY ALU (samosprawdzajacy)
--
-- Testuje wszystkie 16 operacji oraz cztery flagi (C, Z, S, P)
-- bezposrednio na wejsciach/wyjsciach ALU - niezalezne od reszty
-- procesora. To najwygodniejszy sposob na szybkie wykrycie regresji
-- po zmianach w alu.vhd.
--
-- Konwencja flag (zgodna z alu.vhd):
--   Z = 1 gdy wynik = 0
--   S = wynik(15)  (znak)
--   C = przeniesienie/pozyczka zaleznie od operacji
--   P = 1 gdy PARZYSTA liczba jedynek w wyniku (parity even)
-- =============================================================

entity alu_tb is
end entity;

architecture behavior of alu_tb is

    component alu is
        port (
            clk   : in  STD_LOGIC;
            BB    : in  STD_LOGIC_VECTOR(15 downto 0);
            BC    : in  STD_LOGIC_VECTOR(15 downto 0);
            S_ALU : in  STD_LOGIC_VECTOR(3 downto 0);
            S_F   : in  STD_LOGIC;
            C_in  : in  STD_LOGIC;
            Y     : out STD_LOGIC_VECTOR(15 downto 0);
            C     : out STD_LOGIC;
            Z     : out STD_LOGIC;
            S     : out STD_LOGIC;
            P     : out STD_LOGIC
        );
    end component;

    signal clk   : std_logic := '0';
    signal BB    : std_logic_vector(15 downto 0) := (others => '0');
    signal BC    : std_logic_vector(15 downto 0) := (others => '0');
    signal S_ALU : std_logic_vector(3 downto 0)  := (others => '0');
    signal S_F   : std_logic := '0';
    signal C_in  : std_logic := '0';
    signal Y     : std_logic_vector(15 downto 0);
    signal C, Z, S, P : std_logic;

begin

    uut: alu
        port map (
            clk => clk, BB => BB, BC => BC, S_ALU => S_ALU,
            S_F => S_F, C_in => C_in, Y => Y, C => C, Z => Z, S => S, P => P
        );

    process
        variable errcnt : integer := 0;

        -- ustaw wejscia, odczekaj na ustalenie (ALU jest kombinacyjne)
        -- i porownaj wynik oraz wszystkie flagi z oczekiwanymi
        procedure t(bbv : in std_logic_vector(15 downto 0);
                    bcv : in std_logic_vector(15 downto 0);
                    op  : in std_logic_vector(3 downto 0);
                    cin : in std_logic;
                    ey  : in std_logic_vector(15 downto 0);
                    ec, ez, es, ep : in std_logic;
                    nm  : in string) is
        begin
            BB    <= bbv;
            BC    <= bcv;
            S_ALU <= op;
            C_in  <= cin;
            wait for 10 ns;

            if Y /= ey then
                report "FAIL [" & nm & "] Y: got=" & integer'image(to_integer(unsigned(Y)))
                     & " exp=" & integer'image(to_integer(unsigned(ey))) severity error;
                errcnt := errcnt + 1;
            end if;
            if C /= ec then
                report "FAIL [" & nm & "] flaga C" severity error; errcnt := errcnt + 1;
            end if;
            if Z /= ez then
                report "FAIL [" & nm & "] flaga Z" severity error; errcnt := errcnt + 1;
            end if;
            if S /= es then
                report "FAIL [" & nm & "] flaga S" severity error; errcnt := errcnt + 1;
            end if;
            if P /= ep then
                report "FAIL [" & nm & "] flaga P" severity error; errcnt := errcnt + 1;
            end if;
        end procedure;
    begin
        --    BB        BC        op       cin   Y         C   Z   S   P    nazwa
        t(x"1234", x"0000", "0000", '0', x"1234", '0','0','0','0', "PASS BB");
        t(x"0000", x"00FF", "0001", '0', x"00FF", '0','0','0','1', "PASS BC");

        t(x"0007", x"0002", "0010", '0', x"0009", '0','0','0','1', "ADD 7+2");
        t(x"FFFF", x"0001", "0010", '0', x"0000", '1','1','0','1', "ADD przepelnienie");

        t(x"0007", x"0002", "0011", '0', x"0005", '0','0','0','1', "SUB 7-2");
        t(x"0002", x"0007", "0011", '0', x"FFFB", '1','0','1','0', "SUB 2-7 (pozyczka)");

        t(x"0007", x"0002", "0100", '0', x"0007", '0','0','0','0', "OR");
        t(x"0007", x"0002", "0101", '0', x"0002", '0','0','0','0', "AND");
        t(x"0007", x"0002", "0110", '0', x"0005", '0','0','0','1', "XOR");
        t(x"0007", x"0002", "0111", '0', x"FFFA", '0','0','1','1', "XNOR");

        t(x"0007", x"0000", "1000", '0', x"FFF8", '0','0','1','0', "NOT 7");
        t(x"0007", x"0000", "1001", '0', x"FFF9", '0','0','1','1', "NEG 7");

        t(x"1234", x"5678", "1010", '0', x"0000", '0','1','0','1', "CLR");

        t(x"0007", x"0002", "1011", '1', x"000A", '0','0','0','1', "ADC 7+2+1");
        t(x"0007", x"0002", "1100", '1', x"0004", '0','0','0','0', "SBB 7-2-1");

        t(x"0007", x"0000", "1101", '0', x"0008", '0','0','0','0', "INC 7");

        t(x"0007", x"0000", "1110", '0', x"000E", '0','0','0','0', "SHL 7");
        t(x"8000", x"0000", "1110", '0', x"0000", '1','1','0','1', "SHL 0x8000 (carry)");

        t(x"0007", x"0000", "1111", '0', x"0003", '1','0','0','1', "SHR 7");
        t(x"0001", x"0000", "1111", '0', x"0000", '1','1','0','1', "SHR 1 (carry, zero)");

        ----------------------------------------------------------------
        -- PODSUMOWANIE
        ----------------------------------------------------------------
        if errcnt = 0 then
            report "=== ALU_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== ALU_TB: LICZBA BLEDOW = " & integer'image(errcnt) & " ===" severity error;
        end if;

        wait;
    end process;

end architecture;
