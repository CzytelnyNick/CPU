library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- LAB 2: Plik rejestrow procesora (z resetem asynchronicznym)
--
-- Wejscia:
--   clk   - zegar systemowy
--   reset - reset asynchroniczny aktywny WYSOKI
--           (podlaczone do not KEY[1] w top.vhd)
--   DI    - dane wejsciowe z magistrali danych (16-bit)
--   BA    - dane do zapisu do rejestru (16-bit)
--   Sbb   - selektor wyjscia BB (4-bit)
--   Sbc   - selektor wyjscia BC (4-bit)
--   Sba   - selektor rejestru docelowego zapisu (4-bit)
--   Sid   - selektor inkrementacji/dekrementacji (3-bit)
--   Sa    - selektor wyjscia adresowego (2-bit)
--
-- Wyjscia:
--   BB    - szyna B: argument 1 dla ALU (16-bit)
--   BC    - szyna C: argument 2 dla ALU (16-bit)
--   ADR   - wyjscie adresowe do busint (32-bit)
--   IRout - zawartosc rejestru rozkazow IR (16-bit)
--
-- Mapa Sba (zapis synchroniczny):
--   0000=IR   0001=TMP  0010=rA   0011=rB
--   0100=rC   0101=rD   0110=rE   0111=rF
--   1000=PC[15:0]   1001=PC[31:16]
--   1010=SP[15:0]   1011=SP[31:16]
--   1100=AD[15:0]   1101=AD[31:16]
--   1110=ATMP[15:0] 1111=ATMP[31:16]
--
-- Mapa Sbb / Sbc (odczyt asynchroniczny):
--   0000=DI   0001=TMP  0010=rA   0011=rB
--   0100=rC   0101=rD   0110=rE   0111=rF
--   1000=IR   1001=PC[15:0]  1010=PC[31:16]
--   1011=SP[15:0]  1100=SP[31:16]
--   1101=AD[15:0]  1110=ATMP[15:0]  1111=ATMP[31:16]
--
-- Mapa Sid:
--   000=brak  001=PC+1  010=SP+1  011=SP-1  100=AD+1  101=AD-1
--
-- Mapa Sa:
--   00=AD  01=PC  10=SP  11=ATMP
-- =============================================================

entity register_cpu is
    port (
        clk   : in  std_logic;
        reset : in  std_logic;
        DI    : in  signed(15 downto 0);
        BA    : in  signed(15 downto 0);
        Sbb   : in  signed(3 downto 0);
        Sbc   : in  signed(3 downto 0);
        Sba   : in  signed(3 downto 0);
        Sid   : in  signed(2 downto 0);
        Sa    : in  signed(1 downto 0);
        BB    : out signed(15 downto 0);
        BC    : out signed(15 downto 0);
        ADR   : out signed(31 downto 0);
        IRout : out signed(15 downto 0)
    );
end entity register_cpu;

architecture rtl of register_cpu is
begin

    process (clk, reset, Sbb, Sbc, Sa, DI)
        variable IR  : signed(15 downto 0) := (others => '0');
        variable TMP : signed(15 downto 0) := (others => '0');
        variable rA  : signed(15 downto 0) := (others => '0');
        variable rB  : signed(15 downto 0) := (others => '0');
        variable rC  : signed(15 downto 0) := (others => '0');
        variable rD  : signed(15 downto 0) := (others => '0');
        variable rE  : signed(15 downto 0) := (others => '0');
        variable rF  : signed(15 downto 0) := (others => '0');
        variable PC   : signed(31 downto 0) := (others => '0');
        variable SP   : signed(31 downto 0) := (others => '0');
        variable AD   : signed(31 downto 0) := (others => '0');
        variable ATMP : signed(31 downto 0) := (others => '0');
    begin

        -- ====================================================
        -- Reset asynchroniczny - zeruje wszystkie rejestry
        -- ====================================================
        if reset = '1' then
            IR   := (others => '0');
            TMP  := (others => '0');
            rA   := (others => '0');
            rB   := (others => '0');
            rC   := (others => '0');
            rD   := (others => '0');
            rE   := (others => '0');
            rF   := (others => '0');
            PC   := (others => '0');
            SP   := (others => '0');
            AD   := (others => '0');
            ATMP := (others => '0');

        -- ====================================================
        -- Zapis synchroniczny (zbocze rosnace)
        -- ====================================================
        elsif (clk'event and clk = '1') then

            case Sid is
                when "001" => PC   := PC   + 1;
                when "010" => SP   := SP   + 1;
                when "011" => SP   := SP   - 1;
                when "100" => AD   := AD   + 1;
                when "101" => AD   := AD   - 1;
                when others => null;
            end case;

            case Sba is
                when "0000" => IR               := BA;
                when "0001" => TMP              := BA;
                when "0010" => rA               := BA;
                when "0011" => rB               := BA;
                when "0100" => rC               := BA;
                when "0101" => rD               := BA;
                when "0110" => rE               := BA;
                when "0111" => rF               := BA;
                when "1000" => PC(15 downto 0)  := BA;
                when "1001" => PC(31 downto 16) := BA;
                when "1010" => SP(15 downto 0)  := BA;
                when "1011" => SP(31 downto 16) := BA;
                when "1100" => AD(15 downto 0)  := BA;
                when "1101" => AD(31 downto 16) := BA;
                when "1110" => ATMP(15 downto 0)  := BA;
                when "1111" => ATMP(31 downto 16) := BA;
                when others => null;
            end case;

        end if;

        -- ====================================================
        -- Odczyt asynchroniczny - szyna BB
        -- ====================================================
        case Sbb is
            when "0000" => BB <= DI;
            when "0001" => BB <= TMP;
            when "0010" => BB <= rA;
            when "0011" => BB <= rB;
            when "0100" => BB <= rC;
            when "0101" => BB <= rD;
            when "0110" => BB <= rE;
            when "0111" => BB <= rF;
            when "1000" => BB <= IR;
            when "1001" => BB <= PC(15 downto 0);
            when "1010" => BB <= PC(31 downto 16);
            when "1011" => BB <= SP(15 downto 0);
            when "1100" => BB <= SP(31 downto 16);
            when "1101" => BB <= AD(15 downto 0);
            when "1110" => BB <= ATMP(15 downto 0);
            when "1111" => BB <= ATMP(31 downto 16);
            when others => BB <= (others => '0');
        end case;

        -- ====================================================
        -- Odczyt asynchroniczny - szyna BC
        -- ====================================================
        case Sbc is
            when "0000" => BC <= DI;
            when "0001" => BC <= TMP;
            when "0010" => BC <= rA;
            when "0011" => BC <= rB;
            when "0100" => BC <= rC;
            when "0101" => BC <= rD;
            when "0110" => BC <= rE;
            when "0111" => BC <= rF;
            when "1000" => BC <= IR;
            when "1001" => BC <= PC(15 downto 0);
            when "1010" => BC <= PC(31 downto 16);
            when "1011" => BC <= SP(15 downto 0);
            when "1100" => BC <= SP(31 downto 16);
            when "1101" => BC <= AD(15 downto 0);
            when "1110" => BC <= ATMP(15 downto 0);
            when "1111" => BC <= ATMP(31 downto 16);
            when others => BC <= (others => '0');
        end case;

        -- ====================================================
        -- Wyjscie adresowe
        -- ====================================================
        case Sa is
            when "00" => ADR <= AD;
            when "01" => ADR <= PC;
            when "10" => ADR <= SP;
            when "11" => ADR <= ATMP;
            when others => ADR <= (others => '0');
        end case;

        IRout <= IR;

    end process;

end architecture rtl;