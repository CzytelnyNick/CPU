library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- TOP-LEVEL: ALU + Plik Rejestrow + busint + RAM + HEX
--
-- Przyciski (aktywne NISKIE na plytkach DE):
--   KEY[0] - reczny zegar CLK (jedno wcisnij-puscic = 1 cykl)
--   KEY[1] - reset asynchroniczny (zeruje rejestry; NIE czysci RAM)
--
-- TRYB PRACY: SW[9:8]
--   "00" ALU      - operacje ALU na rejestrach
--   "01" RAM WRITE - zapis do pamieci RAM
--   "10" RAM READ  - odczyt z pamieci RAM
--   "11" INSPECT   - podglad dowolnego rejestru
--
-- ---------------------------------------------------------------
-- TRYB "00" ALU
--   SW[7:6] Sbc  - argument 2 ALU: 00=rA 01=rB 10=rC 11=DI
--   SW[5:4] Sbb  - argument 1 ALU ORAZ rejestr docelowy zapisu:
--                  00=rA 01=rB 10=rC 11=DI (DI => zapis pomijany)
--   SW[3:0] S_ALU- kod operacji ALU
--   KEY[0]: zapisuje wynik ALU do rejestru wskazanego przez Sbb
--   (sam podglad wyniku jest na HEX bez wciskania KEY)
--   HEX3..0 = wynik ALU, HEX4 = flagi {C,Z,S,P}, HEX5 = kod operacji
--
-- TRYB "01" RAM WRITE
--   SW[7:0] = adres (offset, segment 0) ORAZ zapisywana dana
--             (zapisujemy wartosc X pod adres X)
--   KEY[0]: zapisuje dana do RAM pod adresem fizycznym
--   HEX3..0 = zapisywana dana, HEX5..4 = adres fizyczny, LEDR[8]=WR
--
-- TRYB "10" RAM READ
--   SW[7:0] = adres (offset, segment 0)
--   Dana spod adresu pojawia sie na HEX na biezaco (bez KEY)
--   HEX3..0 = odczytana dana, HEX5..4 = adres fizyczny, LEDR[9]=RD
--
-- TRYB "11" INSPECT
--   SW[7:4] = kod rejestru do podgladu (mapa Sbb pliku rejestrow):
--             0010=rA 0011=rB 0100=rC ... 1000=IR 1001=PC[15:0] itd.
--   HEX3..0 = zawartosc rejestru, HEX5 = kod rejestru, HEX4 = flagi
--
-- ---------------------------------------------------------------
-- LEDR:
--   LEDR[0]=P  LEDR[1]=S  LEDR[2]=Z  LEDR[3]=C  (flagi ALU)
--   LEDR[7:6]=tryb pracy (SW[9:8])
--   LEDR[8]=WR (zapis do RAM)   LEDR[9]=RD (odczyt z RAM)
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
    -- STALE TRYBOW
    ----------------------------------------------------------------
    constant MODE_ALU   : std_logic_vector(1 downto 0) := "00";
    constant MODE_WRITE : std_logic_vector(1 downto 0) := "01";
    constant MODE_READ  : std_logic_vector(1 downto 0) := "10";
    constant MODE_INSP  : std_logic_vector(1 downto 0) := "11";

    ----------------------------------------------------------------
    -- SYGNALY
    ----------------------------------------------------------------

    signal clk   : std_logic;
    signal reset : std_logic;
    signal s_mode : std_logic_vector(1 downto 0);

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
    signal alu_op : std_logic_vector(3 downto 0);
    signal alu_Y  : std_logic_vector(15 downto 0);
    signal alu_C  : std_logic;
    signal alu_Z  : std_logic;
    signal alu_S  : std_logic;
    signal alu_P  : std_logic;

    -- busint
    signal bus_addr32 : signed(31 downto 0);
    signal bus_AD   : signed(31 downto 0);
    signal bus_D    : signed(15 downto 0);
    signal bus_DI   : signed(15 downto 0);
    signal bus_DO   : signed(15 downto 0);
    signal bus_Smar : std_logic;
    signal bus_Smbr : std_logic;
    signal bus_WRin : std_logic;
    signal bus_RDin : std_logic;
    signal bus_WR   : std_logic;
    signal bus_RD   : std_logic;
    signal phys_addr: std_logic_vector(9 downto 0);

    -- RAM
    signal ram_we       : std_logic;
    signal ram_data_in  : std_logic_vector(15 downto 0);
    signal ram_q        : std_logic_vector(15 downto 0);

    -- flagi i multipleksery wyswietlaczy
    signal flags_nibble : std_logic_vector(3 downto 0);
    signal disp_value   : std_logic_vector(15 downto 0);
    signal disp_h4      : std_logic_vector(3 downto 0);
    signal disp_h5      : std_logic_vector(3 downto 0);

begin

    ----------------------------------------------------------------
    -- ZEGAR I RESET (KEY aktywne NISKIE)
    ----------------------------------------------------------------
    clk    <= not KEY(0);
    reset  <= not KEY(1);
    s_mode <= SW(9 downto 8);

    ----------------------------------------------------------------
    -- DI: dane z przelacznikow SW[3:0] rozszerzone do 16-bit
    ----------------------------------------------------------------
    reg_DI <= signed(x"000" & SW(3 downto 0));

    ----------------------------------------------------------------
    -- Sbb: argument 1 ALU / podgladany rejestr
    --   tryb ALU      -> SW[5:4]: 00=rA 01=rB 10=rC 11=DI
    --   tryb INSPECT  -> SW[7:4] jako surowy kod rejestru
    --   inne tryby    -> rA (bez znaczenia)
    ----------------------------------------------------------------
    reg_Sbb <= "0010" when (s_mode = MODE_ALU and SW(5 downto 4) = "00") else
               "0011" when (s_mode = MODE_ALU and SW(5 downto 4) = "01") else
               "0100" when (s_mode = MODE_ALU and SW(5 downto 4) = "10") else
               "0000" when (s_mode = MODE_ALU) else                       -- DI
               signed(SW(7 downto 4)) when (s_mode = MODE_INSP) else
               "0010";

    ----------------------------------------------------------------
    -- Sbc: argument 2 ALU (tylko tryb ALU)
    --   SW[7:6]: 00=rA 01=rB 10=rC 11=DI
    ----------------------------------------------------------------
    reg_Sbc <= "0010" when (s_mode = MODE_ALU and SW(7 downto 6) = "00") else
               "0011" when (s_mode = MODE_ALU and SW(7 downto 6) = "01") else
               "0100" when (s_mode = MODE_ALU and SW(7 downto 6) = "10") else
               "0000" when (s_mode = MODE_ALU) else                       -- DI
               "0010";

    ----------------------------------------------------------------
    -- Sba: rejestr docelowy zapisu
    --   tryb ALU: zapis do rejestru wskazanego przez Sbb (op.1)
    --     00=rA 01=rB 10=rC ; 11=DI -> "1111" (ATMP, zapis pomijany)
    --   pozostale tryby: "1111" (ATMP, brak zapisu widocznych rej.)
    ----------------------------------------------------------------
    reg_Sba <= "0010" when (s_mode = MODE_ALU and SW(5 downto 4) = "00") else
               "0011" when (s_mode = MODE_ALU and SW(5 downto 4) = "01") else
               "0100" when (s_mode = MODE_ALU and SW(5 downto 4) = "10") else
               "1111";

    reg_BA  <= signed(alu_Y);   -- wynik ALU do rejestru docelowego
    reg_Sid <= "000";           -- brak inkrementacji rejestrow adresowych
    reg_Sa  <= "00";            -- ADR = AD

    ----------------------------------------------------------------
    -- KOD OPERACJI ALU
    --   tryb ALU -> SW[3:0]; pozostale tryby -> PASS BB (podglad BB)
    ----------------------------------------------------------------
    alu_op <= SW(3 downto 0) when s_mode = MODE_ALU else "0000";

    alu_BB <= std_logic_vector(reg_BB);
    alu_BC <= std_logic_vector(reg_BC);

    ----------------------------------------------------------------
    -- MAGISTRALA I PAMIEC
    ----------------------------------------------------------------
    -- adres logiczny (segment 0) budowany z SW[7:0]
    bus_addr32 <= resize(signed('0' & SW(7 downto 0)), 32);

    -- dane do RAM = SW[7:0] (zapisujemy wartosc = adres)
    ram_data_in <= x"00" & SW(7 downto 0);
    bus_DO      <= signed(ram_data_in);

    -- sterowanie busint zaleznie od trybu
    bus_WRin <= '1' when s_mode = MODE_WRITE else '0';
    bus_RDin <= '1' when s_mode = MODE_READ  else '0';
    bus_Smar <= '1' when (s_mode = MODE_WRITE or s_mode = MODE_READ) else '0';
    bus_Smbr <= '1' when s_mode = MODE_WRITE else '0';

    -- RAM sterowany bezposrednio (pewny, jednocyklowy zapis na zbocze KEY[0])
    ram_we <= '1' when s_mode = MODE_WRITE else '0';

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
            S_ALU => alu_op,
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
            ADR           => bus_addr32,
            DO            => bus_DO,
            Smar          => bus_Smar,
            Smbr          => bus_Smbr,
            WRin          => bus_WRin,
            RDin          => bus_RDin,
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
            we      => ram_we,
            address => phys_addr,
            data    => ram_data_in,
            q       => ram_q
        );

    ----------------------------------------------------------------
    -- FLAGI
    ----------------------------------------------------------------
    flags_nibble <= alu_C & alu_Z & alu_S & alu_P;

    ----------------------------------------------------------------
    -- MULTIPLEKSERY WYSWIETLACZY
    ----------------------------------------------------------------
    disp_value <= alu_Y       when s_mode = MODE_ALU   else
                  ram_data_in when s_mode = MODE_WRITE else
                  ram_q       when s_mode = MODE_READ  else
                  alu_Y;  -- INSPECT (PASS BB pokazuje wybrany rejestr)

    disp_h4 <= flags_nibble       when (s_mode = MODE_ALU or s_mode = MODE_INSP) else
               phys_addr(3 downto 0);

    disp_h5 <= SW(3 downto 0)       when s_mode = MODE_ALU  else
               SW(7 downto 4)       when s_mode = MODE_INSP else
               phys_addr(7 downto 4);

    ----------------------------------------------------------------
    -- LED
    ----------------------------------------------------------------
    LEDR(0) <= alu_P;
    LEDR(1) <= alu_S;
    LEDR(2) <= alu_Z;
    LEDR(3) <= alu_C;
    LEDR(5 downto 4) <= "00";
    LEDR(7 downto 6) <= s_mode;
    LEDR(8) <= bus_WR;
    LEDR(9) <= bus_RD;

    ----------------------------------------------------------------
    -- WYSWIETLACZE HEX
    ----------------------------------------------------------------
    U_HEX0 : hex_display port map (hex_in => disp_value(3  downto 0),  seg_out => HEX0);
    U_HEX1 : hex_display port map (hex_in => disp_value(7  downto 4),  seg_out => HEX1);
    U_HEX2 : hex_display port map (hex_in => disp_value(11 downto 8),  seg_out => HEX2);
    U_HEX3 : hex_display port map (hex_in => disp_value(15 downto 12), seg_out => HEX3);
    U_HEX4 : hex_display port map (hex_in => disp_h4,                  seg_out => HEX4);
    U_HEX5 : hex_display port map (hex_in => disp_h5,                  seg_out => HEX5);

end architecture rtl;
