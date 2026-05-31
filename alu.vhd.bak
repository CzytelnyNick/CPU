library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================
-- LAB 1: Jednostka Arytmetyczno-Logiczna (ALU) - 16-bit
--
-- Wejscia:
--   clk   - zegar systemowy
--   BB    - argument 1 (16-bit), z szyny B pliku rejestrow
--   BC    - argument 2 (16-bit), z szyny C pliku rejestrow
--   S_ALU - kod operacji (4-bit)
--   S_F   - wybor wyjscia: 0=wynik operacji, 1=flagi
--   C_in  - przeniesienie wejsciowe (dla ADC/SBB)
--
-- Wyjscia:
--   Y     - wynik operacji (16-bit)
--   C     - flaga przeniesienia (Carry)
--   Z     - flaga zera (Zero)
--   S     - flaga znaku (Sign)
--   P     - flaga parzystosci (Parity, even)
--
-- Tabela kodow operacji S_ALU:
--   0000 - PASS BB   przepisanie BB na wyjscie
--   0001 - PASS BC   przepisanie BC na wyjscie
--   0010 - ADD       BB + BC
--   0011 - SUB       BB - BC
--   0100 - OR        BB or BC
--   0101 - AND       BB and BC
--   0110 - XOR       BB xor BC
--   0111 - XNOR      BB xnor BC (rownowaznos)
--   1000 - NOT       not BB
--   1001 - NEG       dopelnienie do 2 z BB (-BB)
--   1010 - CLR       zerowanie wyjscia
--   1011 - ADC       BB + BC + C_in
--   1100 - SBB       BB - BC - C_in
--   1101 - INC       BB + 1
--   1110 - SHL       przesuniecie logiczne w lewo o 1
--   1111 - SHR       przesuniecie logiczne w prawo o 1
-- =============================================================

entity alu is
    Port (
        clk   : in  STD_LOGIC;
        BB    : in  STD_LOGIC_VECTOR(15 downto 0);
        BC    : in  STD_LOGIC_VECTOR(15 downto 0);
        S_ALU : in  STD_LOGIC_VECTOR(3 downto 0);
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

    -- --------------------------------------------------------
    -- Proces kombinacyjny: obliczenie wyniku
    -- Wyzwalany zmiana wejsc (asynchroniczny)
    -- --------------------------------------------------------
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

            when "0000" =>                          -- PASS BB
                v_res  := BB;
                v_cout := '0';

            when "0001" =>                          -- PASS BC
                v_res  := BC;
                v_cout := '0';

            when "0010" =>                          -- ADD
                v_sum  := ('0' & v_BB) + ('0' & v_BC);
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                v_cout := v_sum(16);

            when "0011" =>                          -- SUB
                v_sum  := ('0' & v_BB) - ('0' & v_BC);
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                if v_BB < v_BC then
                    v_cout := '1';
                else
                    v_cout := '0';
                end if;

            when "0100" =>                          -- OR
                v_res  := BB or BC;
                v_cout := '0';

            when "0101" =>                          -- AND
                v_res  := BB and BC;
                v_cout := '0';

            when "0110" =>                          -- XOR
                v_res  := BB xor BC;
                v_cout := '0';

            when "0111" =>                          -- XNOR
                v_res  := BB xnor BC;
                v_cout := '0';

            when "1000" =>                          -- NOT
                v_res  := not BB;
                v_cout := '0';

            when "1001" =>                          -- NEG
                v_sum  := ('0' & (not v_BB)) + 1;
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                v_cout := v_sum(16);

            when "1010" =>                          -- CLR
                v_res  := (others => '0');
                v_cout := '0';

            when "1011" =>                          -- ADC
                v_sum  := ('0' & v_BB) + ('0' & v_BC) + (x"0000" & C_in);
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                v_cout := v_sum(16);

            when "1100" =>                          -- SBB
                v_sum  := ('0' & v_BB) - ('0' & v_BC) - (x"0000" & C_in);
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                if v_BB < (v_BC + ("000000000000000" & C_in)) then
                    v_cout := '1';
                else
                    v_cout := '0';
                end if;

            when "1101" =>                          -- INC
                v_sum  := ('0' & v_BB) + 1;
                v_res  := STD_LOGIC_VECTOR(v_sum(15 downto 0));
                v_cout := v_sum(16);

            when "1110" =>                          -- SHL
                v_res  := BB(14 downto 0) & '0';
                v_cout := BB(15);

            when "1111" =>                          -- SHR
                v_res  := '0' & BB(15 downto 1);
                v_cout := BB(0);

            when others =>
                v_res  := (others => '0');
                v_cout := '0';

        end case;

        result    <= v_res;
        carry_out <= v_cout;
    end process;

    -- --------------------------------------------------------
    -- Generowanie flag (kombinacyjne)
    -- --------------------------------------------------------

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