library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================
-- LAB 1: Jednostka Arytmetyczno-Logiczna (ALU) - 16-bit
-- 20 operacji, kod S_ALU 5-bitowy (zgodnie ze sprawozdaniem ASK)
-- =============================================================

entity alu is
    Port (
        clk   : in  STD_LOGIC;
        BB    : in  STD_LOGIC_VECTOR(15 downto 0);
        BC    : in  STD_LOGIC_VECTOR(15 downto 0);
        S_ALU : in  STD_LOGIC_VECTOR(4 downto 0);
        S_F   : in  STD_LOGIC;
        C_in  : in  STD_LOGIC;
        Y     : out STD_LOGIC_VECTOR(15 downto 0);
        C     : out STD_LOGIC;
        Z     : out STD_LOGIC;
        S     : out STD_LOGIC;
        P     : out STD_LOGIC
    );
end alu;

architecture Behavioral of alu is

    signal result     : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal carry_out  : STD_LOGIC := '0';
    signal flag_Z     : STD_LOGIC := '0';
    signal flag_S     : STD_LOGIC := '0';
    signal flag_C     : STD_LOGIC := '0';
    signal flag_P     : STD_LOGIC := '0';
    signal parity_xor : STD_LOGIC := '0';

begin

    process(BB, BC, S_ALU, C_in)
        variable v_BB   : unsigned(15 downto 0);
        variable v_BC   : unsigned(15 downto 0);
        variable v_sum  : unsigned(16 downto 0);
        variable v_res  : STD_LOGIC_VECTOR(15 downto 0);
        variable v_cout : STD_LOGIC;
    begin
        v_BB   := unsigned(BB);
        v_BC   := unsigned(BC);
        v_res  := (others => '0');
        v_cout := '0';

        case S_ALU is

            when "00000" => v_res := BB; v_cout := '0';                    -- PASS BB
            when "00001" => v_res := BC; v_cout := '0';                    -- PASS BC

            when "00010" =>                                                  -- ADD
                v_sum  := ('0' & v_BB) + ('0' & v_BC);
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                v_cout := v_sum(16);

            when "00011" =>                                                  -- SUB
                v_sum  := ('0' & v_BB) - ('0' & v_BC);
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                if v_BB < v_BC then v_cout := '1'; else v_cout := '0'; end if;

            when "00100" => v_res := BB or BC;  v_cout := '0';              -- OR
            when "00101" => v_res := BB and BC; v_cout := '0';              -- AND
            when "00110" => v_res := BB xor BC; v_cout := '0';              -- XOR
            when "00111" => v_res := BB xnor BC; v_cout := '0';             -- XNOR

            when "01000" => v_res := not BB; v_cout := '0';                 -- NOT BB
            when "01001" =>                                                  -- NEG BB
                v_sum  := ('0' & (not v_BB)) + 1;
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                v_cout := v_sum(16);

            when "01010" => v_res := (others => '0'); v_cout := '0';       -- CLR

            when "01011" =>                                                  -- ADC
                v_sum  := ('0' & v_BB) + ('0' & v_BC) + (x"0000" & C_in);
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                v_cout := v_sum(16);

            when "01100" =>                                                  -- SBB
                v_sum  := ('0' & v_BB) - ('0' & v_BC) - (x"0000" & C_in);
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                if v_BB < (v_BC + ("000000000000000" & C_in)) then
                    v_cout := '1';
                else
                    v_cout := '0';
                end if;

            when "01101" =>                                                  -- INC BB
                v_sum  := ('0' & v_BB) + 1;
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                v_cout := v_sum(16);

            when "01110" =>                                                  -- SHL BB
                v_res  := BB(14 downto 0) & '0';
                v_cout := BB(15);

            when "01111" =>                                                  -- SHR BB
                v_res  := '0' & BB(15 downto 1);
                v_cout := BB(0);

            when "10000" => v_res := not BC; v_cout := '0';                 -- NOT BC
            when "10001" =>                                                  -- NEG BC
                v_sum  := ('0' & (not v_BC)) + 1;
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                v_cout := v_sum(16);

            when "10010" =>                                                  -- INC BC
                v_sum  := ('0' & v_BC) + 1;
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                v_cout := v_sum(16);

            when "10011" =>                                                  -- DEC BB
                v_sum  := ('0' & v_BB) - 1;
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                if v_BB = 0 then v_cout := '1'; else v_cout := '0'; end if;

            when others =>
                v_res  := BB;
                v_cout := '0';

        end case;

        result    <= v_res;
        carry_out <= v_cout;
    end process;

    flag_Z <= '1' when result = x"0000" else '0';
    flag_S <= result(15);
    flag_C <= carry_out;

    parity_xor <= result(0)  xor result(1)  xor result(2)  xor result(3)
               xor result(4)  xor result(5)  xor result(6)  xor result(7)
               xor result(8)  xor result(9)  xor result(10) xor result(11)
               xor result(12) xor result(13) xor result(14) xor result(15);
    flag_P <= not parity_xor;

    C <= flag_C;
    Z <= flag_Z;
    S <= flag_S;
    P <= flag_P;

    Y <= result when S_F = '0' else
         (15 downto 4 => '0') & flag_C & flag_Z & flag_S & flag_P;

end Behavioral;
