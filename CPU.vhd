library ieee;
use ieee.std_logic_1164.all;

-- =============================================================
-- TOP-LEVEL DE1-SoC: demonstrator 22 rozkazow ALU + HEX
--
-- Przyciski:
--   KEY[0] - podany do ALU jako clk (ALU jest kombinacyjne)
--   KEY[1] - niewykorzystywany w trybie demonstracyjnym
--
-- Mapowanie przelacznikow SW[9:0]:
--   SW[4:0] - S_ALU : 5-bitowy kod operacji ALU (0..21)
--   SW[6:5] - PRESET argumentow BB/BC:
--             00 -> BB=0007, BC=0002
--             01 -> BB=8001, BC=0001
--             10 -> BB=00F0, BC=000F
--             11 -> BB=FFFF, BC=0001
--   SW[7]   - C_in do ALU
--   SW[8]   - S_F: 0=pokaz wynik, 1=pokaz flagi w HEX3..HEX0
--   SW[9]   - SWAP: 0=BB/BC normalnie, 1=zamien BB z BC
--
-- Wyjscia HEX:
--   HEX3..HEX0 - wynik ALU [15:0] albo flagi gdy SW[8]=1
--   HEX4       - flagi {C, Z, S, P}
--   HEX5       - mlodsze 4 bity kodu operacji S_ALU
--
-- Wyjscia LED:
--   LEDR[0]   = P  flaga parzystosci
--   LEDR[1]   = S  flaga znaku
--   LEDR[2]   = Z  flaga zera
--   LEDR[3]   = C  flaga przeniesienia/pozyczki/bledu
--   LEDR[4]   = S_ALU[4] (piaty bit kodu operacji)
--   LEDR[6:5] = PRESET
--   LEDR[7]   = C_in
--   LEDR[8]   = S_F
--   LEDR[9]   = SWAP
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

    component alu is
        port (
            clk   : in  std_logic;
            BB    : in  std_logic_vector(15 downto 0);
            BC    : in  std_logic_vector(15 downto 0);
            S_ALU : in  std_logic_vector(4 downto 0);
            S_F   : in  std_logic;
            C_in  : in  std_logic;
            Y     : out std_logic_vector(15 downto 0);
            C     : out std_logic;
            Z     : out std_logic;
            S     : out std_logic;
            P     : out std_logic
        );
    end component;

    component hex_display is
        port (
            hex_in  : in  std_logic_vector(3 downto 0);
            seg_out : out std_logic_vector(6 downto 0)
        );
    end component;

    signal clk          : std_logic;
    signal op_code      : std_logic_vector(4 downto 0);
    signal preset       : std_logic_vector(1 downto 0);
    signal base_BB      : std_logic_vector(15 downto 0);
    signal base_BC      : std_logic_vector(15 downto 0);
    signal alu_BB       : std_logic_vector(15 downto 0);
    signal alu_BC       : std_logic_vector(15 downto 0);
    signal alu_Y        : std_logic_vector(15 downto 0);
    signal alu_C        : std_logic;
    signal alu_Z        : std_logic;
    signal alu_S        : std_logic;
    signal alu_P        : std_logic;
    signal flags_nibble : std_logic_vector(3 downto 0);

begin

    clk     <= not KEY(0);
    op_code <= SW(4 downto 0);
    preset  <= SW(6 downto 5);

    process(preset)
    begin
        case preset is
            when "00" =>
                base_BB <= x"0007";
                base_BC <= x"0002";
            when "01" =>
                base_BB <= x"8001";
                base_BC <= x"0001";
            when "10" =>
                base_BB <= x"00F0";
                base_BC <= x"000F";
            when others =>
                base_BB <= x"FFFF";
                base_BC <= x"0001";
        end case;
    end process;

    alu_BB <= base_BC when SW(9) = '1' else base_BB;
    alu_BC <= base_BB when SW(9) = '1' else base_BC;

    U_ALU : alu
        port map (
            clk   => clk,
            BB    => alu_BB,
            BC    => alu_BC,
            S_ALU => op_code,
            S_F   => SW(8),
            C_in  => SW(7),
            Y     => alu_Y,
            C     => alu_C,
            Z     => alu_Z,
            S     => alu_S,
            P     => alu_P
        );

    flags_nibble <= alu_C & alu_Z & alu_S & alu_P;

    LEDR(0) <= alu_P;
    LEDR(1) <= alu_S;
    LEDR(2) <= alu_Z;
    LEDR(3) <= alu_C;
    LEDR(4) <= op_code(4);
    LEDR(6 downto 5) <= preset;
    LEDR(7) <= SW(7);
    LEDR(8) <= SW(8);
    LEDR(9) <= SW(9);

    U_HEX0 : hex_display port map (hex_in => alu_Y(3  downto 0),  seg_out => HEX0);
    U_HEX1 : hex_display port map (hex_in => alu_Y(7  downto 4),  seg_out => HEX1);
    U_HEX2 : hex_display port map (hex_in => alu_Y(11 downto 8),  seg_out => HEX2);
    U_HEX3 : hex_display port map (hex_in => alu_Y(15 downto 12), seg_out => HEX3);
    U_HEX4 : hex_display port map (hex_in => flags_nibble,         seg_out => HEX4);
    U_HEX5 : hex_display port map (hex_in => op_code(3 downto 0),  seg_out => HEX5);

end architecture rtl;
