library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- TESTBENCH: jednostka sterujaca control (Lab 4)
-- Sprawdza przejscia stanow i sygnaly sterujace dla LDI, ADD, HLT.
-- =============================================================

entity control_tb is
end entity;

architecture behavior of control_tb is

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

    signal clk, reset, C, Z, S, INT : std_logic := '0';
    signal IR                        : signed(15 downto 0) := (others => '0');
    signal Salu, Sbb, Sbc, Sba       : std_logic_vector(4 downto 0);
    signal Sid                       : std_logic_vector(2 downto 0);
    signal Sa                        : std_logic_vector(1 downto 0);
    signal LDF, Smar, Smbr, WR, RD   : std_logic;
    signal INTA, MIO                 : std_logic;
    signal state_dbg                 : std_logic_vector(3 downto 0);

begin

    uut: control port map (
        clk, IR, reset, C, Z, S, INT,
        Salu, Sbb, Sbc, Sba, Sid, Sa,
        LDF, Smar, Smbr, WR, RD, INTA, MIO, state_dbg
    );

    clk <= not clk after 10 ns;

    process
        variable errcnt : integer := 0;

        procedure tick is
        begin
            wait for 20 ns;
        end procedure;

        procedure chk_state(exp : std_logic_vector(3 downto 0); nm : string) is
        begin
            if state_dbg /= exp then
                report "FAIL [" & nm & "] state" severity error;
                errcnt := errcnt + 1;
            else
                report "PASS [" & nm & "] state" severity note;
            end if;
        end procedure;

        procedure chk5(signal got : std_logic_vector(4 downto 0);
                       exp        : std_logic_vector(4 downto 0);
                       nm         : string) is
        begin
            if got /= exp then
                report "FAIL [" & nm & "]" severity error;
                errcnt := errcnt + 1;
            else
                report "PASS [" & nm & "]" severity note;
            end if;
        end procedure;

        procedure chk1(signal got : std_logic; exp : std_logic; nm : string) is
        begin
            if got /= exp then
                report "FAIL [" & nm & "]" severity error;
                errcnt := errcnt + 1;
            else
                report "PASS [" & nm & "]" severity note;
            end if;
        end procedure;

        procedure do_reset is
        begin
            reset <= '1';
            wait for 20 ns;
            reset <= '0';
            wait for 10 ns;
        end procedure;

        procedure run_ldi is
        begin
            do_reset;
            IR <= x"4007";

            chk_state("0000", "LDI f0");
            chk1(Smar, '1', "LDI f0 Smar");
            chk1(RD, '1', "LDI f0 RD");
            chk5(Sa, "01", "LDI f0 Sa=PC");
            chk5(Sid, "001", "LDI f0 Sid=PC++");
            tick;

            chk_state("0001", "LDI f1");
            chk5(Sba, "00000", "LDI f1 Sba=IR");
            chk1(MIO, '1', "LDI f1 MIO");
            tick;

            chk_state("0010", "LDI decode");
            tick;

            chk_state("0100", "LDI exec_ldi");
            chk5(Salu, "00000", "LDI Salu=PASS");
            chk5(Sba, "00010", "LDI Sba=A");
            chk1(LDF, '1', "LDI LDF");
            chk1(MIO, '1', "LDI exec MIO");
        end procedure;

        procedure run_add is
        begin
            do_reset;
            IR <= x"2201";
            tick;
            tick;

            chk_state("0010", "ADD decode");
            tick;

            chk_state("0011", "ADD exec_alu");
            chk5(Salu, "00010", "ADD Salu=ADD");
            chk5(Sbb, "00010", "ADD Sbb=A");
            chk5(Sbc, "00011", "ADD Sbc=B");
            chk5(Sba, "00010", "ADD Sba=A");
            chk1(LDF, '1', "ADD LDF");
        end procedure;

        procedure run_hlt is
        begin
            do_reset;
            IR <= x"1F00";
            tick;
            tick;

            chk_state("0010", "HLT decode");
            tick;

            chk_state("1111", "HLT halt");
            chk1(Smar, '0', "HLT no fetch");
            chk1(RD, '0', "HLT no RD");
        end procedure;

        procedure run_brz is
        begin
            do_reset;
            IR <= x"C000";
            Z  <= '1';
            tick;
            tick;

            chk_state("0010", "BRZ decode");
            tick;

            chk_state("1100", "BRZ brz_check");
            chk5(Sba, "10100", "BRZ Z=1 Sba=PC");
            Z <= '0';
        end procedure;

    begin
        reset <= '1'; wait for 30 ns;
        reset <= '0'; wait for 10 ns;
        chk_state("0000", "after reset f0");

        run_ldi;
        run_add;
        run_hlt;
        run_brz;

        if errcnt = 0 then
            report "=== CONTROL_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== CONTROL_TB: LICZBA BLEDOW = " & integer'image(errcnt) severity error;
        end if;
        wait;
    end process;

end architecture behavior;
