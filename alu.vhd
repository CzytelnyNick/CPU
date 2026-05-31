library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================
-- Jednostka Arytmetyczno-Logiczna (ALU) - 16-bit
--
-- Wejscia:
--   clk   - zegar systemowy (zostawiony dla zgodnosci komponentu)
--   BB    - argument 1 (16-bit)
--   BC    - argument 2 (16-bit)
--   S_ALU - kod operacji (5-bit, 0..21)
--   S_F   - wybor wyjscia: 0=wynik operacji, 1=flagi
--   C_in  - przeniesienie wejsciowe
--
-- Wyjscia:
--   Y     - wynik operacji (16-bit) albo flagi gdy S_F=1
--   C     - flaga przeniesienia/pozyczki/bledu dzielenia
--   Z     - flaga zera
--   S     - flaga znaku
--   P     - flaga parzystosci (even parity)
--
-- Tabela kodow operacji S_ALU:
--   00000 - ADD       BB + BC
--   00001 - SUB       BB - BC
--   00010 - MUL       BB * BC, dolne 16 bitow
--   00011 - DIV       BB / BC, gdy BC=0 wynik=0 i C=1
--   00100 - MOD       BB mod BC, gdy BC=0 wynik=0 i C=1
--   00101 - INC       BB + 1
--   00110 - DEC       BB - 1
--   00111 - NEG       -BB
--   01000 - AND       BB and BC
--   01001 - OR        BB or BC
--   01010 - XOR       BB xor BC
--   01011 - NOT       not BB
--   01100 - NAND      not (BB and BC)
--   01101 - NOR       not (BB or BC)
--   01110 - SHL       przesuniecie logiczne w lewo o 1
--   01111 - SHR       przesuniecie logiczne w prawo o 1
--   10000 - SAR       przesuniecie arytmetyczne w prawo o 1
--   10001 - ROL       rotacja w lewo o 1
--   10010 - ROR       rotacja w prawo o 1
--   10011 - CMP_EQ    1 gdy BB = BC, inaczej 0
--   10100 - CMP_LT    1 gdy signed(BB) < signed(BC), inaczej 0
--   10101 - CMP_GT    1 gdy signed(BB) > signed(BC), inaczej 0
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
        variable v_mul  : unsigned(31 downto 0);
        variable v_res  : STD_LOGIC_VECTOR(15 downto 0);
        variable v_cout : STD_LOGIC;
    begin
        v_BB   := unsigned(BB);
        v_BC   := unsigned(BC);
        v_sum  := (others => '0');
        v_mul  := (others => '0');
        v_res  := (others => '0');
        v_cout := '0';

        case S_ALU is

            when "00000" =>                          -- ADD
                v_sum  := ('0' & v_BB) + ('0' & v_BC);
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                v_cout := v_sum(16);

            when "00001" =>                          -- SUB
                v_sum  := ('0' & v_BB) - ('0' & v_BC);
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                if v_BB < v_BC then
                    v_cout := '1';
                else
                    v_cout := '0';
                end if;

            when "00010" =>                          -- MUL
                v_mul  := v_BB * v_BC;
                v_res  := STD_LOGIC_VECTOR(v_mul(15 downto 0));
                if v_mul(31 downto 16) /= to_unsigned(0, 16) then
                    v_cout := '1';
                else
                    v_cout := '0';
                end if;

            when "00011" =>                          -- DIV
                if v_BC = to_unsigned(0, 16) then
                    v_res  := (others => '0');
                    v_cout := '1';
                else
                    v_res  := STD_LOGIC_VECTOR(v_BB / v_BC);
                    v_cout := '0';
                end if;

            when "00100" =>                          -- MOD
                if v_BC = to_unsigned(0, 16) then
                    v_res  := (others => '0');
                    v_cout := '1';
                else
                    v_res  := STD_LOGIC_VECTOR(v_BB mod v_BC);
                    v_cout := '0';
                end if;

            when "00101" =>                          -- INC
                v_sum  := ('0' & v_BB) + 1;
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                v_cout := v_sum(16);

            when "00110" =>                          -- DEC
                if v_BB = to_unsigned(0, 16) then
                    v_res  := x"FFFF";
                    v_cout := '1';
                else
                    v_sum  := ('0' & v_BB) - 1;
                    v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                    v_cout := '0';
                end if;

            when "00111" =>                          -- NEG
                v_sum  := ('0' & (not v_BB)) + 1;
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                if v_BB = to_unsigned(0, 16) then
                    v_cout := '0';
                else
                    v_cout := '1';
                end if;

            when "01000" =>                          -- AND
                v_res  := BB and BC;
                v_cout := '0';

            when "01001" =>                          -- OR
                v_res  := BB or BC;
                v_cout := '0';

            when "01010" =>                          -- XOR
                v_res  := BB xor BC;
                v_cout := '0';

            when "01011" =>                          -- NOT
                v_res  := not BB;
                v_cout := '0';

            when "01100" =>                          -- NAND
                v_res  := not (BB and BC);
                v_cout := '0';

            when "01101" =>                          -- NOR
                v_res  := not (BB or BC);
                v_cout := '0';

            when "01110" =>                          -- SHL
                v_res  := BB(14 downto 0) & '0';
                v_cout := BB(15);

            when "01111" =>                          -- SHR
                v_res  := '0' & BB(15 downto 1);
                v_cout := BB(0);

            when "10000" =>                          -- SAR
                v_res  := BB(15) & BB(15 downto 1);
                v_cout := BB(0);

            when "10001" =>                          -- ROL
                v_res  := BB(14 downto 0) & BB(15);
                v_cout := BB(15);

            when "10010" =>                          -- ROR
                v_res  := BB(0) & BB(15 downto 1);
                v_cout := BB(0);

            when "10011" =>                          -- CMP_EQ
                if BB = BC then
                    v_res := x"0001";
                else
                    v_res := x"0000";
                end if;
                v_cout := '0';

            when "10100" =>                          -- CMP_LT
                if signed(BB) < signed(BC) then
                    v_res := x"0001";
                else
                    v_res := x"0000";
                end if;
                v_cout := '0';

            when "10101" =>                          -- CMP_GT
                if signed(BB) > signed(BC) then
                    v_res := x"0001";
                else
                    v_res := x"0000";
                end if;
                v_cout := '0';

            when others =>
                v_res  := (others => '0');
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
