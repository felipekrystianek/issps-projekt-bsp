// Sprawozdanie projektowe: ISSPS - wpływ parametrów fizycznych BSP (sekcja P2) na dynamikę i sterowanie
// Kompilacja: typst compile sprawozdanie_projekt.typ ISSPS_Projekt_P2_Filipek_Michalik_Augustowski.pdf
// Wszystkie liczby czytane z wyniki.json (generuje src/run_project.m)

#let r = json("wyniki.json")

// liczba z przecinkiem dziesiętnym, d miejsc po przecinku
#let f(x, d) = {
  let s = str(calc.abs(calc.round(x, digits: d)))
  if d > 0 {
    if not s.contains(".") { s += "." }
    let frac = s.split(".").at(1).len()
    s += "0" * (d - frac)
  }
  (if x < 0 and calc.round(x, digits: d) != 0 { "-" } else { "" }) + s.replace(".", ",")
}
#let blad(a, b) = (a - b) / b * 100   // błąd względny [%], b - wartość analityczna
#let bl(a, b) = { let e = calc.abs(blad(a, b)); if e < 0.001 { "< 0,001" } else { f(e, 3) } }

// ---------- Styl (wg SZABLON_SPRAWOZDANIA.doc) ----------
#set document(title: "Sprawozdanie - projekt", author: ("Krystian Filipek", "Paweł Michalik", "Artur Augustowski"))
#set page(
  paper: "a4",
  margin: (x: 2.5cm, top: 2.5cm, bottom: 2.5cm),
  footer: context align(right, text(font: "Times New Roman", size: 12pt)[#counter(page).display()]),
)
#set text(font: "Times New Roman", size: 12pt, lang: "pl")
#set par(justify: true, leading: 0.65em, spacing: 1.1em)
#show heading: set text(weight: "bold")
#show heading.where(level: 1): it => context if target() == "html" { it } else { block(sticky: true, above: 1.4em, below: 0.8em, text(size: 13pt, it.body)) }
#show heading.where(level: 2): it => context if target() == "html" { it } else { block(sticky: true, above: 1.4em, below: 0.8em, underline(text(size: 12pt, it.body))) }
#show heading.where(level: 3): it => context if target() == "html" { it } else { block(sticky: true, above: 1.2em, below: 0.6em, text(size: 12pt, it.body)) }
#set list(indent: 1.2em, body-indent: 0.5em)
#set enum(indent: 1.2em)
#show figure.caption: set text(size: 10pt)
#show figure.where(kind: table): set figure.caption(position: top)
#show figure: set block(spacing: 1.4em)
#set table(stroke: 0.6pt, inset: (x: 5pt, y: 4pt), align: center + horizon)
#show table.cell.where(y: 0): set text(weight: "bold")
#show table: set par(justify: false)
#show table: set text(size: 11pt)

// ---------- Strona tytułowa ----------
#let tytul-html() = html.elem("div", attrs: ("data-custom-style": "Tytul"))[
  #par[Politechnika Śląska, Wydział Mechaniczny Technologiczny, Katedra Podstaw Konstrukcji Maszyn]
  #par[*Inżynieria systemów statków powietrznych - systemy sterowania*]
  #par[Rok akademicki 2026/27]
  #par[SPRAWOZDANIE Z PROJEKTU]
  #par[Sekcja projektowa P2]
  #par[Temat]
  #par[Badanie wpływu parametrów fizycznych czterowirnikowego bezzałogowego statku powietrznego na jego dynamikę i działanie systemu sterowania]
  #par[SEKCJA P2: Krystian Filipek, Paweł Michalik, Artur Augustowski]
  #par[Data oddania: 03.12.2026]
  #par[Prowadzący: dr hab. inż. Piotr Przystałka, prof. PŚ]
]
#context if target() == "html" { tytul-html() } else {
page(margin: (left: 2cm, right: 2cm, top: 2.5cm, bottom: 2cm),
  footer: align(right, text(font: "Times New Roman", size: 12pt)[- 1 -]))[
  #set par(justify: false, leading: 0.4em, spacing: 0.5em)
  #set text(font: "Arial")
  #grid(columns: (5cm, 1.6cm, 1fr), rows: 100%,
    // lewa kolumna
    {
      set align(right)
      text(size: 15pt, weight: "bold")[Katedra \ Podstaw \ Konstrukcji \ Maszyn]
      v(1.2em)
      text(size: 15pt, weight: "bold")[Wydział \ Mechaniczny \ Technologiczny]
      v(1.2em)
      text(size: 15pt, weight: "bold")[Politechnika \ Śląska]
      v(0.8em)
      image("img/logo_polsl.png", width: 2.6cm)
      v(1fr)
      text(size: 8.5pt)[ul. Konarskiego 18a \ 44-100 Gliwice]
      v(0.8em)
      text(size: 8.5pt)[tel. 237 1467 \ fax 237 1360]
      v(0.8em)
      text(size: 8.5pt)[http://kpkm.polsl.pl]
    },
    align(center, line(angle: 90deg, length: 100%, stroke: 0.6pt + luma(120))),
    // prawa kolumna
    {
      v(4.6cm)
      text(size: 24pt, weight: "bold")[Inżynieria systemów statków powietrznych - systemy sterowania]
      v(2em)
      text(size: 11pt)[Rok akademicki 2026/27]
      v(3.2cm)
      text(size: 11pt)[SPRAWOZDANIE Z PROJEKTU]
      v(1.2em)
      text(size: 11pt)[Sekcja projektowa P2]
      v(1em)
      text(size: 9pt)[Temat]
      v(0.3em)
      text(size: 11pt)[Badanie wpływu parametrów fizycznych czterowirnikowego bezzałogowego statku powietrznego na jego dynamikę i działanie systemu sterowania]
      v(2.4em)
      text(size: 11pt)[SEKCJA P2: Krystian Filipek, Paweł Michalik, Artur Augustowski]
      v(2em)
      text(size: 11pt)[Data oddania: 03.12.2026]
      v(0.8em)
      text(size: 11pt)[Prowadzący: dr hab. inż. Piotr Przystałka, prof. PŚ]
    },
  )
]
}

#let pr(a, b) = f(calc.abs((b - a) / a * 100), 1) + " %"   // ta sama zmiana bez znaku, do tekstu
// czas ustalania: 19 s oznacza, że przebieg nie wszedł do pasma do końca symulacji (20 s, skok w 1 s)
#let ts(x) = if x >= 18.99 { "> 19" } else { f(x, 2) }
#let wiersz(n, w, jedn) = ([#n], [#f(w.przeregulowanie, 1)], [#ts(w.t_ust5)], [#ts(w.t_ust)], [#f(w.uchyb, 3) #jedn])

#let A = r.REF
#let B = r.P2
#let zm(a, b) = { let x = (b - a) / a * 100; (if x > 0.005 { "+" } else { "" }) + f(x, 1) + " %" }   // zmiana P2 wzgledem REF
// czas ustalania: 19 s oznacza, że przebieg nie wszedł do pasma do końca symulacji (20 s, skok w 1 s)
#let ts(x) = if x >= 18.99 { "> 19" } else { f(x, 2) }
#let wsk(n, a, b) = ([#n], [#f(a.przeregulowanie, 1)], [#f(b.przeregulowanie, 1)], [#ts(a.t_ust5)], [#ts(b.t_ust5)], [#ts(a.t_ust)], [#ts(b.t_ust)])

// ---------- Treść ----------
= 1. Cel i zakres projektu

Celem projektu jest zbadanie, jak parametry fizyczne czterowirnikowego BSP (masa, momenty bezwładności i opór aerodynamiczny) wpływają na jego dynamikę i na działanie systemu sterowania. Wykorzystano modele z ćwiczeń LAB5 (dynamika) i LAB6 (sterowanie), zmieniając w nich tylko parametry przypisane sekcji. Zakres badań odpowiada zadaniom z LAB5 (zadanie nr 1) i LAB6 (zadanie nr 2), a wyniki porównano z konfiguracją referencyjną (REF) z laboratoriów.

Sekcji P2 przypisano BSP wyposażony w dodatkowy ładunek umieszczony blisko środka masy. Masa rośnie o 10 %, momenty bezwładności tylko o 2,7-4,3 % (ładunek jest blisko środka masy), a opór aerodynamiczny się nie zmienia (tab. 1).

#figure(
  table(columns: 5,
    table.header([Parametr], [REF], [P2], [Zmiana], [Jednostka]),
    [$m$], [1,50], [1,65], [+10,0 %], [kg],
    [$J_(x x)$], [0,0111], [0,0114], [+2,7 %], [kg·m²],
    [$J_(y y)$], [0,0070], [0,0073], [+4,3 %], [kg·m²],
    [$J_(z z)$], [0,0080], [0,0083], [+3,8 %], [kg·m²],
    [$C_(D x) S_x$; $C_(D y) S_y$; $C_(D z) S_z$], [0,0390; 0,0455; 0,0900], [0,0390; 0,0455; 0,0900], [bez zmian], [m²],
  ),
  caption: [Parametry konfiguracji P2 w porównaniu z konfiguracją referencyjną],
)

= 2. Opis modeli symulacyjnych

Model BSP z LAB5 (bloki Multirotor DJIF450Rotors w konfiguracji _Quadcopter +_ i 6DOF (Quaternion), ciężar, opór bodyDrag, wiatr) i układ sterowania z LAB6 połączono w jednym pliku `quad_P2.slx` (rys. 1). Prędkości wirników wybiera przełącznik `regulator` (blok sterowanie): wartość 1 podaje stałe prędkości RotorSpeed, jak w LAB5 (zadanie nr 1), a wartość 2 podaje wyjście układu sterowania z LAB6 (zadanie nr 2). Struktura modelu i układu regulacji jest taka sama jak na laboratoriach. Wszystkie parametry są zmiennymi w Model Workspace, więc REF i P2 różnią się tylko wartościami $m$, $J$ i CDxS. Obie konfiguracje liczono na tym samym modelu, a wyniki dla REF są identyczne z otrzymanymi w LAB5 i LAB6.

Układ sterowania (górna część rys. 1) składa się z regulatorów PID wysokości (PID1), kąta roll (PID2), kąta pitch (PID3) i prędkości obrotu yaw (PID4). Ich wyjścia mikser $bold(Omega)^2 = bold(A)^(-1) [Sigma T, tau_phi, tau_theta, tau_psi]^T$ zamienia na prędkości wirników. Ciąg zawisu $m g$ i macierz $bold(A)^(-1)$ liczone są z parametrów modelu, więc dla P2 regulator uwzględnia większą masę. Dolna część rys. 1 to pętle położenia $x$, $y$ i kąta yaw z zadania 2 ćwiczenia LAB6.

#figure(image("img/model.png", width: 100%), caption: [Model BSP z układem sterowania i przełącznikiem RotorSpeed/regulator (`quad_P2.slx`)])

= 3. Parametry modeli

#figure(
  table(columns: (auto, auto, auto, 1fr),
    table.header([Parametr], [Wartość], [Jednostka], [Opis]),
    [AirDensity], [1,225], [kg/m³], [gęstość powietrza],
    [Arm length], [0,225], [m], [odległość osi wirnika od środka BSP],
    [Height], [-0,035], [m], [położenie środka masy względem układu odniesienia],
    [$C_T$], [0,0142], [-], [współczynnik ciągu śmigła],
    [$C_Q$], [0,00206], [-], [współczynnik momentu aerodynamicznego śmigła],
    [Radius], [0,127], [m], [promień śmigła],
    [$g$], [9,81], [m/s²], [przyspieszenie ziemskie],
  ),
  caption: [Parametry wspólne dla wszystkich konfiguracji],
)

#figure(
  table(columns: 6,
    table.header([Regulator], [Wielkość], [P], [I], [D], [N]),
    [PID1], [wysokość $z$], [20], [0,001], [30], [10],
    [PID2], [kąt roll $phi$], [0,00042], [2,87·10⁻⁶], [0,011], [10],
    [PID3], [kąt pitch $theta$], [0,0038], [9,97·10⁻⁵], [0,026], [10],
    [PID4], [prędkość yaw $r$], [0,020], [0,0093], [0,0014], [10],
    [PID X, PID Y], [położenie $x$, $y$], [0,06], [0,01], [0,3], [10],
    [$K_psi$], [kąt yaw $psi$], [1], [-], [-], [-],
  ),
  caption: [Nastawy regulatorów (z LAB6, bez zmian dla P2)],
)

Pozostałe elementy układu sterowania są takie jak w LAB6: ograniczenie dodatkowego ciągu $Delta T$ do $plus.minus 0","5 m g$, prędkość wirników 0-1000 rad/s, kąty zadane roll i pitch do $plus.minus pi \/ 8$, prędkość yaw do $plus.minus pi \/ 12$ rad/s oraz rampa położenia zadanego 0,5 m/s.

= 4. Wyniki zadania nr 1

Badania wykonano jak w LAB5: przełącznik `regulator` = 1, w zmiennej RotorSpeed odpowiednie prędkości wirników, start z wysokości 10 m (w zad. 1.1 i 1.2 z 10, 50 i 100 m).

=== 4.1. Swobodny spadek bez oporu i z oporem aerodynamicznym

Wirniki wyłączone ($Omega = 0$), raz bez oporu (CDxS = [0 0 0]), raz z oporem z tab. 1 i bez wiatru. Czas spadania to chwila, w której wysokość osiąga 0.

#figure(image("img/z21_spadek.png", width: 75%), caption: [Swobodny spadek bez oporu - REF i P2])

#figure(image("img/z22_spadek_opor.png", width: 75%), caption: [Swobodny spadek z oporem aerodynamicznym - REF i P2])

#figure(
  table(columns: 7,
    table.header([$h_0$ [m]], [bez oporu REF [s]], [bez oporu P2 [s]], [z oporem REF [s]], [z oporem P2 [s]], [zmiana P2], [$v$ uderzenia P2 [m/s]]),
    ..range(3).map(i => ([#(10, 50, 100).at(i)], [#f(A.z21.t.at(i), 2)], [#f(B.z21.t.at(i), 2)], [#f(A.z22.t.at(i), 2)], [#f(B.z22.t.at(i), 2)], [#zm(A.z22.t.at(i), B.z22.t.at(i))], [#f(calc.abs(B.z22.v.at(i)), 1)])).flatten(),
  ),
  caption: [Czasy swobodnego spadania],
)

Bez oporu czas spadania nie zależy od masy ($t = sqrt(2 h_0 \/ g)$), więc REF i P2 spadają tak samo. Z oporem P2 spada szybciej: przy tym samym oporze cięższy BSP ma większą prędkość graniczną ($v_"gr" tilde sqrt(m)$, ok. +5 %). Różnica rośnie z wysokością: z 10 m jest pomijalna, a ze 100 m czas skraca się o #f(calc.abs((B.z22.t.at(2) - A.z22.t.at(2)) / A.z22.t.at(2) * 100), 1) %.

=== 4.2. Minimalna prędkość kątowa wirników i wpływ gęstości powietrza

$Omega_"min" = sqrt(m g \/ (4 C_T rho pi R^4))$ obliczono dla masy przypisanej sekcji i masy większej o 0,5 kg oraz dla $rho$ = 1,225 i 1,0 kg/m³, a zawis na 10 m sprawdzono w symulacji (20 s).

#figure(
  table(columns: 5,
    table.header([Przypadek], [REF [rad/s]], [P2 [rad/s]], [zmiana P2], [odchyłka $h$ P2 [m]]),
    [$m$ ($rho$ = 1,225)], [#f(A.z23.Om.at(0), 2)], [#f(B.z23.Om.at(0), 2)], [#zm(A.z23.Om.at(0), B.z23.Om.at(0))], [#f(B.z23.dh.at(0), 3)],
    [$m$ + 0,5 kg ($rho$ = 1,225)], [#f(A.z23.Om.at(1), 2)], [#f(B.z23.Om.at(1), 2)], [#zm(A.z23.Om.at(1), B.z23.Om.at(1))], [#f(B.z23.dh.at(1), 3)],
    [$m$, $rho$ = 1,0 kg/m³], [#f(A.z24.Om.at(1), 2)], [#f(B.z24.Om.at(1), 2)], [#zm(A.z24.Om.at(1), B.z24.Om.at(1))], [#f(B.z24.dh.at(1), 3)],
    [wzrost $Omega$ przy $rho$ = 1,0], [+#f(A.z24.dproc, 2) %], [+#f(B.z24.dproc, 2) %], [-], [-],
  ),
  caption: [Prędkość kątowa wirników w zawisie (m dla REF = 1,5 kg, dla P2 = 1,65 kg)],
)

#figure(image("img/z23_z24_zawis.png", width: 95%), caption: [Zawis na wysokości 10 m - REF i P2])

P2 potrzebuje o #pr(A.z23.Om.at(0), B.z23.Om.at(0)) większej prędkości wirników niż REF ($Omega tilde sqrt(m)$, $sqrt(1","1) = 1,049$). Spadek gęstości powietrza do 1,0 kg/m³ wymaga wzrostu $Omega$ o #f(B.z24.dproc, 1) % dla obu konfiguracji, bo ten stosunek ($sqrt(1","225 \/ 1","0)$) nie zależy od masy. We wszystkich przypadkach BSP utrzymuje wysokość 10 m.

=== 4.3. Pionowe wznoszenie, wiatr i nierównomierna prędkość wirników

#figure(
  table(columns: 4,
    table.header([Wielkość], [REF], [P2], [zmiana P2]),
    [$Omega = 1","2 Omega_"min"$ [rad/s]], [#f(A.z25.Om, 2)], [#f(B.z25.Om, 2)], [#zm(A.z25.Om, B.z25.Om)],
    [przyspieszenie pionowe [m/s²]], [#f(A.z25.a, 3)], [#f(B.z25.a, 3)], [#zm(A.z25.a, B.z25.a)],
    [prędkość wznoszenia po 15 s [m/s]], [#f(A.z25.v15, 2)], [#f(B.z25.v15, 2)], [#zm(A.z25.v15, B.z25.v15)],
    [przemieszczenie po 10 s wiatru 3 m/s [m]], [#f(A.z26.x10, 3)], [#f(B.z26.x10, 3)], [#zm(A.z26.x10, B.z26.x10)],
    [prędkość dryfu po 10 s [m/s]], [#f(A.z26.v10, 3)], [#f(B.z26.v10, 3)], [#zm(A.z26.v10, B.z26.v10)],
  ),
  caption: [Wznoszenie (bez oporu) i przemieszczenie pod wpływem wiatru (bez regulatora)],
)

#figure(image("img/z25_wznoszenie.png", width: 75%), caption: [Prędkość pionowa dla $Omega = 1","2 Omega_"min"$ - REF i P2])

#figure(image("img/z26_wiatr.png", width: 75%), caption: [Przemieszczenie wzdłuż osi roll pod wpływem wiatru 3 m/s - REF i P2])

Przy $Omega = 1","2 Omega_"min"$ ciąg wynosi $1","44 m g$, więc przyspieszenie $a = 0","44 g$ jest takie samo dla obu konfiguracji. $Omega_"min"$ wyznacza się dla danej masy, więc większa masa P2 jest już uwzględniona w prędkości wirników. Wiatr przesuwa P2 o #f(calc.abs((B.z26.x10 - A.z26.x10) / A.z26.x10 * 100), 1) % mniej, bo ta sama siła oporu działa na większą masę.

W zad. 1.7 wirnik nr 1 (przedni) obraca się o 5 % szybciej od pozostałych. Momenty odczytano z wyjścia $M_(x y z)$ bloku DJIF450Rotors, a przyspieszenia kątowe obliczono jako $dot(omega) = M \/ J$.

#figure(
  table(columns: 7,
    table.header([Kanał], [$M$ REF [N·m]], [$M$ P2 [N·m]], [$dot(omega)$ REF [rad/s²]], [$dot(omega)$ P2 [rad/s²]], [zmiana $M$], [zmiana $dot(omega)$]),
    [roll], [#f(A.z27.M.at(0), 4)], [#f(B.z27.M.at(0), 4)], [#f(A.z27.dw.at(0), 2)], [#f(B.z27.dw.at(0), 2)], [-], [-],
    [pitch], [#f(A.z27.M.at(1), 4)], [#f(B.z27.M.at(1), 4)], [#f(A.z27.dw.at(1), 2)], [#f(B.z27.dw.at(1), 2)], [#zm(A.z27.M.at(1), B.z27.M.at(1))], [#zm(A.z27.dw.at(1), B.z27.dw.at(1))],
    [yaw], [#f(A.z27.M.at(2), 4)], [#f(B.z27.M.at(2), 4)], [#f(A.z27.dw.at(2), 3)], [#f(B.z27.dw.at(2), 3)], [#zm(A.z27.M.at(2), B.z27.M.at(2))], [#zm(A.z27.dw.at(2), B.z27.dw.at(2))],
  ),
  caption: [Momenty i przyspieszenia kątowe przy wirniku nr 1 szybszym o 5 %],
)

Momenty w P2 są o 10 % większe, bo zawis wymaga większej prędkości wirników, a moment jest proporcjonalny do $Omega^2$, czyli do masy. Momenty bezwładności wzrosły mniej (o 4,3 % i 3,8 %), więc przyspieszenia kątowe P2 są o ok. 5-6 % większe: P2 jest nieco bardziej wrażliwy na nierównomierną pracę silników.

= 5. Wyniki zadania nr 2

Badania wykonano jak w LAB6: przełącznik `regulator` = 2, nastawy z tab. 3. W warunkach idealnych zadano skoki wysokości z 10 do 15 m, kąta roll i pitch o $pi \/ 8$ oraz prędkości yaw o $pi \/ 12$ rad/s (każdy osobno, w chwili 1 s). Następnie zadano punkt docelowy (5, 5, 15) m z kątem $psi$ = 45° bez wiatru oraz przy wietrze 5 m/s wzdłuż osi $x$ z podmuchem +3 m/s w chwili 30-32 s.

#figure(image("img/z2_z.png", width: 75%), caption: [Skok wysokości - REF i P2])

#figure(image("img/z2_phi.png", width: 75%), caption: [Skok kąta roll - REF i P2])

#figure(image("img/z2_theta.png", width: 75%), caption: [Skok kąta pitch - REF i P2])

#figure(image("img/z2_r.png", width: 75%), caption: [Skok prędkości yaw - REF i P2])

#figure(image("img/z2_xyz_bez_wiatru.png", width: 90%), caption: [Lot do punktu docelowego w warunkach idealnych - REF i P2])

#figure(image("img/z2_xyz_wiatr.png", width: 90%), caption: [Lot do punktu docelowego przy wietrze 5 m/s i podmuchu 3 m/s - REF i P2])

= 6. Porównanie wyników

Porównanie dla zadania nr 1 zawierają tabele 4-7. Wskaźniki jakości regulacji z zadania nr 2 zestawiono w tab. 8 (czas ustalania liczony od chwili skoku; przy wietrze dla $x$ i $y$ do chwili podmuchu).

#figure(
  table(columns: 7,
    table.header(table.cell(rowspan: 2)[Test], table.cell(colspan: 2)[Przeregulowanie [%]], table.cell(colspan: 2)[$t_"ust"$ (5 %) [s]], table.cell(colspan: 2)[$t_"ust"$ (2 %) [s]],
      [REF], [P2], [REF], [P2], [REF], [P2]),
    ..wsk([skok $z$], A.ster.z, B.ster.z),
    ..wsk([skok $phi$], A.ster.phi, B.ster.phi),
    ..wsk([skok $theta$], A.ster.theta, B.ster.theta),
    ..wsk([skok $r$], A.ster.r, B.ster.r),
    ..wsk([XYZ: $x$], A.ster.bez_wiatru.x, B.ster.bez_wiatru.x),
    ..wsk([XYZ: $y$], A.ster.bez_wiatru.y, B.ster.bez_wiatru.y),
    ..wsk([XYZ: $z$], A.ster.bez_wiatru.z, B.ster.bez_wiatru.z),
    ..wsk([XYZ: $psi$], A.ster.bez_wiatru.psi, B.ster.bez_wiatru.psi),
    ..wsk([wiatr: $x$], A.ster.wiatr.x, B.ster.wiatr.x),
    ..wsk([wiatr: $y$], A.ster.wiatr.y, B.ster.wiatr.y),
  ),
  caption: [Wskaźniki jakości regulacji - REF i P2],
)

#figure(
  table(columns: 3,
    table.header([Wielkość (wiatr 5 m/s)], [REF], [P2]),
    [największe odejście od celu po podmuchu [m]], [#f(A.ster.wiatr.podmuch, 3)], [#f(B.ster.wiatr.podmuch, 3)],
    [odległość od celu na końcu (50 s) [m]], [#f(A.ster.wiatr.uchyb_koniec, 3)], [#f(B.ster.wiatr.uchyb_koniec, 3)],
  ),
  caption: [Odporność na wiatr - REF i P2],
)

Przebiegi dla REF i P2 prawie się pokrywają. Regulator wysokości i mikser korzystają z rzeczywistej masy ($m g$ i $bold(A)^(-1)$), więc większa masa P2 jest skompensowana i skok wysokości przebiega tak samo. W kanałach roll, pitch i yaw nastawy są takie same, a momenty bezwładności P2 są większe o 2,7-4,3 %. Dlatego P2 reaguje odrobinę wolniej i ma nieco większe przeregulowanie w roll i yaw (#f(B.ster.phi.przeregulowanie, 1) % i #f(B.ster.r.przeregulowanie, 1) % wobec #f(A.ster.phi.przeregulowanie, 1) % i #f(A.ster.r.przeregulowanie, 1) %). W locie do punktu różnice czasu ustalania $x$, $y$ i $z$ są poniżej 0,2 s. Wyjątkiem jest czas ustalania kąta $psi$ w paśmie 2 % (#f(B.ster.bez_wiatru.psi.t_ust, 1) s zamiast #f(A.ster.bez_wiatru.psi.t_ust, 1) s): po dojściu do 45° kąt chwilowo spada o ok. 1°, a w P2 ten spadek nieznacznie przekracza granicę pasma. Przy wietrze P2 odchodzi od celu po podmuchu mniej niż REF (#f(B.ster.wiatr.podmuch, 2) m wobec #f(A.ster.wiatr.podmuch, 2) m), bo większa masa zmniejsza przyspieszenie od tej samej siły oporu.

= 7. Wnioski

+ Ładunek umieszczony blisko środka masy (P2) zwiększa masę o 10 %, a momenty bezwładności tylko o 2,7-4,3 %. Zmienia to dynamikę BSP w niewielkim stopniu, a opór aerodynamiczny pozostaje taki sam jak w REF.
+ Prędkość wirników w zawisie rośnie jak $sqrt(m)$, czyli o #pr(A.z23.Om.at(0), B.z23.Om.at(0)), a przy $rho$ = 1,0 kg/m³ i dodatkowych 0,5 kg P2 potrzebuje już #f(B.z23.Om.at(1), 0) rad/s. Mniejszy jest więc zapas ciągu na manewry i ładunek.
+ Masa nie wpływa na swobodny spadek bez oporu ani na przyspieszenie przy $Omega = 1","2 Omega_"min"$, bo w obu przypadkach siły skalują się z masą. Z oporem cięższy BSP spada szybciej, a wiatr przesuwa go mniej (o #f(calc.abs((B.z26.x10 - A.z26.x10) / A.z26.x10 * 100), 1) %), bo ta sama siła oporu działa na większą masę.
+ Przy nierównomiernej pracy wirników P2 dostaje o 10 % większe momenty (większe $Omega$), a przyspieszenia kątowe rosną o 5-6 %, bo bezwładność wzrosła mniej niż masa.
+ Układ sterowania z nastawami z LAB6 działa dla P2 poprawnie i prawie tak samo jak dla REF, bez ponownego strojenia. Pomaga w tym to, że ciąg zawisu i mikser liczone są z rzeczywistej masy. Większe momenty bezwładności tylko nieznacznie spowalniają pętle roll, pitch i yaw.
+ Przy wietrze 5 m/s P2 utrzymuje punkt docelowy tak samo dobrze jak REF, a podmuch odsuwa go nawet trochę mniej. Konfigurację P2 można więc stosować z tymi samymi nastawami regulatorów. Przy większych zmianach rozkładu masy (np. P3 lub P5) wpływ na pętle orientacji byłby większy.

= Wykorzystanie sztucznej inteligencji

Przy wykonywaniu projektu korzystano z narzędzia sztucznej inteligencji (Claude, Anthropic) do utworzenia wykresów i obliczeń porównawczych.
