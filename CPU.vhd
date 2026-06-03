library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- TOP-LEVEL: ALU + Plik Rejestrow + busint + RAM + HEX
--
-- Przyciski (aktywne NISKIE na DE1/DE2):
--   KEY[0] - reczny zegar CLK
--   KEY[1] - reset asynchroniczny (zeruje wszystkie rejestry)
--
-- Nowe mapowanie przelacznikow:
--
--   SW[3:0] - S_ALU : kod operacji ALU
--   SW[5:4] - Sbb   : wybor rejestru BB (arg1 ALU)
--                     00=rA, 01=rB, 10=rC, 11=DI
--   SW[7:6] - Sbc   : wybor rejestru BC (arg2 ALU)
--                     00=rA, 01=rB, 10=rC, 11=DI
--   SW[8]   - WEN   : 1 = zapisz wynik ALU do rejestru docelowego
--                     (zapis nastepuje na zbocze KEY[0])
--   SW[9]   - DST   : wybor rejestru docelowego zapisu
--                     0=rA, 1=rB
--
-- Wyjscia HEX:
--   HEX1..HEX0 - wynik ALU [7:0]   (2 cyfry hex)
--   HEX3..HEX2 - wynik ALU [15:8]  (2 cyfry hex)
--   HEX4       - flagi {C, Z, S, P}
--   HEX5       - kod operacji S_ALU
--
-- Wyjscia LED:
--   LEDR[0] = P  flaga parzystosci
--   LEDR[1] = S  flaga znaku
--   LEDR[2] = Z  flaga zera
--   LEDR[3] = C  flaga przeniesienia
--   LEDR[4] = WEN aktywny (zapis do rejestru)
--   LEDR[5] = DST (0=rA, 1=rB)
--   LEDR[7:6] = Sbb (wybrany rejestr BB)
--   LEDR[9:8] = Sbc (wybrany rejestr BC)
--
-- Przyklad uzycia - dodawanie 7 + 2:
--   1. Wpisz 7 do rA:
--      SW = 0100000111  (DST=0=rA, WEN=1, Sbc=00, Sbb=11=DI, S_ALU=0111=PASS BB)
--      KEY[0]: 1->0->1  (zbocze = zapis rA=7)
--   2. Wpisz 2 do rB:
--      SW = 1100000001  (DST=1=rB, WEN=1, Sbc=00, Sbb=11=DI, S_ALU=0001=PASS BC)
--      UWAGA: tu DI=SW[3:0]=0010, ale PASS BC bierze BC...
--      Latwiej: SW = 1100110010 (DST=rB, WEN=1, Sbc=11=DI, Sbb=00, S_ALU=0001=PASS BC)
--      KEY[0]: 1->0->1
--   3. Oblicz rA + rB:
--      SW = 0001010010  (DST=rA, WEN=0, Sbc=01=rB, Sbb=00=rA, S_ALU=0010=ADD)
--      Kliknij KEY[0] - wynik operacji zostanie zatrzasniety i pojawi
--      sie na HEX (operacja wykonuje sie na zboczu zegara).
--
-- WAZNE: wynik ALU pojawia sie na HEX DOPIERO po kliknieciu KEY[0].
-- Sam wybor operacji przelacznikami nie zmienia jeszcze wyswietlacza.
-- =============================================================

entity CPU is
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
end entity CPU;

architecture rtl of CPU is

    ----------------------------------------------------------------
    -- KOMPONENTY
    ----------------------------------------------------------------

    component alu is
        port (
            clk   : in  std_logic;
            BB    : in  std_logic_vector(15 downto 0);
            BC    : in  std_logic_vector(15 downto 0);
            S_ALU : in  std_logic_vector(3 downto 0);
            S_F   : in  std_logic;
            C_in  : in  std_logic;
            Y     : out std_logic_vector(15 downto 0);
            C     : out std_logic;
            Z     : out std_logic;
            S     : out std_logic;
            P     : out std_logic
        );
    end component;

    component register_cpu is
        port (
            clk   : in  std_logic;
            reset : in  std_logic;
            DI    : in  signed(15 downto 0);
            BA    : in  signed(15 downto 0);
            Sbb   : in  signed(3 downto 0);
            Sbc   : in  signed(3 downto 0);
            Sba   : in  signed(3 downto 0);
            Sid   : in  signed(2 downto 0);
            Sa    : in  signed(1 downto 0);
            BB    : out signed(15 downto 0);
            BC    : out signed(15 downto 0);
            ADR   : out signed(31 downto 0);
            IRout : out signed(15 downto 0)
        );
    end component;

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

    component ram is
        port (
            clk     : in  std_logic;
            we      : in  std_logic;
            address : in  std_logic_vector(9 downto 0);
            data    : in  std_logic_vector(15 downto 0);
            q       : out std_logic_vector(15 downto 0)
        );
    end component;

    component hex_display is
        port (
            hex_in  : in  std_logic_vector(3 downto 0);
            seg_out : out std_logic_vector(6 downto 0)
        );
    end component;

    ----------------------------------------------------------------
    -- SYGNALY
    ----------------------------------------------------------------

    signal clk   : std_logic;
    signal reset : std_logic;

    -- sterowanie
    signal wen   : std_logic;                    -- SW[8]: write enable
    signal dst   : std_logic;                    -- SW[9]: rejestr docelowy
    signal s_sbb : std_logic_vector(1 downto 0); -- SW[5:4]: wybor BB
    signal s_sbc : std_logic_vector(1 downto 0); -- SW[7:6]: wybor BC

    -- plik rejestrow
    signal reg_BB  : signed(15 downto 0);
    signal reg_BC  : signed(15 downto 0);
    signal reg_ADR : signed(31 downto 0);
    signal reg_IR  : signed(15 downto 0);
    signal reg_DI  : signed(15 downto 0);
    signal reg_BA  : signed(15 downto 0);
    signal reg_Sbb : signed(3 downto 0);
    signal reg_Sbc : signed(3 downto 0);
    signal reg_Sba : signed(3 downto 0);
    signal reg_Sid : signed(2 downto 0);
    signal reg_Sa  : signed(1 downto 0);

    -- ALU
    signal alu_BB : std_logic_vector(15 downto 0);
    signal alu_BC : std_logic_vector(15 downto 0);
    signal alu_Y  : std_logic_vector(15 downto 0);
    signal alu_C  : std_logic;
    signal alu_Z  : std_logic;
    signal alu_S  : std_logic;
    signal alu_P  : std_logic;

    -- busint (nieuzywany aktywnie, ale podlaczony)
    signal bus_AD   : signed(31 downto 0);
    signal bus_D    : signed(15 downto 0);
    signal bus_DI   : signed(15 downto 0);
    signal bus_WR   : std_logic;
    signal bus_RD   : std_logic;
    signal phys_addr: std_logic_vector(9 downto 0);
    signal ram_data_out : std_logic_vector(15 downto 0);

    -- flagi
    signal flags_nibble : std_logic_vector(3 downto 0);

    -- rejestr wyniku (zatrzask na zboczu zegara - klikniecie KEY[0])
    signal disp_Y  : std_logic_vector(15 downto 0) := (others => '0');
    signal disp_C  : std_logic := '0';
    signal disp_Z  : std_logic := '0';
    signal disp_S  : std_logic := '0';
    signal disp_P  : std_logic := '0';
    signal disp_op : std_logic_vector(3 downto 0) := (others => '0');

begin

    ----------------------------------------------------------------
    -- ZEGAR I RESET
    ----------------------------------------------------------------

    clk   <= not KEY(0);   -- KEY aktywny NISKI
    reset <= not KEY(1);

    ----------------------------------------------------------------
    -- DEKODOWANIE PRZELACZNIKOW
    ----------------------------------------------------------------

    wen   <= SW(8);
    dst   <= SW(9);
    s_sbb <= SW(5 downto 4);
    s_sbc <= SW(7 downto 6);

    -- DI: dane z przelacznikow SW[3:0] rozszerzone do 16-bit
    -- uzywane gdy Sbb lub Sbc = "11" (DI)
    reg_DI <= signed(x"000" & SW(3 downto 0));

    ----------------------------------------------------------------
    -- Sbb: wybor rejestru BB (arg1 ALU)
    --   00 -> 0010 = rA
    --   01 -> 0011 = rB
    --   10 -> 0100 = rC
    --   11 -> 0000 = DI (dane z SW[3:0])
    ----------------------------------------------------------------
    reg_Sbb <= "0010" when s_sbb = "00" else
               "0011" when s_sbb = "01" else
               "0100" when s_sbb = "10" else
               "0000";  -- DI

    ----------------------------------------------------------------
    -- Sbc: wybor rejestru BC (arg2 ALU)
    --   00 -> 0010 = rA
    --   01 -> 0011 = rB
    --   10 -> 0100 = rC
    --   11 -> 0000 = DI (dane z SW[3:0])
    ----------------------------------------------------------------
    reg_Sbc <= "0010" when s_sbc = "00" else
               "0011" when s_sbc = "01" else
               "0100" when s_sbc = "10" else
               "0000";  -- DI

    ----------------------------------------------------------------
    -- Sba: rejestr docelowy zapisu
    -- Zapis tylko gdy WEN=1, inaczej wskazuje na ATMP (ukryty)
    --   WEN=1, DST=0 -> 0010 = rA
    --   WEN=1, DST=1 -> 0011 = rB
    --   WEN=0        -> 1111 = ATMP (ukryty, nie psuje rejestrow)
    ----------------------------------------------------------------
    reg_Sba <= "0010" when (wen = '1' and dst = '0') else
               "0011" when (wen = '1' and dst = '1') else
               "1111";  -- ATMP - zapis niewidoczny dla uzytkownika

    -- BA: wynik ALU idzie do rejestru docelowego
    reg_BA  <= signed(alu_Y);

    -- Sid: brak inkrementacji
    reg_Sid <= "000";

    -- Sa: ADR = AD
    reg_Sa  <= "00";

    ----------------------------------------------------------------
    -- KONWERSJE
    ----------------------------------------------------------------

    alu_BB <= std_logic_vector(reg_BB);
    alu_BC <= std_logic_vector(reg_BC);

    -- busint szyna D (nieaktywna w trybie ALU)
    bus_D <= (others => 'Z');

    ----------------------------------------------------------------
    -- INSTANCJE
    ----------------------------------------------------------------

    U_REGS : register_cpu
        port map (
            clk   => clk,
            reset => reset,
            DI    => reg_DI,
            BA    => reg_BA,
            Sbb   => reg_Sbb,
            Sbc   => reg_Sbc,
            Sba   => reg_Sba,
            Sid   => reg_Sid,
            Sa    => reg_Sa,
            BB    => reg_BB,
            BC    => reg_BC,
            ADR   => reg_ADR,
            IRout => reg_IR
        );

    U_ALU : alu
        port map (
            clk   => clk,
            BB    => alu_BB,
            BC    => alu_BC,
            S_ALU => SW(3 downto 0),
            S_F   => '0',
            C_in  => '0',
            Y     => alu_Y,
            C     => alu_C,
            Z     => alu_Z,
            S     => alu_S,
            P     => alu_P
        );

    U_BUSINT : busint
        port map (
            clk           => clk,
            ADR           => reg_ADR,
            DO            => reg_BB,
            Smar          => '0',
            Smbr          => '0',
            WRin          => '0',
            RDin          => '0',
            AD            => bus_AD,
            D             => bus_D,
            DI            => bus_DI,
            WR            => bus_WR,
            RD            => bus_RD,
            phys_addr_out => phys_addr
        );

    U_RAM : ram
        port map (
            clk     => clk,
            we      => bus_WR,
            address => phys_addr,
            data    => std_logic_vector(bus_D),
            q       => ram_data_out
        );

    ----------------------------------------------------------------
    -- REJESTR WYNIKU (synchroniczny) - operacja wykonuje sie na zboczu
    -- zegara, czyli po kliknieciu KEY[0].
    --
    -- ALU liczy wynik kombinacyjnie, ale na HEX/LEDR pokazujemy go
    -- DOPIERO po zatrzasnieciu w tym rejestrze. Dzieki temu nic nie
    -- zmienia sie na wyswietlaczu, dopoki uzytkownik nie klika KEY[0].
    -- Reset (KEY[1]) zeruje wyswietlany wynik.
    --
    -- Uwaga: zapis wyniku do rejestru docelowego (gdy WEN=1) nadal
    -- korzysta z kombinacyjnego alu_Y i odbywa sie na tym SAMYM zboczu,
    -- wiec jedno klikniecie naraz pokazuje wynik i (opcjonalnie) go
    -- zapisuje - obie wartosci sa identyczne.
    ----------------------------------------------------------------

    process (clk, reset)
    begin
        if reset = '1' then
            disp_Y  <= (others => '0');
            disp_C  <= '0';
            disp_Z  <= '0';
            disp_S  <= '0';
            disp_P  <= '0';
            disp_op <= (others => '0');
        elsif rising_edge(clk) then
            disp_Y  <= alu_Y;
            disp_C  <= alu_C;
            disp_Z  <= alu_Z;
            disp_S  <= alu_S;
            disp_P  <= alu_P;
            disp_op <= SW(3 downto 0);
        end if;
    end process;

    ----------------------------------------------------------------
    -- FLAGI (zatrzasniete na zboczu zegara)
    ----------------------------------------------------------------

    flags_nibble <= disp_C & disp_Z & disp_S & disp_P;

    ----------------------------------------------------------------
    -- LED
    --   LEDR[3:0] - flagi ostatnio wykonanej operacji (zatrzasniete)
    --   LEDR[9:4] - biezacy stan przelacznikow (na zywo)
    ----------------------------------------------------------------

    LEDR(0) <= disp_P;
    LEDR(1) <= disp_S;
    LEDR(2) <= disp_Z;
    LEDR(3) <= disp_C;
    LEDR(4) <= wen;
    LEDR(5) <= dst;
    LEDR(7 downto 6) <= s_sbb;
    LEDR(9 downto 8) <= s_sbc;

    ----------------------------------------------------------------
    -- WYSWIETLACZE HEX (wynik zatrzasniety po kliknieciu KEY[0])
    -- HEX3..HEX0 - wynik ALU (16-bit)
    -- HEX4       - flagi {C,Z,S,P}
    -- HEX5       - kod ostatnio wykonanej operacji
    ----------------------------------------------------------------

    U_HEX0 : hex_display port map (hex_in => disp_Y(3  downto 0),  seg_out => HEX0);
    U_HEX1 : hex_display port map (hex_in => disp_Y(7  downto 4),  seg_out => HEX1);
    U_HEX2 : hex_display port map (hex_in => disp_Y(11 downto 8),  seg_out => HEX2);
    U_HEX3 : hex_display port map (hex_in => disp_Y(15 downto 12), seg_out => HEX3);
    U_HEX4 : hex_display port map (hex_in => flags_nibble,         seg_out => HEX4);
    U_HEX5 : hex_display port map (hex_in => disp_op,              seg_out => HEX5);

end architecture rtl;