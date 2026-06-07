library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- TESTBENCH: busint + RAM (Lab 3)
-- Sprawdza segmentacje adresu, odczyt z MIF i zapis/odczyt.
-- =============================================================

entity memory_tb is
end entity;

architecture behavior of memory_tb is

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

    signal clk, Smar, Smbr, WRin, RDin : std_logic := '0';
    signal ADR, DO, SEG                 : signed(31 downto 0) := (others => '0');
    signal bus_D                        : signed(15 downto 0);
    signal bus_DI, bus_AD               : signed(31 downto 0);
    signal bus_WR, bus_RD               : std_logic;
    signal phys_addr                    : std_logic_vector(15 downto 0);
    signal ram_data_out                 : std_logic_vector(15 downto 0);

begin

    bus_D <= signed(ram_data_out) when bus_RD = '1' else (others => 'Z');

    SEG <= x"0000";

    u_bus: busint port map (
        clk => clk, ADR => ADR, SEG => SEG(15 downto 0), DO => DO,
        Smar => Smar, Smbr => Smbr, WRin => WRin, RDin => RDin,
        AD => bus_AD, D => bus_D, DI => bus_DI,
        WR => bus_WR, RD => bus_RD, phys_addr_out => phys_addr
    );

    u_ram: ram port map (
        clk => clk, we => bus_WR,
        address => phys_addr(9 downto 0),
        data => std_logic_vector(bus_D),
        q => ram_data_out
    );

    clk <= not clk after 10 ns;

    process
        variable errcnt : integer := 0;

        procedure tick is
        begin
            wait for 20 ns;
        end procedure;

        procedure chk_phys(exp : std_logic_vector(15 downto 0); nm : string) is
        begin
            if phys_addr /= exp then
                report "FAIL [" & nm & "] phys=" & integer'image(to_integer(unsigned(phys_addr)))
                    & " exp=" & integer'image(to_integer(unsigned(exp))) severity error;
                errcnt := errcnt + 1;
            else
                report "PASS [" & nm & "]" severity note;
            end if;
        end procedure;

        procedure chk_di(exp : signed(15 downto 0); nm : string) is
        begin
            if bus_DI /= exp then
                report "FAIL [" & nm & "] DI" severity error;
                errcnt := errcnt + 1;
            else
                report "PASS [" & nm & "]" severity note;
            end if;
        end procedure;

        procedure mem_read(addr : signed(31 downto 0)) is
        begin
            ADR  <= addr;
            Smar <= '1';
            RDin <= '1';
            WRin <= '0';
            Smbr <= '0';
            tick;
            Smar <= '0';
            RDin <= '0';
            wait for 5 ns;
        end procedure;

        procedure mem_write(addr : signed(31 downto 0); data : signed(15 downto 0)) is
        begin
            ADR  <= addr;
            DO   <= data;
            Smar <= '1';
            Smbr <= '1';
            WRin <= '1';
            RDin <= '0';
            tick;
            WRin <= '0';
            Smbr <= '0';
            Smar <= '0';
            wait for 5 ns;
        end procedure;

    begin
        wait for 30 ns;

        -- Test 1: adres fizyczny = segment<<8 + offset
        ADR <= x"00000000";
        wait for 5 ns;
        chk_phys(x"0000", "addr PC=0");

        ADR <= x"00000105";
        wait for 5 ns;
        chk_phys(x"0105", "addr offset 5");

        SEG <= x"0002";
        ADR <= x"00000000";
        wait for 5 ns;
        chk_phys(x"0200", "addr segment 2 offset 0");
        SEG <= x"0000";

        -- Test 2: odczyt programu z ram_init.mif
        mem_read(x"00000000");
        chk_di(x"4007", "MIF addr0 LDI A,7");

        mem_read(x"00000001");
        chk_di(x"4202", "MIF addr1 LDI B,2");

        mem_read(x"00000002");
        chk_di(x"2201", "MIF addr2 ADD");

        mem_read(x"00000003");
        chk_di(x"1F00", "MIF addr3 HLT");

        mem_read(x"00000010");
        chk_di(x"00AB", "MIF addr16 test data");

        -- Test 3: zapis i odczyt
        mem_write(x"00000020", x"BEEF");
        mem_read(x"00000020");
        chk_di(x"BEEF", "write-read 0x20");

        mem_write(x"00000100", x"1234");
        mem_read(x"00000100");
        chk_di(x"1234", "write-read segment1");

        -- Nakladanie segmentow: SEG=1 offset 0 == SEG=0 offset 0x100
        SEG <= x"0001";
        ADR <= x"00000000";
        wait for 5 ns;
        chk_phys(x"0100", "overlap seg1 off0");
        SEG <= x"0000";
        ADR <= x"00000100";
        wait for 5 ns;
        chk_phys(x"0100", "overlap seg0 off100");

        if errcnt = 0 then
            report "=== MEMORY_TB: WSZYSTKIE TESTY PRZESZLY ===" severity note;
        else
            report "=== MEMORY_TB: LICZBA BLEDOW = " & integer'image(errcnt) severity error;
        end if;
        wait;
    end process;

end architecture behavior;
