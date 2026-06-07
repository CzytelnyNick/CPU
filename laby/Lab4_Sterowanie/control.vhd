library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Jednostka sterujaca — selektory 5-bitowe, 16 rejestrow A..P w polu 4-bit instrukcji

entity control is
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
        Sas       : out std_logic_vector(1 downto 0);
        LDF       : out std_logic;
        Smar      : out std_logic;
        Smbr      : out std_logic;
        WR        : out std_logic;
        RD        : out std_logic;
        INTA      : out std_logic;
        MIO       : out std_logic;
        state_dbg : out std_logic_vector(3 downto 0)
    );
end entity control;

architecture rtl of control is

    type state_type is (
        f0, f1, decode,
        exec_alu, exec_ldi,
        load_addr, load_read, load_write,
        store_addr, store_prep, store_write,
        jump_addr, brz_check, int_ack, halt
    );

    signal state : state_type := f0;

    -- Pole 4-bit instrukcji (0000=A .. 1111=P) -> kod 5-bit (00010..10001)
    function reg4_to_sel5(r : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(to_integer(unsigned(r)) + 2, 5));
    end function;

begin

    process(clk, reset)
    begin
        if reset = '1' then
            state <= f0;
        elsif rising_edge(clk) then
            case state is
                when f0       => state <= f1;
                when f1       => state <= decode;
                when decode   =>
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
                when exec_alu    => state <= f0;
                when exec_ldi    => state <= f0;
                when load_addr   => state <= load_read;
                when load_read   => state <= load_write;
                when load_write  => state <= f0;
                when store_addr  => state <= store_prep;
                when store_prep  => state <= store_write;
                when store_write => state <= f0;
                when jump_addr   => state <= f0;
                when brz_check   => state <= f0;
                when int_ack     => state <= f0;
                when halt        =>
                    if INT = '1' then state <= int_ack; else state <= halt; end if;
            end case;
        end if;
    end process;

    process(state, IR, Z)
        variable ir_slv : std_logic_vector(15 downto 0);
    begin
        ir_slv := std_logic_vector(IR);

        Sa    <= "00";
        Sas   <= "00";
        Sbb   <= "00001";
        Sbc   <= "00001";
        Sba   <= "11011";
        Sid   <= "000";
        Salu  <= "00000";
        LDF   <= '0';
        Smar  <= '0';
        Smbr  <= '0';
        WR    <= '0';
        RD    <= '0';
        INTA  <= '0';
        MIO   <= '0';
        state_dbg <= "0000";

        case state is
            when f0 =>
                Sa <= "01"; Sid <= "001"; Smar <= '1'; RD <= '1'; MIO <= '0';
                state_dbg <= "0000";

            when f1 =>
                Sba <= "00000"; MIO <= '1';
                state_dbg <= "0001";

            when decode =>
                state_dbg <= "0010";

            when exec_alu =>
                Salu <= ir_slv(12 downto 8);
                Sbb  <= reg4_to_sel5(ir_slv(7 downto 4));
                Sbc  <= reg4_to_sel5(ir_slv(3 downto 0));
                Sba  <= reg4_to_sel5(ir_slv(7 downto 4));
                LDF  <= '1';
                state_dbg <= "0011";

            when exec_ldi =>
                Salu <= "00000";
                Sbb  <= "00000";
                Sbc  <= "00001";
                Sba  <= reg4_to_sel5(ir_slv(12 downto 9));
                LDF  <= '1';
                state_dbg <= "0100";

            when load_addr =>
                Salu <= "00000";
                Sbb  <= "00000";
                Sbc  <= "00001";
                Sba  <= "11000";
                Sas  <= ir_slv(9 downto 8);
                state_dbg <= "0101";

            when load_read =>
                Sa <= "00"; Sas <= ir_slv(9 downto 8);
                Smar <= '1'; RD <= '1'; MIO <= '1';
                state_dbg <= "0110";

            when load_write =>
                Sba <= reg4_to_sel5(ir_slv(12 downto 9)); MIO <= '1';
                state_dbg <= "0111";

            when store_addr =>
                Salu <= "00000";
                Sbb  <= "00000";
                Sbc  <= "00001";
                Sba  <= "11000";
                Sas  <= ir_slv(9 downto 8);
                state_dbg <= "1000";

            when store_prep =>
                Sa <= "00"; Sas <= ir_slv(9 downto 8);
                Sbb <= reg4_to_sel5(ir_slv(12 downto 9));
                Smar <= '1'; Smbr <= '1';
                state_dbg <= "1001";

            when store_write =>
                Sa <= "00"; Sas <= ir_slv(9 downto 8); WR <= '1';
                state_dbg <= "1010";

            when jump_addr =>
                Salu <= "00000";
                Sbb  <= "00000";
                Sbc  <= "00001";
                Sba  <= "10100";
                state_dbg <= "1011";

            when brz_check =>
                if Z = '1' then
                    Salu <= "00000";
                    Sbb  <= "00000";
                    Sbc  <= "00001";
                    Sba  <= "10100";
                end if;
                state_dbg <= "1100";

            when int_ack =>
                INTA <= '1';
                state_dbg <= "1101";

            when halt =>
                state_dbg <= "1111";
        end case;
    end process;

end architecture rtl;
