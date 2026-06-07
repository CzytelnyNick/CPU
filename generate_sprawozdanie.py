#!/usr/bin/env python3
"""Generuje sprawozdanie LAB 10-15 w formacie .docx pod projekt CPU."""

from pathlib import Path

try:
    from docx import Document
    from docx.shared import Pt, Cm, RGBColor
    from docx.enum.text import WD_ALIGN_PARAGRAPH
    from docx.enum.table import WD_TABLE_ALIGNMENT
except ImportError:
    raise SystemExit("Zainstaluj: pip install python-docx")

OUT = Path(__file__).parent / "SPRAWOZDANIE_PROCESOR.docx"


def add_placeholder(doc, text, color=RGBColor(0xC0, 0x00, 0x00)):
    p = doc.add_paragraph()
    r = p.add_run(text)
    r.italic = True
    r.font.color.rgb = color
    r.font.size = Pt(11)


def add_code(doc, text):
    p = doc.add_paragraph()
    r = p.add_run(text)
    r.font.name = "Consolas"
    r.font.size = Pt(8)


def add_table(doc, headers, rows):
    t = doc.add_table(rows=1 + len(rows), cols=len(headers))
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, h in enumerate(headers):
        t.rows[0].cells[i].text = h
        for p in t.rows[0].cells[i].paragraphs:
            for r in p.runs:
                r.bold = True
    for ri, row in enumerate(rows):
        for ci, val in enumerate(row):
            t.rows[ri + 1].cells[ci].text = str(val)
    doc.add_paragraph()


def build():
    doc = Document()

    # --- Strona tytułowa ---
    for line in [
        "Politechnika Krakowska",
        "Wydział Inżynierii Elektrycznej i Komputerowej",
        "Studia Stacjonarne, Informatyka w Inżynierii Komputerowej",
        "",
        "Sprawozdanie z przedmiotu",
        "Architektury Systemów Komputerowych",
        "",
        "Prowadzący: mgr inż. Dariusz Dorota",
        "",
        "Temat",
        "Laboratorium 10–15: Projekt procesora w VHDL",
        "",
        "Wykonali:",
    ]:
        p = doc.add_paragraph(line)
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER

    add_placeholder(doc, "[WPISZ: Imię Nazwisko 1]", RGBColor(0, 0, 255))
    add_placeholder(doc, "[WPISZ: Imię Nazwisko 2 — opcjonalnie]", RGBColor(0, 0, 255))

    doc.add_page_break()

    # --- Wstęp ---
    doc.add_heading("Wstęp", level=1)
    doc.add_paragraph(
        "Celem laboratoriów 10–15 było zaprojektowanie i zaimplementowanie 16-bitowego "
        "procesora w języku VHDL oraz weryfikacja jego działania w symulacji i na płytce FPGA."
    )
    doc.add_paragraph("Procesor składa się z 4 podstawowych części:")
    for item in [
        "ALU — jednostka arytmetyczno-logiczna (Lab 1)",
        "Rejestry — plik rejestrów procesora (Lab 2)",
        "Pamięć — układ współpracy z pamięcią busint + RAM (Lab 3)",
        "Układ sterujący — maszyna stanów control (Lab 4)",
    ]:
        doc.add_paragraph(item, style="List Bullet")

    doc.add_paragraph(
        "Komponenty zostały połączone w module top-level CPU.vhd. Program testowy "
        "znajduje się w pliku ram_init.mif. Po resecie procesor wykonuje sekwencję: "
        "LDI A,7 → LDI B,2 → ADD A,A,B → HLT, uzyskując wynik A = 9."
    )

    # --- ALU ---
    doc.add_heading("ALU", level=1)
    doc.add_paragraph(
        "Jednostka arytmetyczno-logiczna (ALU) wykonuje operacje na dwóch 16-bitowych "
        "argumentach BB i BC. Kod operacji S_ALU ma 5 bitów (20 rozkazów). ALU generuje flagi: "
        "C (carry), Z (zero), S (sign), P (parzystość even)."
    )

    doc.add_heading("1. Schemat koncepcyjny", level=2)
    add_placeholder(doc, "[WSTAW RYSUNEK: Schemat koncepcyjny ALU — dwa wejścia BB/BC, wejście S_ALU, wyjście Y, flagi C/Z/S/P. Możesz użyć rysunku z materiałów ćwiczeń lub zrobić screenshot z Quartus RTL Viewer dla alu.vhd]")

    doc.add_heading("2. Symbol ALU", level=2)
    add_placeholder(doc, "[WSTAW RYSUNEK: Symbol blokowy ALU z portami clk, BB[15:0], BC[15:0], S_ALU[4:0], C_in, Y[15:0], C, Z, S, P]")

    doc.add_heading("3. Rodzaje operacji", level=2)
    for item in ["arytmetyczne (ADD, SUB, INC, ADC, SBB, NEG)", "logiczne (OR, AND, XOR, XNOR, NOT)", "przesunięcia (SHL, SHR)", "przepisanie i zerowanie (PASS BB, PASS BC, CLR)"]:
        doc.add_paragraph(item, style="List Bullet")

    doc.add_heading("4. Rozkazy obsługiwane przez nasze ALU", level=2)
    add_table(doc, ["Numer", "Rozkaz", "Kod S_ALU"], [
        ["0", "Y = BB", "00000"], ["1", "Y = BC", "00001"], ["2", "Y = BB + BC", "00010"],
        ["3", "Y = BB - BC", "00011"], ["4", "Y = BB OR BC", "00100"], ["5", "Y = BB AND BC", "00101"],
        ["6", "Y = BB XOR BC", "00110"], ["7", "Y = BB XNOR BC", "00111"], ["8", "Y = NOT BB", "01000"],
        ["9", "Y = -BB", "01001"], ["10", "Y = 0", "01010"], ["11", "Y = BB + BC + C", "01011"],
        ["12", "Y = BB - BC - C", "01100"], ["13", "Y = BB + 1", "01101"],
        ["14", "Y = BB SHL 1", "01110"], ["15", "Y = BB SHR 1", "01111"],
        ["16", "Y = NOT BC", "10000"], ["17", "Y = -BC", "10001"],
        ["18", "Y = BC + 1", "10010"], ["19", "Y = BB - 1", "10011"],
    ])
    doc.add_paragraph(
        "Uwaga: W zintegrowanym procesorze wejście C_in jest na stałe ustawione na 0, "
        "więc ADC i SBB działają jak ADD i SUB."
    )

    doc.add_heading("5. Kod VHDL", level=2)
    doc.add_paragraph("Plik źródłowy: alu.vhd")
    add_code(doc, """entity alu is
    Port (
        clk   : in  STD_LOGIC;
        BB    : in  STD_LOGIC_VECTOR(15 downto 0);
        BC    : in  STD_LOGIC_VECTOR(15 downto 0);
        S_ALU : in  STD_LOGIC_VECTOR(4 downto 0);
        S_F   : in  STD_LOGIC;
        C_in  : in  STD_LOGIC;
        Y     : out STD_LOGIC_VECTOR(15 downto 0);
        C, Z, S, P : out STD_LOGIC
    );
end alu;""")
    add_placeholder(doc, "[WSTAW ZDJĘCIE: Fragment kodu alu.vhd w edytorze Quartus — proces case S_ALU lub pełny plik jako listing]")

    doc.add_heading("6. Symulacja ALU", level=2)
    doc.add_paragraph("Testbench: alu_tb.vhd — samosprawdzający, testuje wszystkie 20 operacji i flagi.")
    doc.add_paragraph("Uruchomienie w QuestaSim:")
    add_code(doc, "do run_tests.do   ;# lub: vsim work.alu_tb, run -all")
    doc.add_paragraph("Przykładowe przypadki testowe:")
    add_table(doc, ["Test", "BB", "BC", "S_ALU", "Y (hex)", "C", "Z", "S", "P"], [
        ["ADD 7+2", "0007", "0002", "00010", "0009", "0", "0", "0", "1"],
        ["SUB 7-2", "0007", "0002", "00011", "0005", "0", "0", "0", "1"],
        ["NOT BC", "0000", "0003", "10000", "FFFC", "0", "0", "1", "0"],
        ["DEC BB", "0008", "0000", "10011", "0007", "0", "0", "0", "0"],
        ["CLR", "1234", "5678", "01010", "0000", "0", "1", "0", "1"],
    ])
    add_placeholder(doc, "[WSTAW SCREENSHOT: Waveform symulacji alu_tb — sygnały BB, BC, S_ALU, Y, C, Z, S, P]")
    add_placeholder(doc, "[WSTAW SCREENSHOT: Okno Transcript z komunikatem === ALU_TB: WSZYSTKIE TESTY PRZESZLY ===]")

    doc.add_page_break()

    # --- Rejestry ---
    doc.add_heading("Rejestry", level=1)
    doc.add_paragraph(
        "Plik rejestrów (register_cpu.vhd) implementuje 16 rejestrów roboczych A..P "
        "oraz IR, TMP, PC, SP, AD, ATMP. Selektory Sba/Sbb/Sbc są 5-bitowe. "
        "Zapis synchroniczny (Sba, BA), odczyt asynchroniczny (Sbb, Sbc)."
    )

    doc.add_heading("1. Symbol i rodzaje rejestrów", level=2)
    add_placeholder(doc, "[WSTAW RYSUNEK: Diagram rejestrów procesora — IR, PC, SP, AD, A-P (16 rejestrów), TMP, ATMP, szyny BB/BC/ADR]")
    add_table(doc, ["Rejestr", "Szerokość", "Rola"], [
        ["A..P", "16×16 bit", "16 rejestrów roboczych ogólnego przeznaczenia"],
        ["IR", "16 bit", "Aktualna instrukcja"], ["PC", "32 bit", "Licznik rozkazów"],
        ["SP", "32 bit", "Wskaźnik stosu"], ["AD", "32 bit", "Rejestr adresowy"],
        ["TMP, ATMP", "16/32 bit", "Rejestry pomocnicze (ukryte)"],
        ["MAR, MBR", "w busint", "Bufor adresu i danych pamięci"],
    ])

    doc.add_heading("2. Mapa selektorów 5-bitowych", level=2)
    add_table(doc, ["Kod 5-bit", "Zapis Sba / Odczyt Sbb,Sbc"], [
        ["00000", "IR (zapis) / DI (odczyt)"], ["00001", "TMP"],
        ["00010", "A"], ["00011", "B"], ["00100", "C"], ["00101", "D"],
        ["00110", "E"], ["00111", "F"], ["01000", "G"], ["01001", "H"],
        ["01010", "I"], ["01011", "J"], ["01100", "K"], ["01101", "L"],
        ["01110", "M"], ["01111", "N"], ["10000", "O"], ["10001", "P"],
        ["11100", "IR (odczyt Sbb/Sbc)"], ["10100", "PC[15:0]"], ["10101", "PC[31:16]"],
        ["10110", "SP[15:0]"], ["10111", "SP[31:16]"], ["11000", "AD[15:0]"],
        ["11001", "AD[31:16]"], ["11010", "ATMP[15:0]"], ["11011", "ATMP[31:16]"],
    ])
    doc.add_paragraph(
        "W polu instrukcji (4 bity): 0000=A, 0001=B, …, 1111=P. "
        "Jednostka sterująca przelicza na kod 5-bit: rejestr + 2."
    )
    doc.add_paragraph("Sid: 001=PC+1, 010=SP+1, 011=SP-1, 100=AD+1, 101=AD-1")
    doc.add_paragraph("Sa: 00=ADR=AD, 01=ADR=PC, 10=ADR=SP, 11=ADR=ATMP")

    doc.add_heading("3. Kod VHDL", level=2)
    doc.add_paragraph("Plik źródłowy: register_cpu.vhd")
    add_placeholder(doc, "[WSTAW ZDJĘCIE: Fragment register_cpu.vhd — mapa Sba / proces zapisu]")

    doc.add_heading("4. Symulacja rejestrów", level=2)
    doc.add_paragraph(
        "Dodano testbench register_cpu_tb.vhd (nowy plik w projekcie) do weryfikacji: "
        "zapisu/odczytu rA i rB, inkrementacji PC oraz zapisu IR."
    )
    add_code(doc, "vcom -93 register_cpu.vhd register_cpu_tb.vhd\nvsim work.register_cpu_tb\nrun -all")
    add_placeholder(doc, "[WSTAW SCREENSHOT: Waveform register_cpu_tb — rA_dbg, rB_dbg, PC_dbg, BB, BC, IRout]")
    add_placeholder(doc, "[WSTAW SCREENSHOT: Transcript — REGISTER_CPU_TB: WSZYSTKIE TESTY PRZESZLY]")

    doc.add_page_break()

    # --- Pamięć ---
    doc.add_heading("Pamięć (układ współpracy z pamięcią)", level=1)
    doc.add_paragraph(
        "Moduł busint.vhd realizuje współpracę z pamięcią RAM: rejestry MAR i MBR, "
        "szyna danych dwukierunkowa, segmentacja adresu (4 segmenty × 256 słów)."
    )

    doc.add_heading("1. Schemat", level=2)
    add_placeholder(doc, "[WSTAW RYSUNEK: Schemat busint — ADR, DO, MAR, MBR, szyna D, sygnały Smar/Smbr/WR/RD, połączenie z RAM]")
    add_table(doc, ["Parametr", "Wartość"], [
        ["Szyna danych", "16 bit"], ["Szyna adresowa (logiczna)", "32 bit"],
        ["Adres fizyczny RAM", "10 bit (1024 słów)"],
        ["Segment", "ADR(9:8)"], ["Offset", "ADR(7:0)"],
        ["Zapis", "WR = 1"], ["Odczyt", "RD = 1"],
    ])

    doc.add_heading("2. Współpraca procesora z pamięcią", level=2)
    add_placeholder(doc, "[WSTAW RYSUNEK: Sekwencja fetch — PC → ADR → busint → RAM → DI → IR]")
    doc.add_paragraph(
        "W CPU.vhd szyna D łączy busint z RAM: przy RD=1 dane z ram.q trafiają na szynę; "
        "przy WR=1 busint wystawia dane do zapisu."
    )

    doc.add_heading("3. Sygnały sterujące pamięcią", level=2)
    add_table(doc, ["Sygnał", "Znaczenie"], [
        ["Smar", "1 = załaduj MAR z ADR"], ["Smbr", "1 = załaduj MBR z DO (reg_BB)"],
        ["WRin / WR", "1 = zapis do RAM"], ["RDin / RD", "1 = odczyt z RAM"],
        ["DI", "Dane odczytane z pamięci → rejestry / IR"],
    ])

    doc.add_heading("4. Kod VHDL", level=2)
    doc.add_paragraph("Pliki: busint.vhd, ram.vhd")
    add_placeholder(doc, "[WSTAW ZDJĘCIE: Fragment busint.vhd i ram.vhd]")

    doc.add_heading("5. Symulacja pamięci", level=2)
    doc.add_paragraph(
        "Pamięć testowana w ramach symulacji całego procesora (cpu_tb) oraz na płytce. "
        "Program i dane inicjalizowane z ram_init.mif."
    )
    add_placeholder(doc, "[WSTAW SCREENSHOT: Waveform — phys_addr, bus_RD, bus_WR, ram_data_out, reg_IR podczas fetch]")
    add_placeholder(doc, "[WSTAW ZDJĘCIE: Zawartość ram_init.mif w edytorze Quartus]")

    doc.add_page_break()

    # --- Sterowanie ---
    doc.add_heading("Układ sterujący (sterowanie)", level=1)
    doc.add_paragraph(
        "Jednostka sterująca control.vhd implementuje maszynę stanów: "
        "f0 (fetch) → f1 (load IR) → decode → execute → powrót do f0 lub halt."
    )

    doc.add_heading("1. Schemat", level=2)
    add_placeholder(doc, "[WSTAW RYSUNEK: Diagram maszyny stanów — f0, f1, decode, exec_alu, exec_ldi, load_*, store_*, jump, brz, halt]")

    doc.add_heading("2. Mapa rejestrów (kody 4-bit)", level=2)
    add_table(doc, ["Kod 4-bit (w IR)", "Rejestr"], [
        ["0000", "A"], ["0001", "B"], ["0010", "C"], ["0011", "D"],
        ["0100", "E"], ["0101", "F"], ["0110", "G"], ["0111", "H"],
        ["1000", "I"], ["1001", "J"], ["1010", "K"], ["1011", "L"],
        ["1100", "M"], ["1101", "N"], ["1110", "O"], ["1111", "P"],
    ])

    doc.add_heading("3. Rozkazy obsługiwane przez sterowanie", level=2)
    add_table(doc, ["Typ IR[15:13]", "Mnemonik", "Format", "Opis"], [
        ["000", "NOP/HLT", "000 11111 ...", "HLT gdy IR[12:8]=11111"],
        ["001", "ALU", "001 ooooo dddd ssss", "R[d] = R[d] op R[s]"],
        ["010", "LDI", "010 dddd 0 imm8", "R[d] = stała 8-bit"],
        ["011", "LOAD", "011 dddd 0 addr8", "R[d] = MEM[addr]"],
        ["100", "STORE", "100 ssss 0 addr8", "MEM[addr] = R[s]"],
        ["101", "JMP", "101 0000 0 addr8", "Skok bezwarunkowy"],
        ["110", "BRZ", "110 0000 0 addr8", "Skok gdy Z=1"],
    ])

    doc.add_heading("4. Stany FSM (state_dbg)", level=2)
    add_table(doc, ["Kod", "Stan", "Opis"], [
        ["0000", "f0", "Fetch — PC na adres, RD, PC++"],
        ["0001", "f1", "Załaduj IR z pamięci"],
        ["0010", "decode", "Dekoduj instrukcję"],
        ["0011", "exec_alu", "Wykonaj ALU"],
        ["0100", "exec_ldi", "Załaduj stałą"],
        ["0101–0111", "load_*", "Sekwencja LOAD"],
        ["1000–1010", "store_*", "Sekwencja STORE"],
        ["1011", "jump_addr", "JMP"],
        ["1100", "brz_check", "BRZ"],
        ["1111", "halt", "Zatrzymanie"],
    ])

    doc.add_heading("5. Kod VHDL", level=2)
    doc.add_paragraph("Plik: control.vhd")
    add_placeholder(doc, "[WSTAW ZDJĘCIE: Fragment control.vhd — definicja stanów i case decode]")

    doc.add_page_break()

    # --- Łączenie ---
    doc.add_heading("Łączenie komponentów", level=1)

    doc.add_heading("1. Schemat struktury procesora", level=2)
    add_placeholder(doc, "[WSTAW RYSUNEK: Schemat blokowy CPU — control → register_cpu → ALU, busint → RAM, multipleksery BA/DI/D w CPU.vhd]")
    add_placeholder(doc, "[WSTAW SCREENSHOT: RTL Viewer w Quartus dla entity CPU — hierarchia komponentów]")

    doc.add_heading("2. Pliki projektu", level=2)
    add_table(doc, ["Plik", "Rola"], [
        ["alu.vhd", "Jednostka ALU"], ["register_cpu.vhd", "Plik rejestrów"],
        ["busint.vhd", "Interfejs pamięci"], ["ram.vhd", "Pamięć RAM"],
        ["control.vhd", "Jednostka sterująca"], ["hex_display.vhd", "Dekoder 7-seg"],
        ["CPU.vhd", "Top-level — pełny procesor"], ["ram_init.mif", "Program startowy"],
        ["alu_tb.vhd", "Testbench ALU"], ["register_cpu_tb.vhd", "Testbench rejestrów (dodany)"],
        ["cpu_tb.vhd", "Testbench procesora end-to-end"], ["run_tests.do", "Skrypt QuestaSim"],
    ])

    doc.add_heading("3. Multipleksery w CPU.vhd (dodane przy integracji)", level=2)
    add_table(doc, ["Mux", "Zadanie"], [
        ["DI ← IR[7:0]", "Stała 8-bit dla LDI i adresów"],
        ["BA ← MIO ? bus_DI : alu_Y", "Wynik ALU lub dane z RAM"],
        ["D ← ram.q przy RD", "Połączenie odczytu RAM z busint"],
    ])
    doc.add_paragraph(
        "Poprawka w control.vhd: w stanie f0 ustawiono MIO=0, aby uniknąć "
        "przypadkowego zapisu do rejestrów podczas fazy fetch."
    )

    doc.add_heading("4. RAM — program testowy", level=2)
    add_table(doc, ["Adres", "Kod hex", "Instrukcja"], [
        ["0", "4007", "LDI A, 7"], ["1", "4202", "LDI B, 2"],
        ["2", "2201", "ADD A, A, B"], ["3", "1F00", "HLT"],
    ])
    add_placeholder(doc, "[WSTAW ZDJĘCIE: Memory Initialization File ram_init.mif w Quartus]")

    doc.add_heading("5. Kod VHDL top-level", level=2)
    doc.add_paragraph("Plik: CPU.vhd")
    add_code(doc, """-- Fragment integracji:
reg_DI <= signed(resize(unsigned(std_logic_vector(reg_IR(7 downto 0)), 16));
reg_BA <= bus_DI when ctrl_MIO = '1' else signed(alu_Y);
bus_D  <= signed(ram_data_out) when bus_RD = '1' else (others => 'Z');""")
    add_placeholder(doc, "[WSTAW ZDJĘCIE: Fragment CPU.vhd — instancje U_CONTROL, U_REGS, U_ALU, U_BUSINT, U_RAM]")

    doc.add_heading("6. Test na płytce FPGA", level=2)
    add_table(doc, ["Element", "Funkcja"], [
        ["KEY[0]", "Zegar ręczny — 1 klik = 1 cykl FSM"],
        ["KEY[1]", "Reset asynchroniczny"],
        ["SW[1:0]", "Widok HEX: 00=rA, 01=rB, 10=IR, 11=PC"],
        ["HEX3..0", "Wybrany rejestr"], ["HEX4", "Flagi C,Z,S,P"],
        ["HEX5 / LEDR[9:6]", "Stan FSM (state_dbg)"],
    ])
    doc.add_paragraph("Procedura testu:")
    for step in [
        "Wgraj output_files/CPU.sof na płytkę DE1/DE2.",
        "SW = 0000000000, KEY[1] — reset.",
        "KEY[0] — kliknij ok. 16 razy.",
        "HEX (SW=00) = 0009, LEDR[9:6] = 1111 (HLT).",
    ]:
        doc.add_paragraph(step, style="List Number")

    add_placeholder(doc, "[WSTAW ZDJĘCIE: Płytka DE1/DE2 — ogólny widok z podłączonymi przełącznikami i wyświetlaczami]")
    add_placeholder(doc, "[WSTAW ZDJĘCIE: HEX pokazujące 0009 po wykonaniu programu]")
    add_placeholder(doc, "[WSTAW ZDJĘCIE: LEDR — stan HLT (LEDR[9:6] = 1111)]")

    doc.add_heading("7. Symulacja całego procesora", level=2)
    add_code(doc, "do run_tests.do")
    add_placeholder(doc, "[WSTAW SCREENSHOT: Waveform cpu_tb — ctrl_state_dbg, rA_val, reg_IR, bus_RD, PC_val]")
    add_placeholder(doc, "[WSTAW SCREENSHOT: Transcript — CPU_TB: WSZYSTKIE TESTY PRZESZLY]")

    doc.add_page_break()

    # --- Podsumowanie ---
    doc.add_heading("Podsumowanie", level=1)
    doc.add_paragraph(
        "Udało się zrealizować projekt 16-bitowego procesora w języku VHDL. "
        "Zaimplementowano i przetestowano moduły: ALU, plik rejestrów, układ współpracy "
        "z pamięcią, RAM, jednostkę sterującą oraz top-level CPU łączący wszystkie komponenty."
    )
    doc.add_paragraph(
        "Procesor wykonuje program z pamięci RAM: ładuje stałe do rejestrów, "
        "wykonuje operację ADD w ALU i zatrzymuje się instrukcją HLT. "
        "Wynik rejestru A = 9 został zweryfikowany w symulacji QuestaSim (cpu_tb) "
        "oraz na płytce FPGA (wyświetlacze HEX)."
    )
    doc.add_paragraph("Wykonane testy:")
    for t in [
        "alu_tb — 16 operacji ALU + flagi",
        "register_cpu_tb — zapis/odczyt rejestrów, PC++, IR",
        "cpu_tb — program end-to-end LDI/LDI/ADD/HLT",
        "Test manualny na płytce — KEY[0] × 16, HEX = 0009",
    ]:
        doc.add_paragraph(t, style="List Bullet")

    add_placeholder(doc, "[OPCJONALNIE: Wnioski końcowe — 2–3 zdania własne, np. trudności przy integracji busint z RAM]")

    # --- Załącznik zmian w kodzie ---
    doc.add_heading("Załącznik — zmiany w kodzie wprowadzone pod sprawozdanie", level=1)
    add_table(doc, ["Plik", "Zmiana"], [
        ["alu.vhd", "20 operacji ALU, S_ALU 5-bitowe (00000..10011)"],
        ["register_cpu.vhd", "16 rejestrów A..P, selektory 5-bitowe, rA_dbg/rB_dbg"],
        ["control.vhd", "Selektory 5-bit, funkcja reg4_to_sel5, MIO=0 w f0"],
        ["CPU.vhd", "Pełny procesor, S_ALU 5-bit, porty rejestrów 5-bit"],
        ["alu_tb.vhd", "Testy wszystkich 20 operacji ALU"],
        ["register_cpu_tb.vhd", "Testbench rejestrów A, B, PC, IR"],
        ["ram_init.mif", "Program: LDI A,7 / LDI B,2 / ADD / HLT (kody 4007,4202,2201)"],
        ["cpu_tb.vhd", "Test end-to-end procesora"],
        ["run_tests.do", "alu_tb + register_cpu_tb + cpu_tb"],
    ])

    doc.save(OUT)
    print(f"Zapisano: {OUT}")


if __name__ == "__main__":
    build()
