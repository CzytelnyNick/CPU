library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_cpu_tb is
end entity;

architecture behavior of register_cpu_tb is

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

    signal clk, reset, reg_we, LDF : std_logic := '0';
    signal DI, BA     : signed(15 downto 0) := (others => '0');
    signal Sbb, Sbc, Sba : signed(4 downto 0) := (others => '0');
    signal Sid : signed(2 downto 0) := (others => '0');
    signal Sa, Sas : signed(1 downto 0) := (others => '0');
    signal FI : std_logic_vector(3 downto 0) := (others => '0');
    signal BB, BC, IRout, rA_dbg, rB_dbg, PC_dbg : signed(15 downto 0);
    signal ADR : signed(31 downto 0);
    signal SEGout : signed(15 downto 0);
    signal flag_C, flag_Z, flag_S, flag_P : std_logic;

begin

    uut: register_cpu port map (
        clk => clk, reset => reset, reg_we => reg_we,
        DI => DI, BA => BA,
        Sbb => Sbb, Sbc => Sbc, Sba => Sba,
        Sid => Sid, Sa => Sa, Sas => Sas,
        LDF => LDF, FI => FI,
        BB => BB, BC => BC, ADR => ADR, IRout => IRout, SEGout => SEGout,
        flag_C => flag_C, flag_Z => flag_Z, flag_S => flag_S, flag_P => flag_P,
        rA_dbg => rA_dbg, rB_dbg => rB_dbg, PC_dbg => PC_dbg
    );

    clk <= not clk after 10 ns;
    reg_we <= '1';

    process
        variable errcnt : integer := 0;
        procedure tick is begin wait for 20 ns; end procedure;
        procedure idle_regs is
        begin
            Sba <= "00001";
            Sid <= "000";
            Sa  <= "00";
            Sas <= "00";
            LDF <= '0';
        end procedure;
    begin
        reset <= '1'; wait for 30 ns; reset <= '0'; wait for 10 ns;
        idle_regs;

        -- Zapis A = 7 (kod 00010)
        BA  <= to_signed(7, 16);
        Sba <= "00010";
        tick;
        if rA_dbg /= to_signed(7, 16) then
            errcnt := errcnt + 1; report "FAIL A write" severity error;
        else report "PASS A write" severity note; end if;

        Sbb <= "00010";
        wait for 5 ns;
        if BB /= to_signed(7, 16) then
            errcnt := errcnt + 1; report "FAIL BB=A" severity error;
        else report "PASS BB=A" severity note; end if;

        -- Zapis B = 2 (kod 00011)
        BA  <= to_signed(2, 16);
        Sba <= "00011";
        tick;
        idle_regs;
        Sbc <= "00011";
        wait for 5 ns;
        if rB_dbg /= to_signed(2, 16) or BC /= to_signed(2, 16) then
            errcnt := errcnt + 1; report "FAIL B" severity error;
        else report "PASS B" severity note; end if;

        -- PC++ (2 cykle)
        Sa  <= "01";
        Sid <= "001";
        tick; tick;
        idle_regs;
        if PC_dbg /= to_signed(2, 16) then
            errcnt := errcnt + 1; report "FAIL PC++" severity error;
        else report "PASS PC++" severity note; end if;

        -- Zapis IR (kod 00000)
        BA  <= x"A5A5";
        Sba <= "00000";
        tick;
        idle_regs;
        if IRout /= x"A5A5" then
            errcnt := errcnt + 1; report "FAIL IR" severity error;
        else report "PASS IR" severity note; end if;

        -- Rejestr znacznikow FLAGS przez LDF (kod odczytu 10010)
        FI  <= "1001";
        LDF <= '1';
        tick;
        idle_regs;
        if flag_C /= '1' or flag_Z /= '0' or flag_S /= '0' or flag_P /= '1' then
            errcnt := errcnt + 1; report "FAIL FLAGS LDF" severity error;
        else report "PASS FLAGS LDF" severity note; end if;

        Sbb <= "10010";
        wait for 5 ns;
        if BB(3 downto 0) /= "1001" then
            errcnt := errcnt + 1; report "FAIL FLAGS read" severity error;
        else report "PASS FLAGS read" severity note; end if;

        -- Rejestr segmentowy SEG1 (kod 11101)
        BA  <= to_signed(1, 16);
        Sba <= "11101";
        tick;
        idle_regs;
        Sas <= "01";
        wait for 5 ns;
        if SEGout /= to_signed(1, 16) then
            errcnt := errcnt + 1; report "FAIL SEG1" severity error;
        else report "PASS SEG1" severity note; end if;

        if errcnt = 0 then
            report "=== REGISTER_CPU_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== REGISTER_CPU_TB: BLEDY = " & integer'image(errcnt) severity error;
        end if;
        wait;
    end process;

end architecture behavior;
