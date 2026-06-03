library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================
-- TESTBENCH JEDNOSTKOWY PAMIECI RAM (samosprawdzajacy)
--
-- Testuje modul ram.vhd niezaleznie od reszty procesora:
--   - synchroniczny zapis (zbocze rosnace clk, gdy we = '1')
--   - asynchroniczny odczyt (q zmienia sie od razu po zmianie address)
--   - blokada zapisu gdy we = '0'
--   - nadpisanie tej samej komorki
--   - niezaleznosc komorek (zapis pod jeden adres nie psuje innych)
--   - adresy graniczne 0 oraz 1023
--
-- UWAGA: plik ram_init.mif jest ladowany tylko przez Quartus/sprzet.
-- W czystej symulacji pamiec startuje nieokreslona ('U'), dlatego
-- KAZDA komorka jest najpierw zapisywana, a dopiero potem czytana.
-- =============================================================

entity ram_tb is
end entity;

architecture behavior of ram_tb is

    component ram is
        port (
            clk     : in  std_logic;
            we      : in  std_logic;
            address : in  std_logic_vector(9 downto 0);
            data    : in  std_logic_vector(15 downto 0);
            q       : out std_logic_vector(15 downto 0)
        );
    end component;

    signal clk     : std_logic := '0';
    signal we      : std_logic := '0';
    signal address : std_logic_vector(9 downto 0)  := (others => '0');
    signal data    : std_logic_vector(15 downto 0) := (others => '0');
    signal q       : std_logic_vector(15 downto 0);

begin

    uut: ram
        port map (
            clk     => clk,
            we      => we,
            address => address,
            data    => data,
            q       => q
        );

    process
        variable errcnt : integer := 0;

        -- zapis synchroniczny: ustaw adres/dane, we='1', pojedyncze zbocze clk
        procedure wr(addr : in integer;
                     val  : in std_logic_vector(15 downto 0)) is
        begin
            address <= std_logic_vector(to_unsigned(addr, 10));
            data    <= val;
            we      <= '1';
            clk     <= '0';
            wait for 5 ns;
            clk     <= '1';   -- zbocze rosnace => zapis
            wait for 5 ns;
            we      <= '0';
            clk     <= '0';
            wait for 5 ns;
        end procedure;

        -- proba zapisu przy we='0' (powinna byc zignorowana)
        procedure wr_disabled(addr : in integer;
                              val  : in std_logic_vector(15 downto 0)) is
        begin
            address <= std_logic_vector(to_unsigned(addr, 10));
            data    <= val;
            we      <= '0';
            clk     <= '0';
            wait for 5 ns;
            clk     <= '1';   -- zbocze rosnace, ale we=0 => brak zapisu
            wait for 5 ns;
            clk     <= '0';
            wait for 5 ns;
        end procedure;

        -- odczyt asynchroniczny: ustaw adres i sprawdz q
        procedure rd_chk(addr : in integer;
                         exp  : in std_logic_vector(15 downto 0);
                         name : in string) is
        begin
            address <= std_logic_vector(to_unsigned(addr, 10));
            we      <= '0';
            wait for 5 ns;
            if q /= exp then
                report "FAIL [" & name & "] q: got=" & integer'image(to_integer(unsigned(q)))
                     & " exp=" & integer'image(to_integer(unsigned(exp))) severity error;
                errcnt := errcnt + 1;
            else
                report "PASS [" & name & "]" severity note;
            end if;
        end procedure;
    begin
        ------------------------------------------------------------
        -- Podstawowy zapis + odczyt
        ------------------------------------------------------------
        wr(10, x"ABCD");
        rd_chk(10, x"ABCD", "zapis/odczyt adr=10");

        ------------------------------------------------------------
        -- Adresy graniczne
        ------------------------------------------------------------
        wr(0,    x"1234");
        rd_chk(0, x"1234", "adres graniczny 0");

        wr(1023, x"FFFF");
        rd_chk(1023, x"FFFF", "adres graniczny 1023");

        ------------------------------------------------------------
        -- Niezaleznosc komorek - poprzednie zapisy maja byc nienaruszone
        ------------------------------------------------------------
        rd_chk(10, x"ABCD", "adr=10 nienaruszony po zapisach 0 i 1023");
        rd_chk(0,  x"1234", "adr=0 nienaruszony po zapisie 1023");

        ------------------------------------------------------------
        -- Blokada zapisu gdy we='0'
        ------------------------------------------------------------
        wr_disabled(10, x"0000");   -- proba wyzerowania adr=10 bez we
        rd_chk(10, x"ABCD", "we=0 nie nadpisuje adr=10");

        ------------------------------------------------------------
        -- Nadpisanie tej samej komorki
        ------------------------------------------------------------
        wr(10, x"5555");
        rd_chk(10, x"5555", "nadpisanie adr=10");

        ------------------------------------------------------------
        -- Dwie sasiednie komorki segmentu (segment 1: 256..511)
        ------------------------------------------------------------
        wr(256, x"0F0F");
        wr(257, x"F0F0");
        rd_chk(256, x"0F0F", "segment 1 adr=256");
        rd_chk(257, x"F0F0", "segment 1 adr=257");

        ------------------------------------------------------------
        -- PODSUMOWANIE
        ------------------------------------------------------------
        if errcnt = 0 then
            report "=== RAM_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== RAM_TB: LICZBA BLEDOW = " & integer'image(errcnt) & " ===" severity error;
        end if;

        wait;
    end process;

end architecture;
