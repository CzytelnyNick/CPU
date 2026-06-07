library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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
            C, Z, S, P : out STD_LOGIC
        );
    end component;

    signal BB, BC, Y : std_logic_vector(15 downto 0) := (others => '0');
    signal S_ALU       : std_logic_vector(4 downto 0) := (others => '0');
    signal C_in        : std_logic := '0';
    signal C, Z, S, P  : std_logic;
    signal clk         : std_logic := '0';

begin

    uut: alu port map (
        clk => clk, BB => BB, BC => BC, S_ALU => S_ALU, S_F => '0', C_in => C_in,
        Y => Y, C => C, Z => Z, S => S, P => P
    );

    process
        variable errcnt : integer := 0;

        procedure t(bbv : std_logic_vector(15 downto 0);
                    bcv : std_logic_vector(15 downto 0);
                    op  : std_logic_vector(4 downto 0);
                    cin : std_logic;
                    ey  : std_logic_vector(15 downto 0);
                    ec, ez, es, ep : std_logic;
                    nm  : in string) is
        begin
            BB <= bbv; BC <= bcv; S_ALU <= op; C_in <= cin;
            wait for 10 ns;
            if Y /= ey then
                report "FAIL [" & nm & "] Y" severity error; errcnt := errcnt + 1;
            end if;
            if C /= ec then report "FAIL [" & nm & "] C" severity error; errcnt := errcnt + 1; end if;
            if Z /= ez then report "FAIL [" & nm & "] Z" severity error; errcnt := errcnt + 1; end if;
            if S /= es then report "FAIL [" & nm & "] S" severity error; errcnt := errcnt + 1; end if;
            if P /= ep then report "FAIL [" & nm & "] P" severity error; errcnt := errcnt + 1; end if;
        end procedure;
    begin
        t(x"1234", x"0000", "00000", '0', x"1234", '0','0','0','0', "PASS BB");
        t(x"0000", x"00FF", "00001", '0', x"00FF", '0','0','0','1', "PASS BC");
        t(x"0007", x"0002", "00010", '0', x"0009", '0','0','0','1', "ADD 7+2");
        t(x"FFFF", x"0001", "00010", '0', x"0000", '1','1','0','1', "ADD overflow");
        t(x"0007", x"0002", "00011", '0', x"0005", '0','0','0','1', "SUB 7-2");
        t(x"0002", x"0007", "00011", '0', x"FFFB", '1','0','1','0', "SUB 2-7");
        t(x"0007", x"0002", "00100", '0', x"0007", '0','0','0','0', "OR");
        t(x"0007", x"0002", "00101", '0', x"0002", '0','0','0','0', "AND");
        t(x"0007", x"0002", "00110", '0', x"0005", '0','0','0','1', "XOR");
        t(x"0007", x"0002", "00111", '0', x"FFFA", '0','0','1','1', "XNOR");
        t(x"0007", x"0000", "01000", '0', x"FFF8", '0','0','1','0', "NOT BB");
        t(x"0007", x"0000", "01001", '0', x"FFF9", '0','0','1','1', "NEG BB");
        t(x"1234", x"5678", "01010", '0', x"0000", '0','1','0','1', "CLR");
        t(x"0007", x"0002", "01011", '1', x"000A", '0','0','0','1', "ADC");
        t(x"0007", x"0002", "01100", '1', x"0004", '0','0','0','0', "SBB");
        t(x"0007", x"0000", "01101", '0', x"0008", '0','0','0','0', "INC BB");
        t(x"0007", x"0000", "01110", '0', x"000E", '0','0','0','0', "SHL BB");
        t(x"8000", x"0000", "01110", '0', x"0000", '1','1','0','1', "SHL carry");
        t(x"0007", x"0000", "01111", '0', x"0003", '1','0','0','1', "SHR BB");
        t(x"0000", x"0003", "10000", '0', x"FFFC", '0','0','1','0', "NOT BC");
        t(x"0000", x"0007", "10001", '0', x"FFF9", '0','0','1','1', "NEG BC");
        t(x"0000", x"0007", "10010", '0', x"0008", '0','0','0','0', "INC BC");
        t(x"0008", x"0000", "10011", '0', x"0007", '0','0','0','0', "DEC BB");

        if errcnt = 0 then
            report "=== ALU_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== ALU_TB: LICZBA BLEDOW = " & integer'image(errcnt) severity error;
        end if;
        wait;
    end process;

end architecture behavior;
