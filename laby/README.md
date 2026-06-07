# Laboratoria — testy komponentów procesora

Folder `laby/` zawiera **kopie** plików z głównego projektu, podzielone na 4 niezależne laboratoria.
Każde labo można skompilować i przetestować osobno w QuestaSim, bez całego procesora.

| Folder | Komponent | Testbench |
|--------|-----------|-----------|
| [Lab1_ALU](Lab1_ALU/) | Jednostka arytmetyczno-logiczna | `alu_tb` |
| [Lab2_Rejestry](Lab2_Rejestry/) | Plik rejestrów | `register_cpu_tb` |
| [Lab3_Pamiec](Lab3_Pamiec/) | busint + RAM | `memory_tb` |
| [Lab4_Sterowanie](Lab4_Sterowanie/) | Maszyna stanów control | `control_tb` |

---

## Szybki start — wszystkie testy naraz

W oknie **Transcript** QuestaSim:

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby}
do run_all_tests.do
```

**Sukces** — w Transcript pojawią się 4 komunikaty:

```
=== ALU_TB: WSZYSTKIE TESTY PRZESZLY ===
=== REGISTER_CPU_TB: WSZYSTKIE TESTY PRZESZLY ===
=== MEMORY_TB: WSZYSTKIE TESTY PRZESZLY ===
=== CONTROL_TB: WSZYSTKIE TESTY PRZESZLY ===
```

---

## Pojedyncze laboratorium

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab1_ALU}
do run_tests.do
```

Zamień `Lab1_ALU` na `Lab2_Rejestry`, `Lab3_Pamiec` lub `Lab4_Sterowanie`.

---

## Szczegółowe instrukcje

- [Lab 1 — ALU](Lab1_ALU/INSTRUKCJA.md)
- [Lab 2 — Rejestry](Lab2_Rejestry/INSTRUKCJA.md)
- [Lab 3 — Pamięć](Lab3_Pamiec/INSTRUKCJA.md)
- [Lab 4 — Układ sterujący](Lab4_Sterowanie/INSTRUKCJA.md)

---

## Tabela zbiorcza — oczekiwane wyniki

| Lab | Test | Oczekiwany komunikat | Liczba przypadków |
|-----|------|----------------------|-------------------|
| 1 | ALU — wszystkie operacje + flagi | `ALU_TB: WSZYSTKIE TESTY PRZESZLY` | 23 |
| 2 | Rejestry — zapis/odczyt A, B, PC, IR | `REGISTER_CPU_TB: WSZYSTKIE TESTY PRZESZLY` | 5 |
| 3 | Pamięć — adresy, MIF, zapis/odczyt | `MEMORY_TB: WSZYSTKIE TESTY PRZESZLY` | 10 |
| 4 | Sterowanie — LDI, ADD, HLT, BRZ | `CONTROL_TB: WSZYSTKIE TESTY PRZESZLY` | 4 scenariusze |

Główny projekt (folder nadrzędny) pozostaje bez zmian — nadal działa `do run_tests.do` z katalogu `CPU/`.
