library ieee;

use ieee.std_logic_1164.all;

use ieee.numeric_std.all;



-- =============================================================

-- TOP-LEVEL: Pelny procesor 16-bit

--

-- Tryb automatyczny (SW[9]=0):

--   Pelny cykl fetch/decode/execute sterowany przez control.

--   SW[1:0] wybiera widok na HEX3..HEX0 (A/B/IR/PC).

--

-- Tryb laboratoryjny ALU (SW[9]=1):

--   SW[3:0]  = kod operacji ALU (S_ALU)

--   SW[5:4]  = Sbb (00=A, 01=B, 10=C, 11=DI)

--   SW[7:6]  = Sbc (00=A, 01=B, 10=C, 11=DI)

--   SW[8]    = WEN (zapis wyniku do rejestru przy impulsie KEY[0])

--   SW[2]    = DST (0=rA, 1=rB)

--   KEY[0]   = zegar, KEY[1] = reset

--   LEDR[3:0]= flagi C,Z,S,P; HEX4 = flagi; HEX0..3 = wynik ALU

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



    function sw2sel(sw2 : std_logic_vector(1 downto 0)) return std_logic_vector is

    begin

        case sw2 is

            when "00"   => return "00010";

            when "01"   => return "00011";

            when "10"   => return "00100";

            when others => return "00000";

        end case;

    end function;



    component control is

        port (

            clk       : in  std_logic;

            IR        : in  signed(15 downto 0);

            reset     : in  std_logic;

            C         : in  std_logic;

            Z         : in  std_logic;

            S         : in  std_logic;

            INT       : in  std_logic;

            Salu      : out std_logic_vector(4 downto 0);

            Sbb       : out std_logic_vector(4 downto 0);

            Sbc       : out std_logic_vector(4 downto 0);

            Sba       : out std_logic_vector(4 downto 0);

            Sid       : out std_logic_vector(2 downto 0);

            Sa        : out std_logic_vector(1 downto 0);

            Sas       : out std_logic_vector(1 downto 0);

            LDF       : out std_logic;

            Smar      : out std_logic;

            Smbr      : out std_logic;

            WR        : out std_logic;

            RD        : out std_logic;

            INTA      : out std_logic;

            MIO       : out std_logic;

            state_dbg : out std_logic_vector(3 downto 0)

        );

    end component;



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



    component register_cpu is

        port (

            clk    : in  std_logic;

            reset  : in  std_logic;

            reg_we : in  std_logic;

            DI     : in  signed(15 downto 0);

            BA     : in  signed(15 downto 0);

            Sbb    : in  signed(4 downto 0);

            Sbc    : in  signed(4 downto 0);

            Sba    : in  signed(4 downto 0);

            Sid    : in  signed(2 downto 0);

            Sa     : in  signed(1 downto 0);

            Sas    : in  signed(1 downto 0);

            LDF    : in  std_logic;

            FI     : in  std_logic_vector(3 downto 0);

            BB     : out signed(15 downto 0);

            BC     : out signed(15 downto 0);

            ADR    : out signed(31 downto 0);

            IRout  : out signed(15 downto 0);

            SEGout : out signed(15 downto 0);

            flag_C : out std_logic;

            flag_Z : out std_logic;

            flag_S : out std_logic;

            flag_P : out std_logic;

            rA_dbg : out signed(15 downto 0);

            rB_dbg : out signed(15 downto 0);

            PC_dbg : out signed(15 downto 0)

        );

    end component;



    component busint is

        port (

            clk           : in    std_logic;

            ADR           : in    signed(31 downto 0);

            SEG           : in    signed(15 downto 0);

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

            phys_addr_out : out   std_logic_vector(15 downto 0)

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



    signal clk   : std_logic;

    signal reset : std_logic;



    signal manual_mode : std_logic;



    signal ctrl_Salu      : std_logic_vector(4 downto 0);

    signal ctrl_Sbb       : std_logic_vector(4 downto 0);

    signal ctrl_Sbc       : std_logic_vector(4 downto 0);

    signal ctrl_Sba       : std_logic_vector(4 downto 0);

    signal ctrl_Sid       : std_logic_vector(2 downto 0);

    signal ctrl_Sa        : std_logic_vector(1 downto 0);

    signal ctrl_Sas       : std_logic_vector(1 downto 0);

    signal ctrl_LDF       : std_logic;

    signal ctrl_Smar      : std_logic;

    signal ctrl_Smbr      : std_logic;

    signal ctrl_WR        : std_logic;

    signal ctrl_RD        : std_logic;

    signal ctrl_MIO       : std_logic;

    signal ctrl_state_dbg : std_logic_vector(3 downto 0);



    signal eff_Salu : std_logic_vector(4 downto 0);

    signal eff_Sbb  : std_logic_vector(4 downto 0);

    signal eff_Sbc  : std_logic_vector(4 downto 0);

    signal eff_Sba  : std_logic_vector(4 downto 0);

    signal eff_Sid  : std_logic_vector(2 downto 0);

    signal eff_Sa   : std_logic_vector(1 downto 0);

    signal eff_Sas  : std_logic_vector(1 downto 0);

    signal eff_LDF  : std_logic;

    signal eff_Smar : std_logic;

    signal eff_Smbr : std_logic;

    signal eff_WR   : std_logic;

    signal eff_RD   : std_logic;

    signal eff_MIO  : std_logic;

    signal eff_reg_we : std_logic;



    signal manual_Sba : std_logic_vector(4 downto 0);



    signal reg_BB    : signed(15 downto 0);

    signal reg_BC    : signed(15 downto 0);

    signal reg_ADR   : signed(31 downto 0);

    signal reg_IR    : signed(15 downto 0);

    signal reg_DI    : signed(15 downto 0);

    signal reg_BA    : signed(15 downto 0);

    signal reg_SEG   : signed(15 downto 0);

    signal rA_val    : signed(15 downto 0);

    signal rB_val    : signed(15 downto 0);

    signal PC_val    : signed(15 downto 0);

    signal reg_flag_C : std_logic;

    signal reg_flag_Z : std_logic;

    signal reg_flag_S : std_logic;

    signal reg_flag_P : std_logic;



    signal alu_BB : std_logic_vector(15 downto 0);

    signal alu_BC : std_logic_vector(15 downto 0);

    signal alu_Y  : std_logic_vector(15 downto 0);

    signal alu_C  : std_logic;

    signal alu_Z  : std_logic;

    signal alu_S  : std_logic;

    signal alu_P  : std_logic;



    signal bus_AD        : signed(31 downto 0);

    signal bus_D         : signed(15 downto 0);

    signal bus_DI        : signed(15 downto 0);

    signal bus_WR        : std_logic;

    signal bus_RD        : std_logic;

    signal phys_addr     : std_logic_vector(15 downto 0);

    signal ram_data_out  : std_logic_vector(15 downto 0);



    signal disp_val      : std_logic_vector(15 downto 0);

    signal flags_nibble  : std_logic_vector(3 downto 0);

    signal hex5_val      : std_logic_vector(3 downto 0);



begin



    clk         <= not KEY(0);

    reset       <= not KEY(1);

    manual_mode <= SW(9);



    manual_Sba <= "00010" when SW(2) = '0' else "00011";



    eff_Salu <= SW(3 downto 0)              when manual_mode = '1' else ctrl_Salu;

    eff_Sbb  <= sw2sel(SW(5 downto 4))      when manual_mode = '1' else ctrl_Sbb;

    eff_Sbc  <= sw2sel(SW(7 downto 6))      when manual_mode = '1' else ctrl_Sbc;

    eff_Sba  <= manual_Sba                  when manual_mode = '1' else ctrl_Sba;

    eff_Sid  <= (others => '0')             when manual_mode = '1' else ctrl_Sid;

    eff_Sa   <= (others => '0')             when manual_mode = '1' else ctrl_Sa;

    eff_Sas  <= (others => '0')             when manual_mode = '1' else ctrl_Sas;

    eff_Smar <= '0'                         when manual_mode = '1' else ctrl_Smar;

    eff_Smbr <= '0'                         when manual_mode = '1' else ctrl_Smbr;

    eff_WR   <= '0'                         when manual_mode = '1' else ctrl_WR;

    eff_RD   <= '0'                         when manual_mode = '1' else ctrl_RD;

    eff_MIO  <= '0'                         when manual_mode = '1' else ctrl_MIO;

    eff_reg_we <= SW(8)                     when manual_mode = '1' else '1';

    eff_LDF  <= SW(8)                       when manual_mode = '1' else ctrl_LDF;



    reg_DI <= signed(resize(unsigned(std_logic_vector(reg_IR(7 downto 0))), 16));

    reg_BA <= signed(alu_Y) when manual_mode = '1' else

              bus_DI when eff_MIO = '1' else signed(alu_Y);



    bus_D <= signed(ram_data_out) when bus_RD = '1' else (others => 'Z');



    flags_nibble <= alu_C & alu_Z & alu_S & alu_P when manual_mode = '1' else

                    reg_flag_C & reg_flag_Z & reg_flag_S & reg_flag_P;



    hex5_val <= "1110" when manual_mode = '1' else ctrl_state_dbg;



    process (manual_mode, alu_Y, SW, rA_val, rB_val, reg_IR, PC_val)

    begin

        if manual_mode = '1' then

            disp_val <= alu_Y;

        else

            case SW(1 downto 0) is

                when "00"   => disp_val <= std_logic_vector(rA_val);

                when "01"   => disp_val <= std_logic_vector(rB_val);

                when "10"   => disp_val <= std_logic_vector(reg_IR);

                when others => disp_val <= std_logic_vector(PC_val);

            end case;

        end if;

    end process;



    alu_BB <= std_logic_vector(reg_BB);

    alu_BC <= std_logic_vector(reg_BC);



    U_CONTROL : control

        port map (

            clk       => clk,

            IR        => reg_IR,

            reset     => reset or manual_mode,

            C         => alu_C,

            Z         => reg_flag_Z,

            S         => alu_S,

            INT       => '0',

            Salu      => ctrl_Salu,

            Sbb       => ctrl_Sbb,

            Sbc       => ctrl_Sbc,

            Sba       => ctrl_Sba,

            Sid       => ctrl_Sid,

            Sa        => ctrl_Sa,

            Sas       => ctrl_Sas,

            LDF       => ctrl_LDF,

            Smar      => ctrl_Smar,

            Smbr      => ctrl_Smbr,

            WR        => ctrl_WR,

            RD        => ctrl_RD,

            INTA      => open,

            MIO       => ctrl_MIO,

            state_dbg => ctrl_state_dbg

        );



    U_REGS : register_cpu

        port map (

            clk    => clk,

            reset  => reset,

            reg_we => eff_reg_we,

            DI     => reg_DI,

            BA     => reg_BA,

            Sbb    => signed(eff_Sbb),

            Sbc    => signed(eff_Sbc),

            Sba    => signed(eff_Sba),

            Sid    => signed(eff_Sid),

            Sa     => signed(eff_Sa),

            Sas    => signed(eff_Sas),

            LDF    => eff_LDF,

            FI     => alu_C & alu_Z & alu_S & alu_P,

            BB     => reg_BB,

            BC     => reg_BC,

            ADR    => reg_ADR,

            IRout  => reg_IR,

            SEGout => reg_SEG,

            flag_C => reg_flag_C,

            flag_Z => reg_flag_Z,

            flag_S => reg_flag_S,

            flag_P => reg_flag_P,

            rA_dbg => rA_val,

            rB_dbg => rB_val,

            PC_dbg => PC_val

        );



    U_ALU : alu

        port map (

            clk   => clk,

            BB    => alu_BB,

            BC    => alu_BC,

            S_ALU => eff_Salu,

            S_F   => '0',

            C_in  => reg_flag_C,

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

            SEG           => reg_SEG,

            DO            => reg_BB,

            Smar          => eff_Smar,

            Smbr          => eff_Smbr,

            WRin          => eff_WR,

            RDin          => eff_RD,

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

            address => phys_addr(9 downto 0),

            data    => std_logic_vector(bus_D),

            q       => ram_data_out

        );



    LEDR(0) <= flags_nibble(0);

    LEDR(1) <= flags_nibble(1);

    LEDR(2) <= flags_nibble(2);

    LEDR(3) <= flags_nibble(3);

    LEDR(4) <= bus_RD;

    LEDR(5) <= bus_WR;

    LEDR(9 downto 6) <= (others => '0') when manual_mode = '1' else ctrl_state_dbg;



    U_HEX0 : hex_display port map (hex_in => disp_val(3  downto 0),  seg_out => HEX0);

    U_HEX1 : hex_display port map (hex_in => disp_val(7  downto 4),  seg_out => HEX1);

    U_HEX2 : hex_display port map (hex_in => disp_val(11 downto 8),  seg_out => HEX2);

    U_HEX3 : hex_display port map (hex_in => disp_val(15 downto 12), seg_out => HEX3);

    U_HEX4 : hex_display port map (hex_in => flags_nibble,            seg_out => HEX4);

    U_HEX5 : hex_display port map (hex_in => hex5_val,                seg_out => HEX5);



end architecture rtl;

