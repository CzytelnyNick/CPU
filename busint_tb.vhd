library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================
-- TESTBENCH JEDNOSTKOWY UKLADU WSPOLPRACY Z PAMIECIA (busint)
--
-- busint to "jednostka sterujaca" dostepem do pamieci: zawiera
-- rejestry MAR / MBR, przelicza adres logiczny na fizyczny i
-- steruje dwukierunkowa szyna danych D oraz sygnalami WR / RD.
--
-- Testowane sa kolejno:
--   1. Przeliczanie adresu logicznego -> fizycznego (phys_addr_out)
--   2. Zaladowanie MAR (Smar) i wystawienie adresu na AD
--   3. Sciezka ZAPISU: Smbr laduje MBRout z DO, a WRin wystawia
--      MBRout na szyne D (oraz WR='1')
--   4. Trojstan szyny: gdy WRin='0', busint zwalnia D (wysokie Z)
--   5. Sciezka ODCZYTU: testbench wystawia dane na D, RDin zatrzaskuje
--      je w MBRin, a busint podaje je na DI
--   6. Przekazywanie sygnalow WR / RD
-- =============================================================

entity busint_tb is
end entity;

architecture behavior of busint_tb is

    component busint is
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
    end component;

    signal clk           : std_logic := '0';
    signal ADR           : signed(31 downto 0) := (others => '0');
    signal DO            : signed(15 downto 0) := (others => '0');
    signal Smar          : std_logic := '0';
    signal Smbr          : std_logic := '0';
    signal WRin          : std_logic := '0';
    signal RDin          : std_logic := '0';
    signal AD            : signed(31 downto 0);
    signal D             : signed(15 downto 0);   -- inout, wspoldzielona szyna
    signal DI            : signed(15 downto 0);
    signal WR            : std_logic;
    signal RD            : std_logic;
    signal phys_addr_out : std_logic_vector(9 downto 0);

    constant HIZ : signed(15 downto 0) := (others => 'Z');

begin

    uut: busint
        port map (
            clk           => clk,
            ADR           => ADR,
            DO            => DO,
            Smar          => Smar,
            Smbr          => Smbr,
            WRin          => WRin,
            RDin          => RDin,
            AD            => AD,
            D             => D,
            DI            => DI,
            WR            => WR,
            RD            => RD,
            phys_addr_out => phys_addr_out
        );

    -- Domyslnie testbench NIE napedza szyny D (zostawia 'Z'),
    -- dzieki czemu busint moze nia sterowac. Dla testu odczytu
    -- testbench chwilowo wystawia na nia wartosc (ponizej w procesie).
    process
        variable errcnt : integer := 0;

        -- pojedyncze zbocze rosnace zegara
        procedure tick is
        begin
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
            clk <= '0';
            wait for 5 ns;
        end procedure;

        procedure chk_slv(got  : in std_logic_vector;
                          exp  : in std_logic_vector;
                          name : in string) is
        begin
            if got /= exp then
                report "FAIL [" & name & "]" severity error;
                errcnt := errcnt + 1;
            else
                report "PASS [" & name & "]" severity note;
            end if;
        end procedure;

        procedure chk_signed(got  : in signed;
                             exp  : in signed;
                             name : in string) is
        begin
            if got /= exp then
                report "FAIL [" & name & "] got=" & integer'image(to_integer(got))
                     & " exp=" & integer'image(to_integer(exp)) severity error;
                errcnt := errcnt + 1;
            else
                report "PASS [" & name & "]" severity note;
            end if;
        end procedure;

        procedure chk_bit(got : in std_logic;
                          exp : in std_logic;
                          name : in string) is
        begin
            if got /= exp then
                report "FAIL [" & name & "]" severity error;
                errcnt := errcnt + 1;
            else
                report "PASS [" & name & "]" severity note;
            end if;
        end procedure;
    begin
        -- Testbench domyslnie zwalnia szyne D (wysokie Z), aby
        -- nie kolidowac z driverem busint. Wartosc wystawiamy tylko
        -- na czas testu odczytu.
        D <= HIZ;
        wait for 5 ns;

        ------------------------------------------------------------
        -- 1. Przeliczanie adresu logicznego -> fizycznego
        --    phys_addr = ADR(9:8) (segment) & ADR(7:0) (offset)
        --    ADR = 0x...0345 => segment=11, offset=0x45 => phys=0x345
        ------------------------------------------------------------
        ADR <= to_signed(16#0345#, 32);
        wait for 5 ns;
        chk_slv(phys_addr_out, "1101000101", "phys_addr 0x345 (seg=3, off=0x45)");

        ADR <= to_signed(16#0100#, 32);   -- segment 1, offset 0
        wait for 5 ns;
        chk_slv(phys_addr_out, "0100000000", "phys_addr 0x100 (seg=1, off=0)");

        ------------------------------------------------------------
        -- 2. Zaladowanie MAR i wystawienie adresu na AD
        ------------------------------------------------------------
        ADR  <= to_signed(16#0345#, 32);
        wait for 5 ns;
        Smar <= '1';
        tick;                  -- MAR <- phys_addr (rozszerzony do 32-bit)
        Smar <= '0';
        wait for 5 ns;
        chk_signed(AD, to_signed(16#0345#, 32), "MAR/AD = 0x345 po Smar");

        ------------------------------------------------------------
        -- 3. Sciezka ZAPISU: Smbr laduje MBRout, WRin wystawia na D
        ------------------------------------------------------------
        DO   <= to_signed(16#BEEF#, 16);
        wait for 5 ns;
        Smbr <= '1';
        tick;                  -- MBRout <- DO (0xBEEF)
        Smbr <= '0';
        WRin <= '1';
        wait for 5 ns;
        chk_signed(D, to_signed(16#BEEF#, 16), "WRin=1 wystawia MBRout (0xBEEF) na D");
        chk_bit(WR, '1', "WR = 1 podczas zapisu");

        ------------------------------------------------------------
        -- 4. Trojstan: WRin=0 => busint zwalnia szyne D (wysokie Z)
        ------------------------------------------------------------
        WRin <= '0';
        wait for 5 ns;
        chk_slv(std_logic_vector(D), std_logic_vector(HIZ), "WRin=0 zwalnia szyne D (Z)");
        chk_bit(WR, '0', "WR = 0 gdy brak zapisu");

        ------------------------------------------------------------
        -- 5. Sciezka ODCZYTU: testbench wystawia dane na D, RDin
        --    zatrzaskuje je w MBRin, busint podaje je na DI
        ------------------------------------------------------------
        D    <= to_signed(16#1357#, 16);   -- model pamieci wystawia dane
        RDin <= '1';
        wait for 5 ns;
        tick;                  -- MBRin <- D (0x1357)
        RDin <= '0';
        D    <= HIZ;           -- testbench zwalnia szyne
        wait for 5 ns;
        chk_signed(DI, to_signed(16#1357#, 16), "RDin: DI = dane z szyny (0x1357)");

        ------------------------------------------------------------
        -- 6. Przekazywanie sygnalu RD
        ------------------------------------------------------------
        RDin <= '1';
        wait for 5 ns;
        chk_bit(RD, '1', "RD = 1 gdy RDin = 1");
        RDin <= '0';
        D    <= HIZ;
        wait for 5 ns;
        chk_bit(RD, '0', "RD = 0 gdy RDin = 0");

        ------------------------------------------------------------
        -- PODSUMOWANIE
        ------------------------------------------------------------
        if errcnt = 0 then
            report "=== BUSINT_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== BUSINT_TB: LICZBA BLEDOW = " & integer'image(errcnt) & " ===" severity error;
        end if;

        wait;
    end process;

end architecture;
