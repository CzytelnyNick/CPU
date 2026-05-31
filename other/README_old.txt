================================================================
  PROJEKT PROCESORA - LAB 1 + LAB 2 + LAB 3
  Architektura Systemow Komputerowych (ASK)
================================================================

SPIS PLIKOW
-----------
  alu.vhd          - LAB 1: Jednostka Arytmetyczno-Logiczna
  register_cpu.vhd - LAB 2: Plik rejestrow procesora
  busint.vhd       - LAB 3: Uklad wspolpracy z pamiecia
  ram.vhd          - LAB 3: Pamiec RAM (1024 x 16-bit)
  hex_display.vhd  - Komponent: dekoder wyswietlacza 7-segmentowego
  top.vhd          - Top-Level: laczy wszystkie moduly
  README.txt       - Ten plik


================================================================
  OPIS MODULOW
================================================================

--- alu.vhd ---
  Jednostka Arytmetyczno-Logiczna, 16-bitowa.
  Wykonuje 16 operacji (kod 4-bitowy S_ALU):
    0000 PASS BB  - przepisanie BB
    0001 PASS BC  - przepisanie BC
    0010 ADD      - dodawanie BB + BC
    0011 SUB      - odejmowanie BB - BC
    0100 OR       - suma logiczna
    0101 AND      - iloczyn logiczny
    0110 XOR      - roznica symetryczna
    0111 XNOR     - rownowaznosc
    1000 NOT      - negacja bitowa BB
    1001 NEG      - negacja arytmetyczna (-BB, dopelnienie do 2)
    1010 CLR      - zerowanie wyjscia
    1011 ADC      - dodawanie z przeniesieniem (BB + BC + C_in)
    1100 SBB      - odejmowanie z pozyczka  (BB - BC - C_in)
    1101 INC      - inkrementacja BB + 1
    1110 SHL      - przesuniecie logiczne w lewo o 1
    1111 SHR      - przesuniecie logiczne w prawo o 1

  Flagi wyjsciowe:
    C - przeniesienie (Carry)
    Z - zero (Zero)
    S - znak (Sign) - najstarszy bit wyniku
    P - parzystosc (Parity) - P=1 gdy parzysta liczba jedynek

--- register_cpu.vhd ---
  Plik rejestrow procesora.
  Rejestry wewnetrzne:
    IR   (16-bit) - rejestr rozkazow
    TMP  (16-bit) - rejestr pomocniczy (ukryty)
    rA..rF (16-bit kazdy) - rejestry ogolnego przeznaczenia
    PC   (32-bit) - licznik rozkazow
    SP   (32-bit) - wskaznik stosu
    AD   (32-bit) - rejestr adresowy
    ATMP (32-bit) - pomocniczy rejestr adresowy (ukryty)

  3 szyny:
    BB  (16-bit wyj.) - argument 1 dla ALU
    BC  (16-bit wyj.) - argument 2 dla ALU
    ADR (32-bit wyj.) - adres logiczny dla busint

  Zapis synchroniczny (zbocze rosnace CLK) przez sygnal Sba.
  Odczyt asynchroniczny przez sygnaly Sbb / Sbc / Sa.

--- busint.vhd ---
  Uklad wspolpracy z pamiecia.
  Zawiera rejestry MAR i MBR (wewnetrzne).
  Obsluguje dwukierunkowa szyne danych D.
  Przelicza adres logiczny na fizyczny (segmentacja):
    Adres fizyczny = segment(1:0) << 8 + offset(7:0)
    Segment: ADR(9:8), Offset: ADR(7:0)
  4 segmenty po 256 slow, lacznie 1024 slowa.

--- ram.vhd ---
  Pamiec RAM 1024 slow x 16-bit.
  Synchroniczny zapis, asynchroniczny odczyt.
  Inicjalizowana przykladowymi wartosciami testowymi:
    adr 0=0x0001, 1=0x0002, 2=0x0003, 3=0xABCD, 4=0x1234, 5=0xFFFF
    adr 256=0x0010 (poczatek seg.1), 512=0x0020 (seg.2), 768=0x0030 (seg.3)

--- hex_display.vhd ---
  Dekoder 7-segmentowy, wspoldzielony przez wszystkie moduly.
  Wejscie 4-bit (0x0..0xF), wyjscie aktywne NISKIM stanem logicznym
  (standard plyt DE1-SoC i DE2i-150).

--- top.vhd ---
  Modul nadrzdny (Top-Level Entity w Quartus).
  Laczy: register_cpu -> alu -> busint -> ram -> hex_display.
  Ustawic jako "Top-Level Entity" w projekcie Quartus.


================================================================
  SCHEMAT POLACZEN
================================================================

  SW[7:0] --> reg_DI / reg_BA -----> [register_cpu]
  SW[7:4] --> Sbb (wybor rej. BB)         |
  SW[3:0] --> S_ALU (kod operacji)        |
  SW[9:8] --> mode (tryb pracy)           |
                                     BB --+--> [ALU] --> alu_Y
                                     BC --+        \--> flagi C,Z,S,P
                                     ADR --> [busint] --> [RAM]
                                              DI <---------/
                                    reg_BA <-- alu_Y / DI (zaleznie od trybu)
                                         \
                               [hex_display x6] --> HEX5..HEX0
                                    LEDR[9:0]


================================================================
  TRYBY PRACY (SW[9:8])
================================================================

  "00" - TRYB ALU
         SW[7:4] wybiera rejestr dla BB (argument 1)
         SW[3:0] wybiera operacje ALU
         HEX3..0: wynik ALU (16-bit hex)
         HEX4:    flagi {C, Z, S, P}
         HEX5:    kod operacji S_ALU
         Na zboczu KEY[0]: wynik zapisywany do rejestru rA

  "01" - TRYB ZAPIS DO RAM
         SW[7:0] = dane do zapisu ORAZ adres (offset, segment=0)
         Na zboczu KEY[0]: dane ladowane do MBR i zapisywane do RAM
         HEX3..0: dane zapisywane
         HEX4:    adres fizyczny [3:0]
         HEX5:    adres fizyczny [7:4]
         LEDR[8]: WR aktywny (swieci gdy zapis)

  "10" - TRYB ODCZYT Z RAM
         SW[7:0] = adres do odczytu (offset, segment=0)
         Na zboczu KEY[0]: dane odczytywane z RAM i ladowane do rA
         HEX3..0: dane odczytane z RAM
         HEX4:    adres fizyczny [3:0]
         HEX5:    adres fizyczny [7:4]
         LEDR[9]: RD aktywny (swieci gdy odczyt)

  "11" - TRYB DEBUG
         SW[7:4] wybiera rejestr do podgladniecia (Sbb)
         HEX3..0: zawartosc wybranego rejestru BB
         HEX4:    flagi ALU
         HEX5:    kod SW[3:0]


================================================================
  MAPOWANIE PRZELACZNIKOW I PRZYCISKOW
================================================================

  SW[0]  - bit 0 danych / adresu / kodu operacji ALU
  SW[1]  - bit 1
  SW[2]  - bit 2
  SW[3]  - bit 3  (MSB kodu operacji ALU / MSB adresu)
  SW[4]  - bit 0 selektora rejestru BB (Sbb)
  SW[5]  - bit 1 selektora rejestru BB (Sbb)
  SW[6]  - bit 2 selektora rejestru BB (Sbb)
  SW[7]  - bit 3 selektora rejestru BB (Sbb)
  SW[8]  - bit 0 trybu pracy (mode)
  SW[9]  - bit 1 trybu pracy (mode)

  KEY[0] - zegar (CLK) - kazde wcisniecie = 1 cykl
           UWAGA: aktywny NISKI, wewnatrz invertowany
  KEY[1] - reset asynchroniczny
           UWAGA: aktywny NISKI, wewnatrz invertowany


================================================================
  MAPOWANIE WYJSC
================================================================

  HEX0  - nibble 0 danych wynikowych (bity 3:0)
  HEX1  - nibble 1 danych wynikowych (bity 7:4)
  HEX2  - nibble 2 danych wynikowych (bity 11:8)
  HEX3  - nibble 3 danych wynikowych (bity 15:12)
  HEX4  - flagi ALU {C,Z,S,P} lub adres fizyczny [3:0]
  HEX5  - kod operacji lub adres fizyczny [7:4]

  LEDR[7:0] - dolne 8 bitow danych wynikowych
  LEDR[8]   - sygnal WR (swieci podczas zapisu do RAM)
  LEDR[9]   - sygnal RD (swieci podczas odczytu z RAM)


================================================================
  MAPA SELEKTORA REJESTROW (Sbb / Sbc)
================================================================

  Wartosc SW[7:4]  Rejestr na szynie BB
  0000 (0)         DI   (dane z przelacznikow SW[7:0])
  0001 (1)         TMP  (rejestr pomocniczy)
  0010 (2)         rA   (rejestr A)
  0011 (3)         rB   (rejestr B)
  0100 (4)         rC   (rejestr C)
  0101 (5)         rD   (rejestr D)
  0110 (6)         rE   (rejestr E)
  0111 (7)         rF   (rejestr F)
  1000 (8)         IR   (rejestr rozkazow)
  1001 (9)         PC[15:0]
  1010 (A)         PC[31:16]
  1011 (B)         SP[15:0]
  1100 (C)         SP[31:16]
  1101 (D)         AD[15:0]
  1110 (E)         ATMP[15:0]
  1111 (F)         ATMP[31:16]


================================================================
  INSTRUKCJA KONFIGURACJI W QUARTUS PRIME
================================================================

  1. Stworz nowy projekt w Quartus Prime
     File -> New Project Wizard
     - Katalog: ASK_NIESTACJONARNE/Nazwisko1_Nazwisko2/Lab1_2_3/
     - Nazwa projektu: procesor
     - Top-Level Entity: top

  2. Dodaj wszystkie pliki VHDL do projektu
     Project -> Add/Remove Files in Project
     Dodaj: alu.vhd, register_cpu.vhd, busint.vhd,
            ram.vhd, hex_display.vhd, top.vhd

  3. Wybierz uklad FPGA
     Assignments -> Device
     - DE1-SoC:   Cyclone V SoC  5CSEMA5F31C6
     - DE2i-150:  Cyclone IV     EP4CGX150DF31C7
     - DE10:      Cyclone V      5CSXFC6DF31C6N

  4. Przypisz piny (Assignments -> Pin Planner)
     Przykladowe przypisania dla DE1-SoC:
     (sprawdz dokumentacje plytki - Pin Assignments DE1)

     Wejscia:
       SW[0]  -> PIN_AB12
       SW[1]  -> PIN_AC12
       SW[2]  -> PIN_AF9
       SW[3]  -> PIN_AF10
       SW[4]  -> PIN_AD11
       SW[5]  -> PIN_AD12
       SW[6]  -> PIN_AE11
       SW[7]  -> PIN_AC9
       SW[8]  -> PIN_AD10
       SW[9]  -> PIN_AE12
       KEY[0] -> PIN_AA14
       KEY[1] -> PIN_AA15

     Wyjscia HEX (aktywne niskie):
       HEX0[0..6] -> PIN_AE26..PIN_AE22 (sprawdz DE1 pinout)
       HEX1[0..6] -> ...
       HEX2[0..6] -> ...
       HEX3[0..6] -> ...
       HEX4[0..6] -> ...
       HEX5[0..6] -> ...

     LEDR:
       LEDR[0] -> PIN_V16
       LEDR[1] -> PIN_W16
       ...
       LEDR[9] -> PIN_V15

     UWAGA: Dokladne numery pinow sprawdz w:
       - dokumentacji DE1-SoC (plik PDF z plytka)
       - lub Pin Assignments DE1 na stronie laboratorium

  5. Skompiluj projekt
     Processing -> Start Compilation  (Ctrl+L)

  6. Wgraj na plytke
     Tools -> Programmer -> Start


================================================================
  PRZYKLAD TESTOWANIA
================================================================

  TEST 1: Dodawanie (ADD) w trybie ALU
    - SW[9:8] = "00"  (tryb ALU)
    - Najpierw zaladuj wartosc do rA:
        SW[7:4] = "0000" (Sbb = DI)
        SW[3:0] = "0101" (wartosc = 5)
        Wcisij KEY[0] -> rA = 0x0005
    - Zaladuj wartosc do rB:
        SW[7:4] = "0000", SW[3:0] = "0011" (wartosc = 3)
        Zmien Sba na rB (w top.vhd Sba="0011") -> rB = 0x0003
    - Wykonaj ADD:
        SW[7:4] = "0010" (Sbb = rA)
        SW[3:0] = "0010" (S_ALU = ADD)
        HEX3..0 powinno pokazac 0008
        HEX4: flagi (Z=0, C=0, S=0, P=1 -> 0010 = 2 -> wyswietla "2")

  TEST 2: Odczyt z RAM
    - SW[9:8] = "10"  (tryb ODCZYT)
    - SW[7:0] = "00000011" (adres 3, segment 0)
    - Wcisij KEY[0]
    - HEX3..0 powinno pokazac ABCD (wartosc inicjalizacyjna pod adresem 3)
    - LEDR[9] swieci (RD aktywny)

  TEST 3: Zapis i odczyt RAM
    - SW[9:8] = "01"  (tryb ZAPIS)
    - SW[7:0] = "01000010" (adres=dane=0x42)
    - Wcisij KEY[0] -> zapisano 0x0042 pod adres 0x42
    - SW[9:8] = "10"  (tryb ODCZYT)
    - SW[7:0] = "01000010" (ten sam adres)
    - Wcisij KEY[0]
    - HEX3..0 powinno pokazac 0042


================================================================
  SEGMENTACJA PAMIECI
================================================================

  Adres logiczny (z rejestru AD, 32-bit):
    bity  9:8  = numer segmentu (0..3)
    bity  7:0  = offset (0..255)

  Adres fizyczny (10-bit):
    = segment << 8 + offset

  Przyklad:
    segment=1, offset=5 -> adres fizyczny = 256 + 5 = 261

  Mapa pamieci RAM:
    Segment 0: adresy   0..255   (kod programu / dane)
    Segment 1: adresy 256..511   (dane)
    Segment 2: adresy 512..767   (dane)
    Segment 3: adresy 768..1023  (dane / stos)

  Segmenty moga sie nakladac (gdy rejestry segmentow wskazuja
  ten sam obszar fizyczny).


================================================================
  AUTORZY / INFORMACJE
================================================================

  Projekt: Laboratorium ASK (Architektura Systemow Komputerowych)
  Plytki:  DE1-SoC / DE2i-150 / DE10
  Jezyk:   VHDL (Quartus Prime)

================================================================
