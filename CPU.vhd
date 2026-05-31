library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- TOP-LEVEL DE1-SoC: ALU demo + prosty procesor z jednostka sterujaca
--
-- SW9 = 0: demonstrator 22 rozkazow ALU
--   SW[4:0] - kod ALU
--   SW[6:5] - preset argumentow
--   SW[7]   - C_in
--   SW[8]   - S_F: 0=wynik, 1=flagi na HEX3..HEX0
--
-- SW9 = 1: tryb procesora
--   KEY[0]  - reczny zegar, jeden krok po wcisnieciu
--   KEY[1]  - reset aktywny niskim stanem
--   SW[8]   - INT do jednostki sterujacej
--   SW[7:6] - wybor podgladu na HEX3..HEX0:
--             00=IR, 01=wynik ALU, 10=DI z pamieci, 11=adres fizyczny
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

    component control is
        port (
            clk   : in  std_logic;
            IR    : in  signed(15 downto 0);
            reset : in  std_logic;
            C     : in  std_logic;
            Z     : in  std_logic;
            S     : in  std_logic;
            INT   : in  std_logic;
            Salu  : out std_logic_vector(4 downto 0);
            Sbb   : out std_logic_vector(3 downto 0);
            Sbc   : out std_logic_vector(3 downto 0);
            Sba   : out std_logic_vector(3 downto 0);
            Sid   : out std_logic_vector(2 downto 0);
            Sa    : out std_logic_vector(1 downto 0);
            LDF   : out std_logic;
            Smar  : out std_logic;
            Smbr  : out std_logic;
            WR    : out std_logic;
            RD    : out std_logic;
            INTA  : out std_logic;
            MIO   : out std_logic;
            state_dbg : out std_logic_vector(3 downto 0)
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

    signal clk        : std_logic;
    signal reset      : std_logic;
    signal proc_mode  : std_logic;
    signal proc_reset : std_logic;

    -- Demonstrator ALU
    signal demo_preset  : std_logic_vector(1 downto 0);
    signal demo_BB      : std_logic_vector(15 downto 0);
    signal demo_BC      : std_logic_vector(15 downto 0);

    -- Plik rejestrow
    signal reg_BB  : signed(15 downto 0);
    signal reg_BC  : signed(15 downto 0);
    signal reg_ADR : signed(31 downto 0);
    signal reg_IR  : signed(15 downto 0);
    signal reg_DI  : signed(15 downto 0);
    signal reg_BA  : signed(15 downto 0);

    -- Jednostka sterujaca
    signal ctrl_Salu : std_logic_vector(4 downto 0);
    signal ctrl_Sbb  : std_logic_vector(3 downto 0);
    signal ctrl_Sbc  : std_logic_vector(3 downto 0);
    signal ctrl_Sba  : std_logic_vector(3 downto 0);
    signal ctrl_Sid  : std_logic_vector(2 downto 0);
    signal ctrl_Sa   : std_logic_vector(1 downto 0);
    signal ctrl_LDF  : std_logic;
    signal ctrl_Smar : std_logic;
    signal ctrl_Smbr : std_logic;
    signal ctrl_WR   : std_logic;
    signal ctrl_RD   : std_logic;
    signal ctrl_INTA : std_logic;
    signal ctrl_MIO  : std_logic;
    signal ctrl_state_dbg : std_logic_vector(3 downto 0);
    signal run_Smar : std_logic;
    signal run_Smbr : std_logic;
    signal run_WR   : std_logic;
    signal run_RD   : std_logic;
    signal run_MIO  : std_logic;

    -- ALU wspolne dla demo i procesora
    signal alu_BB : std_logic_vector(15 downto 0);
    signal alu_BC : std_logic_vector(15 downto 0);
    signal alu_op : std_logic_vector(4 downto 0);
    signal alu_Y  : std_logic_vector(15 downto 0);
    signal alu_S_F : std_logic;
    signal alu_C_in : std_logic;
    signal alu_C  : std_logic;
    signal alu_Z  : std_logic;
    signal alu_S  : std_logic;
    signal alu_P  : std_logic;

    -- Zatrzask flag procesora
    signal flag_C : std_logic := '0';
    signal flag_Z : std_logic := '0';
    signal flag_S : std_logic := '0';
    signal flag_P : std_logic := '0';

    -- busint / RAM
    signal bus_AD   : signed(31 downto 0);
    signal bus_D    : signed(15 downto 0);
    signal bus_DI   : signed(15 downto 0);
    signal bus_WR   : std_logic;
    signal bus_RD   : std_logic;
    signal phys_addr : std_logic_vector(9 downto 0);
    signal ram_data_out : std_logic_vector(15 downto 0);

    -- Wyswietlanie
    signal display_data : std_logic_vector(15 downto 0);
    signal proc_display : std_logic_vector(15 downto 0);
    signal flags_nibble : std_logic_vector(3 downto 0);
    signal hex4_in      : std_logic_vector(3 downto 0);
    signal hex5_in      : std_logic_vector(3 downto 0);

begin

    clk        <= not KEY(0);
    reset      <= not KEY(1);
    proc_mode  <= SW(9);
    proc_reset <= reset or (not proc_mode);
    demo_preset <= SW(6 downto 5);

    process(demo_preset)
    begin
        case demo_preset is
            when "00" =>
                demo_BB <= x"0007";
                demo_BC <= x"0002";
            when "01" =>
                demo_BB <= x"8001";
                demo_BC <= x"0001";
            when "10" =>
                demo_BB <= x"00F0";
                demo_BC <= x"000F";
            when others =>
                demo_BB <= x"FFFF";
                demo_BC <= x"0001";
        end case;
    end process;

    -- DI jest uzywane przez control do LDI/JMP/LOAD/STORE jako imm8.
    reg_DI <= signed(x"00" & std_logic_vector(reg_IR(7 downto 0)));
    run_Smar <= ctrl_Smar when proc_mode = '1' else '0';
    run_Smbr <= ctrl_Smbr when proc_mode = '1' else '0';
    run_WR   <= ctrl_WR   when proc_mode = '1' else '0';
    run_RD   <= ctrl_RD   when proc_mode = '1' else '0';
    run_MIO  <= ctrl_MIO  when proc_mode = '1' else '0';
    reg_BA <= bus_DI when run_MIO = '1' else signed(alu_Y);

    alu_BB <= std_logic_vector(reg_BB) when proc_mode = '1' else demo_BB;
    alu_BC <= std_logic_vector(reg_BC) when proc_mode = '1' else demo_BC;
    alu_op <= ctrl_Salu               when proc_mode = '1' else SW(4 downto 0);
    alu_S_F <= '0' when proc_mode = '1' else SW(8);
    alu_C_in <= flag_C when proc_mode = '1' else SW(7);

    process(clk, proc_reset)
    begin
        if proc_reset = '1' then
            flag_C <= '0';
            flag_Z <= '0';
            flag_S <= '0';
            flag_P <= '0';
        elsif rising_edge(clk) then
            if ctrl_LDF = '1' then
                flag_C <= alu_C;
                flag_Z <= alu_Z;
                flag_S <= alu_S;
                flag_P <= alu_P;
            end if;
        end if;
    end process;

    U_CONTROL : control
        port map (
            clk   => clk,
            IR    => reg_IR,
            reset => proc_reset,
            C     => flag_C,
            Z     => flag_Z,
            S     => flag_S,
            INT   => SW(8),
            Salu  => ctrl_Salu,
            Sbb   => ctrl_Sbb,
            Sbc   => ctrl_Sbc,
            Sba   => ctrl_Sba,
            Sid   => ctrl_Sid,
            Sa    => ctrl_Sa,
            LDF   => ctrl_LDF,
            Smar  => ctrl_Smar,
            Smbr  => ctrl_Smbr,
            WR    => ctrl_WR,
            RD    => ctrl_RD,
            INTA  => ctrl_INTA,
            MIO   => ctrl_MIO,
            state_dbg => ctrl_state_dbg
        );

    U_REGS : register_cpu
        port map (
            clk   => clk,
            reset => proc_reset,
            DI    => reg_DI,
            BA    => reg_BA,
            Sbb   => signed(ctrl_Sbb),
            Sbc   => signed(ctrl_Sbc),
            Sba   => signed(ctrl_Sba),
            Sid   => signed(ctrl_Sid),
            Sa    => signed(ctrl_Sa),
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
            S_F   => alu_S_F,
            C_in  => alu_C_in,
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
            Smar          => run_Smar,
            Smbr          => run_Smbr,
            WRin          => run_WR,
            RDin          => run_RD,
            AD            => bus_AD,
            D             => bus_D,
            DI            => bus_DI,
            WR            => bus_WR,
            RD            => bus_RD,
            phys_addr_out => phys_addr
        );

    bus_D <= signed(ram_data_out) when bus_RD = '1' else (others => 'Z');

    U_RAM : ram
        port map (
            clk     => clk,
            we      => bus_WR,
            address => phys_addr,
            data    => std_logic_vector(bus_D),
            q       => ram_data_out
        );

    with SW(7 downto 6) select proc_display <=
        std_logic_vector(reg_IR)              when "00",
        alu_Y                                 when "01",
        std_logic_vector(bus_DI)              when "10",
        "000000" & phys_addr                 when others;

    display_data <= alu_Y when proc_mode = '0' else proc_display;

    flags_nibble <= (alu_C & alu_Z & alu_S & alu_P) when proc_mode = '0' else
                     (flag_C & flag_Z & flag_S & flag_P);

    hex4_in <= flags_nibble when proc_mode = '0' else (flag_C & flag_Z & flag_S & flag_P);
    hex5_in <= alu_op(3 downto 0) when proc_mode = '0' else ctrl_state_dbg;

    LEDR(0) <= flags_nibble(0);
    LEDR(1) <= flags_nibble(1);
    LEDR(2) <= flags_nibble(2);
    LEDR(3) <= flags_nibble(3);
    LEDR(4) <= alu_op(4)  when proc_mode = '0' else ctrl_LDF;
    LEDR(5) <= SW(5)     when proc_mode = '0' else bus_RD;
    LEDR(6) <= SW(6)     when proc_mode = '0' else bus_WR;
    LEDR(7) <= SW(7)     when proc_mode = '0' else run_MIO;
    LEDR(8) <= SW(8)     when proc_mode = '0' else ctrl_INTA;
    LEDR(9) <= proc_mode;

    U_HEX0 : hex_display port map (hex_in => display_data(3  downto 0),  seg_out => HEX0);
    U_HEX1 : hex_display port map (hex_in => display_data(7  downto 4),  seg_out => HEX1);
    U_HEX2 : hex_display port map (hex_in => display_data(11 downto 8),  seg_out => HEX2);
    U_HEX3 : hex_display port map (hex_in => display_data(15 downto 12), seg_out => HEX3);
    U_HEX4 : hex_display port map (hex_in => hex4_in,                   seg_out => HEX4);
    U_HEX5 : hex_display port map (hex_in => hex5_in,                   seg_out => HEX5);

end architecture rtl;
