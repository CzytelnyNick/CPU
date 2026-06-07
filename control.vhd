library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- Jednostka sterujaca procesora
--
-- Cykl pracy:
--   f0       - wystaw PC na adres, czytaj pamiec, PC = PC + 1
--   f1       - przepisz slowo z pamieci do IR
--   decode   - dekoduj IR
--   execute  - wykonaj mikrooperacje dla instrukcji
--
-- Format instrukcji:
--   000 xxxxx ........  NOP/HLT
--       IR[12:8] = 11111 -> HLT
--
--   001 ooooo dddd ssss ALU: R[d] = R[d] op R[s]
--       IR[12:8] = 5-bitowy kod ALU
--       IR[7:4]  = rejestr docelowy i argument BB
--       IR[3:0]  = rejestr zrodlowy BC
--
--   010 dddd 0 iiiiiiii LDI: R[d] = imm8
--   011 dddd 0 aaaaaaaa LOAD: R[d] = MEM[addr8]
--   100 ssss 0 aaaaaaaa STORE: MEM[addr8] = R[s]
--   101 0000 0 aaaaaaaa JMP addr8
--   110 0000 0 aaaaaaaa BRZ addr8, gdy Z=1
-- =============================================================

entity control is
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
end entity control;

architecture rtl of control is
    type state_type is (
        f0, f1, decode,
        exec_alu,
        exec_ldi,
        load_addr, load_read, load_write,
        store_addr, store_prep, store_write,
        jump_addr,
        brz_check,
        int_ack,
        halt
    );

    signal state : state_type := f0;
begin

    process(clk, reset)
    begin
        if reset = '1' then
            state <= f0;
        elsif rising_edge(clk) then
            case state is
                when f0 =>
                    state <= f1;

                when f1 =>
                    state <= decode;

                when decode =>
                    if INT = '1' then
                        state <= int_ack;
                    else
                        case std_logic_vector(IR(15 downto 13)) is
                            when "000" =>
                                if std_logic_vector(IR(12 downto 8)) = "11111" then
                                    state <= halt;
                                else
                                    state <= f0;
                                end if;
                            when "001" => state <= exec_alu;
                            when "010" => state <= exec_ldi;
                            when "011" => state <= load_addr;
                            when "100" => state <= store_addr;
                            when "101" => state <= jump_addr;
                            when "110" => state <= brz_check;
                            when others => state <= f0;
                        end case;
                    end if;

                when exec_alu =>
                    state <= f0;

                when exec_ldi =>
                    state <= f0;

                when load_addr =>
                    state <= load_read;

                when load_read =>
                    state <= load_write;

                when load_write =>
                    state <= f0;

                when store_addr =>
                    state <= store_prep;

                when store_prep =>
                    state <= store_write;

                when store_write =>
                    state <= f0;

                when jump_addr =>
                    state <= f0;

                when brz_check =>
                    state <= f0;

                when int_ack =>
                    state <= f0;

                when halt =>
                    if INT = '1' then
                        state <= int_ack;
                    else
                        state <= halt;
                    end if;
            end case;
        end if;
    end process;

    process(state, IR, Z)
        variable ir_slv : std_logic_vector(15 downto 0);
    begin
        ir_slv := std_logic_vector(IR);

        -- Wartosc bezpieczna: brak zapisu i brak dostepu do pamieci.
        Sa    <= "00";     -- ADR = AD
        Sbb   <= "0001";   -- TMP
        Sbc   <= "0001";   -- TMP
        Sba   <= "1111";   -- ATMP high jako nieistotny cel
        Sid   <= "000";
        Salu  <= "00000";  -- ADD
        LDF   <= '0';
        Smar  <= '0';
        Smbr  <= '0';
        WR    <= '0';
        RD    <= '0';
        INTA  <= '0';
        MIO   <= '0';      -- 0=wynik ALU, 1=dane z pamieci
        state_dbg <= "0000";

        case state is
            when f0 =>
                Sa    <= "01";     -- adres = PC
                Sid   <= "001";    -- PC = PC + 1
                Smar  <= '1';
                RD    <= '1';
                MIO   <= '1';
                state_dbg <= "0000";

            when f1 =>
                Sba   <= "0000";   -- IR
                MIO   <= '1';      -- IR = bus_DI
                state_dbg <= "0001";

            when decode =>
                state_dbg <= "0010";

            when exec_alu =>
                Salu  <= ir_slv(12 downto 8);
                Sbb   <= ir_slv(7 downto 4); -- dst jako BB
                Sbc   <= ir_slv(3 downto 0); -- src jako BC
                Sba   <= ir_slv(7 downto 4); -- zapis do dst
                LDF   <= '1';
                state_dbg <= "0011";

            when exec_ldi =>
                -- Top-level podaje imm8 na DI. ADD DI + TMP(0) zapisuje imm.
                Salu  <= "00000";
                Sbb   <= "0000";   -- DI
                Sbc   <= "0001";   -- TMP = 0 po resecie
                Sba   <= ir_slv(12 downto 9);
                LDF   <= '1';
                state_dbg <= "0100";

            when load_addr =>
                -- AD[15:0] = imm8
                Salu  <= "00000";
                Sbb   <= "0000";   -- DI = imm8
                Sbc   <= "0001";   -- TMP = 0
                Sba   <= "1100";   -- AD low
                state_dbg <= "0101";

            when load_read =>
                Sa    <= "00";     -- adres = AD
                Smar  <= '1';
                RD    <= '1';
                MIO   <= '1';
                state_dbg <= "0110";

            when load_write =>
                Sba   <= ir_slv(12 downto 9);
                MIO   <= '1';
                state_dbg <= "0111";

            when store_addr =>
                -- AD[15:0] = imm8
                Salu  <= "00000";
                Sbb   <= "0000";   -- DI = imm8
                Sbc   <= "0001";
                Sba   <= "1100";   -- AD low
                state_dbg <= "1000";

            when store_prep =>
                Sa    <= "00";
                Sbb   <= ir_slv(12 downto 9); -- dane do busint.DO
                Smar  <= '1';
                Smbr  <= '1';
                state_dbg <= "1001";

            when store_write =>
                Sa    <= "00";
                WR    <= '1';
                state_dbg <= "1010";

            when jump_addr =>
                -- PC[15:0] = imm8
                Salu  <= "00000";
                Sbb   <= "0000";   -- DI = imm8
                Sbc   <= "0001";
                Sba   <= "1000";   -- PC low
                state_dbg <= "1011";

            when brz_check =>
                if Z = '1' then
                    Salu <= "00000";
                    Sbb  <= "0000";
                    Sbc  <= "0001";
                    Sba  <= "1000"; -- PC low
                end if;
                state_dbg <= "1100";

            when int_ack =>
                INTA  <= '1';
                state_dbg <= "1101";

            when halt =>
                state_dbg <= "1111";
        end case;
    end process;

end architecture rtl;