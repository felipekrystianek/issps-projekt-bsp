# ISSPS - projekt: wpływ parametrów fizycznych BSP na dynamikę i sterowanie (sekcja P2)

Sprawozdanie i model Simulink do projektu „Badanie wpływu parametrów fizycznych czterowirnikowego bezzałogowego statku powietrznego na jego dynamikę i działanie systemu sterowania” (Inżynieria systemów statków powietrznych - systemy sterowania, Politechnika Śląska), konfiguracja **P2**: m = 1,65 kg, J = diag(0,0114; 0,0073; 0,0083) kg·m², opór jak w konfiguracji referencyjnej.

Model to połączenie modelu z [LAB5](https://github.com/felipekrystianek/issps-lab5-quadrocopter) i układu sterowania z [LAB6](https://github.com/felipekrystianek/issps-lab6-sterowanie) w jednym pliku z przełącznikiem.

## Co tu jest

```
docs/
  ISSPS_Projekt_P2_...pdf   <- gotowe sprawozdanie
  ISSPS_Projekt_P2_...docx    to samo sprawozdanie w wersji Word
  make_docx.py              tworzy wersję Word: python3 make_docx.py <plik.typ> <wynik.docx>
  sprawozdanie_projekt.typ  źródło sprawozdania (Typst)
  wyniki.json               wyniki dla REF i P2, które wczytuje sprawozdanie
  img/                      wykresy (REF i P2 na wspólnych osiach) i zrzut modelu
src/
  quad_P2.slx               model Simulink (działa bez skryptów)
  build_P2.m                skrypt, który od zera buduje quad_P2.slx
  run_project.m             wszystkie badania z zadań 1 i 2 dla REF i P2, wykresy i wyniki.json
  bodyDrag.m, xy_na_katy.m  kod bloków MATLAB Function
```

## Jak używać modelu

Parametry są zmiennymi w Model Workspace (Modeling → Model Explorer → Model Workspace):

- `regulator = 1` - stałe prędkości wirników `RotorSpeed` (badania dynamiki jak w LAB5),
- `regulator = 2` - układ sterowania z LAB6; wtedy `tryb` = 1 (skoki `z_cel`, `phi_cel`, `theta_cel`, `r_cel`), 2 (suwaki) albo 3 (punkt `x_cel`, `y_cel`, `z_cel`, `psi_cel`),
- `m`, `I`, `CDxS` - konfiguracja BSP (domyślnie P2), `rho`, `InitialPosition`, `Wind`, `Gust`, `t_gust`.

Wszystko naraz: w folderze `src` wpisz `run_project`.

## Wymagania

- MATLAB + Simulink + Aerospace Blockset (robione na R2026a)
