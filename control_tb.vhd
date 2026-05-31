library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================
-- TESTBENCH JEDNOSTKI STERUJACEJ
--
-- Sprawdza najwazniejsze przejscia stanow i sygnaly sterujace
-- dla fetch, ALU, LDI oraz BRZ.
-- =============================================================

entity control_tb is
end entity;

architecture behavior of control_tb is

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

    signal clk   : std_logic := '0';
    signal IR    : signed(15 downto 0) := (others => '0');
    signal reset : std_logic := '0';
    signal C     : std_logic := '0';
    signal Z     : std_logic := '0';
    signal S     : std_logic := '0';
    signal INT   : std_logic := '0';

    signal Salu  : std_logic_vector(4 downto 0);
    signal Sbb   : std_logic_vector(3 downto 0);
    signal Sbc   : std_logic_vector(3 downto 0);
    signal Sba   : std_logic_vector(3 downto 0);
    signal Sid   : std_logic_vector(2 downto 0);
    signal Sa    : std_logic_vector(1 downto 0);
    signal LDF   : std_logic;
    signal Smar  : std_logic;
    signal Smbr  : std_logic;
    signal WR    : std_logic;
    signal RD    : std_logic;
    signal INTA  : std_logic;
    signal MIO   : std_logic;
    signal state_dbg : std_logic_vector(3 downto 0);

begin

    uut: control
        port map (
            clk => clk,
            IR => IR,
            reset => reset,
            C => C,
            Z => Z,
            S => S,
            INT => INT,
            Salu => Salu,
            Sbb => Sbb,
            Sbc => Sbc,
            Sba => Sba,
            Sid => Sid,
            Sa => Sa,
            LDF => LDF,
            Smar => Smar,
            Smbr => Smbr,
            WR => WR,
            RD => RD,
            INTA => INTA,
            MIO => MIO,
            state_dbg => state_dbg
        );

    process
        variable errcnt : integer := 0;

        procedure tick is
        begin
            clk <= '1';
            wait for 10 ns;
            clk <= '0';
            wait for 10 ns;
        end procedure;

        procedure chk_slv(signal got : in std_logic_vector;
                          exp        : in std_logic_vector;
                          name       : in string) is
        begin
            if got /= exp then
                report "FAIL: " & name severity error;
                errcnt := errcnt + 1;
            else
                report "PASS: " & name severity note;
            end if;
        end procedure;

        procedure chk_bit(signal got : in std_logic;
                          exp        : in std_logic;
                          name       : in string) is
        begin
            if got /= exp then
                report "FAIL: " & name severity error;
                errcnt := errcnt + 1;
            else
                report "PASS: " & name severity note;
            end if;
        end procedure;

        procedure do_reset is
        begin
            reset <= '1';
            wait for 10 ns;
            reset <= '0';
            wait for 10 ns;
        end procedure;
    begin
        ----------------------------------------------------------------
        -- Fetch: f0 -> f1
        ----------------------------------------------------------------
        IR <= signed(x"2023"); -- ADD rA, rB
        do_reset;

        chk_slv(state_dbg, "0000", "po resecie stan f0");
        chk_bit(Smar, '1', "f0 Smar=1");
        chk_bit(RD,   '1', "f0 RD=1");
        chk_slv(Sid,  "001", "f0 Sid=PC+1");
        chk_slv(Sa,   "01", "f0 Sa=PC");

        tick;
        chk_slv(state_dbg, "0001", "stan f1");
        chk_slv(Sba, "0000", "f1 zapis do IR");
        chk_bit(MIO, '1', "f1 MIO=pamiec");

        tick;
        chk_slv(state_dbg, "0010", "stan decode");

        tick;
        chk_slv(state_dbg, "0011", "stan exec_alu");
        chk_slv(Salu, "00000", "ALU opcode ADD");
        chk_slv(Sbb,  "0010", "ALU BB=rA");
        chk_slv(Sbc,  "0011", "ALU BC=rB");
        chk_slv(Sba,  "0010", "ALU zapis rA");
        chk_bit(LDF, '1', "ALU laduje flagi");

        ----------------------------------------------------------------
        -- LDI rA, 0x07
        ----------------------------------------------------------------
        IR <= signed(x"4407");
        do_reset;
        tick; -- f1
        tick; -- decode
        tick; -- exec_ldi
        chk_slv(state_dbg, "0100", "stan exec_ldi");
        chk_slv(Sbb, "0000", "LDI BB=DI");
        chk_slv(Sbc, "0001", "LDI BC=TMP");
        chk_slv(Sba, "0010", "LDI zapis rA");
        chk_bit(LDF, '1', "LDI laduje flagi");

        ----------------------------------------------------------------
        -- BRZ: bez Z nie zapisuje PC, z Z zapisuje PC low
        ----------------------------------------------------------------
        IR <= signed(x"C004"); -- BRZ 0x04
        Z <= '0';
        do_reset;
        tick;
        tick;
        tick;
        chk_slv(state_dbg, "1100", "stan BRZ check");
        chk_slv(Sba, "1111", "BRZ Z=0 bez zapisu PC");

        Z <= '1';
        do_reset;
        tick;
        tick;
        tick;
        chk_slv(state_dbg, "1100", "stan BRZ check Z=1");
        chk_slv(Sba, "1000", "BRZ Z=1 zapis PC low");

        if errcnt = 0 then
            report "=== CONTROL_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== CONTROL_TB: LICZBA BLEDOW = " & integer'image(errcnt) & " ===" severity error;
        end if;

        wait;
    end process;

end architecture;
