library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- LAB 3: Uklad wspolpracy z pamiecia (busint)
--
-- Oparty na przykladzie z dokumentacji laboratorium.
-- Zawiera rejestry MAR i MBR oraz obsluge szyny dwukierunkowej.
--
-- Segmentacja pamieci:
--   - 4 segmenty (2 bity numeru segmentu)
--   - 8 bitow przesuniecia (offset)
--   - Adres fizyczny (10-bit) = segment << 8 + offset
--   - Pobierane z ADR (32-bit):
--       ADR(9 downto 8) = numer segmentu
--       ADR(7 downto 0) = offset
--
-- Wejscia:
--   clk        - zegar
--   ADR        - adres logiczny z pliku rejestrow (32-bit)
--   DO         - dane wyjsciowe do pamieci (16-bit)
--   Smar       - 1 = zaladuj MAR z ADR
--   Smbr       - 1 = zaladuj MBRout z DO
--   WRin       - zapis do pamieci
--   RDin       - odczyt z pamieci
--
-- Wyjscia:
--   AD         - adres fizyczny na szyne adresowa (32-bit)
--   D          - szyna danych dwukierunkowa (16-bit)
--   DI         - dane odczytane z pamieci (do pliku rejestrow)
--   WR, RD     - sygnaly sterujace pamiecia
--   phys_addr_out - adres fizyczny 10-bit (do wyswietlacza)
-- =============================================================

entity busint is
    port (
        clk           : in    std_logic;
        ADR           : in    signed(31 downto 0);
        DO            : in    signed(15 downto 0);
        Smar          : in    std_logic;
        Smbr          : in    std_logic;
        WRin          : in    std_logic;
        RDin          : in    std_logic;
        AD            : out   signed(31 downto 0);
        D             : inout signed(15 downto 0);
        DI            : out   signed(15 downto 0);
        WR            : out   std_logic;
        RD            : out   std_logic;
        phys_addr_out : out   std_logic_vector(9 downto 0)
    );
end entity busint;

architecture rtl of busint is

    signal phys_addr : unsigned(9 downto 0) := (others => '0');

begin

    -- --------------------------------------------------------
    -- Przeliczanie adresu logicznego -> fizycznego
    -- Adres fizyczny = segment(1:0) << 8 + offset(7:0)
    -- --------------------------------------------------------
    phys_addr <= unsigned(ADR(9 downto 8)) & unsigned(ADR(7 downto 0));

    phys_addr_out <= std_logic_vector(phys_addr);

    -- --------------------------------------------------------
    -- Proces - na wzor z dokumentacji laboratorium
    -- --------------------------------------------------------
    process(clk, Smar, ADR, Smbr, DO, D, WRin, RDin)
        variable MBRin  : signed(15 downto 0) := (others => '0');
        variable MBRout : signed(15 downto 0) := (others => '0');
        variable MAR    : signed(31 downto 0) := (others => '0');
    begin

        -- Synchroniczny zapis MAR i MBR (zbocze rosnace)
        if (clk'event and clk = '1') then
            if Smar = '1' then
                MAR := signed("0000000000000000000000" & phys_addr);
            end if;
            if Smbr = '1' then
                MBRout := DO;
            end if;
            if RDin = '1' then
                MBRin := D;
            end if;
        end if;

        -- Szyna danych dwukierunkowa
        if WRin = '1' then
            D <= MBRout;
        else
            D <= "ZZZZZZZZZZZZZZZZ";
        end if;

        DI <= MBRin;
        AD <= MAR;
        WR <= WRin;
        RD <= RDin;

    end process;

end architecture rtl;