library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- LAB 2: Plik rejestrow procesora
-- 16 rejestrow roboczych A..P (kody 00010..10001)
-- + IR, TMP, PC, SP, AD, ATMP, FLAGS, SEG0..SEG3
-- =============================================================

entity register_cpu is
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
end entity register_cpu;

architecture rtl of register_cpu is

    type reg16_t is array (0 to 15) of signed(15 downto 0);

    function is_gp_code(sel : signed(4 downto 0)) return boolean is
        variable v : integer;
    begin
        v := to_integer(unsigned(std_logic_vector(sel)));
        return (v >= 2 and v <= 17);
    end function;

    function gp_index(sel : signed(4 downto 0)) return integer is
    begin
        return to_integer(unsigned(std_logic_vector(sel))) - 2;
    end function;

    function read_sel(sel : signed(4 downto 0);
                      DIv : signed(15 downto 0);
                      TMP : signed(15 downto 0);
                      R   : reg16_t;
                      IR  : signed(15 downto 0);
                      PC  : signed(31 downto 0);
                      SP  : signed(31 downto 0);
                      AD  : signed(31 downto 0);
                      ATMP: signed(31 downto 0);
                      FLAGS : signed(15 downto 0);
                      SEG0, SEG1, SEG2, SEG3 : signed(15 downto 0)) return signed is
    begin
        case sel is
            when "00000" => return DIv;
            when "00001" => return TMP;
            when "11100" => return IR;
            when "10100" => return PC(15 downto 0);
            when "10101" => return PC(31 downto 16);
            when "10110" => return SP(15 downto 0);
            when "10111" => return SP(31 downto 16);
            when "11000" => return AD(15 downto 0);
            when "11001" => return AD(31 downto 16);
            when "11010" => return ATMP(15 downto 0);
            when "11011" => return ATMP(31 downto 16);
            when "10010" => return FLAGS;
            when "10011" => return SEG0;
            when "11101" => return SEG1;
            when "11110" => return SEG2;
            when "11111" => return SEG3;
            when others  =>
                if is_gp_code(sel) then
                    return R(gp_index(sel));
                else
                    return to_signed(0, 16);
                end if;
        end case;
    end function;

    procedure clear_gp(v : out reg16_t) is
    begin
        for i in v'range loop
            v(i) := (others => '0');
        end loop;
    end procedure;

    signal FLAGS_r : signed(15 downto 0) := (others => '0');
    signal SEG0_r  : signed(15 downto 0) := (others => '0');
    signal SEG1_r  : signed(15 downto 0) := to_signed(1, 16);
    signal SEG2_r  : signed(15 downto 0) := to_signed(2, 16);
    signal SEG3_r  : signed(15 downto 0) := to_signed(3, 16);

begin

    process (clk, reset, Sbb, Sbc, Sa, Sas, DI, reg_we, LDF, FI, Sba, BA, Sid)
        variable IR   : signed(15 downto 0) := (others => '0');
        variable TMP  : signed(15 downto 0) := (others => '0');
        variable R    : reg16_t;
        variable PC   : signed(31 downto 0) := (others => '0');
        variable SP   : signed(31 downto 0) := (others => '0');
        variable AD   : signed(31 downto 0) := (others => '0');
        variable ATMP : signed(31 downto 0) := (others => '0');
    begin

        if reset = '1' then
            IR   := (others => '0');
            TMP  := (others => '0');
            clear_gp(R);
            PC   := (others => '0');
            SP   := (others => '0');
            AD   := (others => '0');
            ATMP := (others => '0');
            FLAGS_r  <= (others => '0');
            SEG0_r   <= (others => '0');
            SEG1_r   <= to_signed(1, 16);
            SEG2_r   <= to_signed(2, 16);
            SEG3_r   <= to_signed(3, 16);

        elsif (clk'event and clk = '1') then

            if LDF = '1' then
                FLAGS_r(3) <= FI(3);
                FLAGS_r(2) <= FI(2);
                FLAGS_r(1) <= FI(1);
                FLAGS_r(0) <= FI(0);
            end if;

            if reg_we = '1' then

                case Sid is
                    when "001" => PC := PC + 1;
                    when "010" => SP := SP + 1;
                    when "011" => SP := SP - 1;
                    when "100" => AD := AD + 1;
                    when "101" => AD := AD - 1;
                    when others => null;
                end case;

                case Sba is
                    when "00000" => IR               := BA;
                    when "00001" => TMP              := BA;
                    when "10100" => PC(15 downto 0)  := BA;
                    when "10101" => PC(31 downto 16) := BA;
                    when "10110" => SP(15 downto 0)  := BA;
                    when "10111" => SP(31 downto 16) := BA;
                    when "11000" => AD(15 downto 0)  := BA;
                    when "11001" => AD(31 downto 16) := BA;
                    when "11010" => ATMP(15 downto 0)  := BA;
                    when "11011" => ATMP(31 downto 16) := BA;
                    when "10010" => FLAGS_r          <= BA;
                    when "10011" => SEG0_r           <= BA;
                    when "11101" => SEG1_r           <= BA;
                    when "11110" => SEG2_r           <= BA;
                    when "11111" => SEG3_r           <= BA;
                    when others  =>
                        if is_gp_code(Sba) then
                            R(gp_index(Sba)) := BA;
                        end if;
                end case;

            end if;

        end if;

        BB <= read_sel(Sbb, DI, TMP, R, IR, PC, SP, AD, ATMP,
                       FLAGS_r, SEG0_r, SEG1_r, SEG2_r, SEG3_r);
        BC <= read_sel(Sbc, DI, TMP, R, IR, PC, SP, AD, ATMP,
                       FLAGS_r, SEG0_r, SEG1_r, SEG2_r, SEG3_r);

        case Sa is
            when "00" => ADR <= AD;
            when "01" => ADR <= PC;
            when "10" => ADR <= SP;
            when "11" => ADR <= ATMP;
            when others => ADR <= (others => '0');
        end case;

        case Sas is
            when "00" => SEGout <= SEG0_r;
            when "01" => SEGout <= SEG1_r;
            when "10" => SEGout <= SEG2_r;
            when "11" => SEGout <= SEG3_r;
            when others => SEGout <= SEG0_r;
        end case;

        IRout  <= IR;
        rA_dbg <= R(0);
        rB_dbg <= R(1);
        PC_dbg <= PC(15 downto 0);

        flag_C <= FLAGS_r(3);
        flag_Z <= FLAGS_r(2);
        flag_S <= FLAGS_r(1);
        flag_P <= FLAGS_r(0);

    end process;

end architecture rtl;
