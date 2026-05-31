library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================
-- TESTBENCH PAMIECI RAM
--
-- Testuje bezposrednio modul ram.vhd:
--   - zapis synchroniczny na zboczu rosnacym,
--   - odczyt asynchroniczny,
--   - kilka adresow z roznych fragmentow 10-bitowej przestrzeni,
--   - nadpisanie komorki bez psucia sasiedniego adresu.
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
    signal address : std_logic_vector(9 downto 0) := (others => '0');
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

        procedure tick is
        begin
            clk <= '1';
            wait for 10 ns;
            clk <= '0';
            wait for 10 ns;
        end procedure;

        procedure write_word(addr : in std_logic_vector(9 downto 0);
                             val  : in std_logic_vector(15 downto 0);
                             name : in string) is
        begin
            address <= addr;
            data    <= val;
            we      <= '1';
            wait for 5 ns;
            tick;
            we      <= '0';
            wait for 5 ns;
            report "WRITE: " & name severity note;
        end procedure;

        procedure read_expect(addr : in std_logic_vector(9 downto 0);
                              exp  : in std_logic_vector(15 downto 0);
                              name : in string) is
        begin
            address <= addr;
            we      <= '0';
            wait for 10 ns;
            if q /= exp then
                report "FAIL: " & name severity error;
                errcnt := errcnt + 1;
            else
                report "PASS: " & name severity note;
            end if;
        end procedure;
    begin
        -- Zapis do kilku adresow: poczatek, adres programu/danych, koniec RAM.
        write_word("0000000000", x"4407", "addr 0x000 = 4407");
        write_word("0000100000", x"0012", "addr 0x020 = 0012");
        write_word("0100000000", x"ABCD", "addr 0x100 = ABCD");
        write_word("1111111111", x"FFFF", "addr 0x3FF = FFFF");

        read_expect("0000000000", x"4407", "read addr 0x000");
        read_expect("0000100000", x"0012", "read addr 0x020");
        read_expect("0100000000", x"ABCD", "read addr 0x100");
        read_expect("1111111111", x"FFFF", "read addr 0x3FF");

        -- Nadpisanie komorki 0x020 i kontrola sasiedniego adresu 0x021.
        write_word("0000100001", x"2222", "addr 0x021 = 2222");
        write_word("0000100000", x"1234", "overwrite addr 0x020 = 1234");
        read_expect("0000100000", x"1234", "read overwritten addr 0x020");
        read_expect("0000100001", x"2222", "neighbor addr 0x021 unchanged");

        if errcnt = 0 then
            report "=== RAM_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== RAM_TB: LICZBA BLEDOW = " & integer'image(errcnt) & " ===" severity error;
        end if;

        wait;
    end process;

end architecture;
