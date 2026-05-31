library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================
-- TESTBENCH JEDNOSTKOWY ALU (samosprawdzajacy)
--
-- Testuje wszystkie 22 operacje oraz flagi C, Z, S, P bezposrednio
-- na wejsciach/wyjsciach ALU.
-- =============================================================

entity alu_tb is
end entity;

architecture behavior of alu_tb is

    component alu is
        port (
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
    end component;

    signal clk   : std_logic := '0';
    signal BB    : std_logic_vector(15 downto 0) := (others => '0');
    signal BC    : std_logic_vector(15 downto 0) := (others => '0');
    signal S_ALU : std_logic_vector(4 downto 0)  := (others => '0');
    signal S_F   : std_logic := '0';
    signal C_in  : std_logic := '0';
    signal Y     : std_logic_vector(15 downto 0);
    signal C, Z, S, P : std_logic;

begin

    uut: alu
        port map (
            clk => clk, BB => BB, BC => BC, S_ALU => S_ALU,
            S_F => S_F, C_in => C_in, Y => Y, C => C, Z => Z, S => S, P => P
        );

    process
        variable errcnt : integer := 0;

        procedure t(bbv : in std_logic_vector(15 downto 0);
                    bcv : in std_logic_vector(15 downto 0);
                    op  : in std_logic_vector(4 downto 0);
                    cin : in std_logic;
                    ey  : in std_logic_vector(15 downto 0);
                    ec, ez, es, ep : in std_logic;
                    nm  : in string) is
        begin
            BB    <= bbv;
            BC    <= bcv;
            S_ALU <= op;
            C_in  <= cin;
            S_F   <= '0';
            wait for 10 ns;

            if Y /= ey then
                report "FAIL [" & nm & "] Y: got=" & integer'image(to_integer(unsigned(Y)))
                     & " exp=" & integer'image(to_integer(unsigned(ey))) severity error;
                errcnt := errcnt + 1;
            end if;
            if C /= ec then
                report "FAIL [" & nm & "] flaga C" severity error; errcnt := errcnt + 1;
            end if;
            if Z /= ez then
                report "FAIL [" & nm & "] flaga Z" severity error; errcnt := errcnt + 1;
            end if;
            if S /= es then
                report "FAIL [" & nm & "] flaga S" severity error; errcnt := errcnt + 1;
            end if;
            if P /= ep then
                report "FAIL [" & nm & "] flaga P" severity error; errcnt := errcnt + 1;
            end if;
        end procedure;

        procedure t_flags(bbv : in std_logic_vector(15 downto 0);
                          bcv : in std_logic_vector(15 downto 0);
                          op  : in std_logic_vector(4 downto 0);
                          ey  : in std_logic_vector(15 downto 0);
                          nm  : in string) is
        begin
            BB    <= bbv;
            BC    <= bcv;
            S_ALU <= op;
            C_in  <= '0';
            S_F   <= '1';
            wait for 10 ns;

            if Y /= ey then
                report "FAIL [" & nm & "] S_F flags Y" severity error;
                errcnt := errcnt + 1;
            end if;
        end procedure;
    begin
        t(x"0007", x"0002", "00000", '0', x"0009", '0','0','0','1', "ADD 7+2");
        t(x"FFFF", x"0001", "00000", '0', x"0000", '1','1','0','1', "ADD carry");
        t(x"0007", x"0002", "00001", '0', x"0005", '0','0','0','1', "SUB 7-2");
        t(x"0002", x"0007", "00001", '0', x"FFFB", '1','0','1','0', "SUB borrow");
        t(x"0007", x"0002", "00010", '0', x"000E", '0','0','0','0', "MUL 7*2");
        t(x"FFFF", x"0002", "00010", '0', x"FFFE", '1','0','1','0', "MUL upper bits");
        t(x"0007", x"0002", "00011", '0', x"0003", '0','0','0','1', "DIV 7/2");
        t(x"0007", x"0000", "00011", '0', x"0000", '1','1','0','1', "DIV by zero");
        t(x"0007", x"0002", "00100", '0', x"0001", '0','0','0','0', "MOD 7 mod 2");
        t(x"0007", x"0000", "00100", '0', x"0000", '1','1','0','1', "MOD by zero");
        t(x"0007", x"0000", "00101", '0', x"0008", '0','0','0','0', "INC 7");
        t(x"0007", x"0000", "00110", '0', x"0006", '0','0','0','1', "DEC 7");
        t(x"0000", x"0000", "00110", '0', x"FFFF", '1','0','1','1', "DEC borrow");
        t(x"0007", x"0000", "00111", '0', x"FFF9", '1','0','1','1', "NEG 7");
        t(x"0007", x"0002", "01000", '0', x"0002", '0','0','0','0', "AND");
        t(x"0007", x"0002", "01001", '0', x"0007", '0','0','0','0', "OR");
        t(x"0007", x"0002", "01010", '0', x"0005", '0','0','0','1', "XOR");
        t(x"0007", x"0000", "01011", '0', x"FFF8", '0','0','1','0', "NOT");
        t(x"0007", x"0002", "01100", '0', x"FFFD", '0','0','1','0', "NAND");
        t(x"0007", x"0002", "01101", '0', x"FFF8", '0','0','1','0', "NOR");
        t(x"0007", x"0000", "01110", '0', x"000E", '0','0','0','0', "SHL 7");
        t(x"8000", x"0000", "01110", '0', x"0000", '1','1','0','1', "SHL carry");
        t(x"0007", x"0000", "01111", '0', x"0003", '1','0','0','1', "SHR 7");
        t(x"8001", x"0000", "10000", '0', x"C000", '1','0','1','1', "SAR");
        t(x"8001", x"0000", "10001", '0', x"0003", '1','0','0','1', "ROL");
        t(x"8001", x"0000", "10010", '0', x"C000", '1','0','1','1', "ROR");
        t(x"0007", x"0007", "10011", '0', x"0001", '0','0','0','0', "CMP_EQ true");
        t(x"0007", x"0002", "10011", '0', x"0000", '0','1','0','1', "CMP_EQ false");
        t(x"0002", x"0007", "10100", '0', x"0001", '0','0','0','0', "CMP_LT true");
        t(x"0007", x"0002", "10101", '0', x"0001", '0','0','0','0', "CMP_GT true");

        t_flags(x"0007", x"0002", "00000", x"0001", "S_F returns flags after ADD");

        if errcnt = 0 then
            report "=== ALU_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== ALU_TB: LICZBA BLEDOW = " & integer'image(errcnt) & " ===" severity error;
        end if;

        wait;
    end process;

end architecture;
