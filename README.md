# Proton Manager

Narzędzie GUI (GTK4 + libadwaita, napisane w **Vala**, budowane **Meson-em**),
które łączy w sobie funkcje **Proton (GE)** i **protontricks** w jednym miejscu,
a przede wszystkim **naprawia typowe bolączki protontricks**:

- protontricks czasem się wiesza, źle wykrywa AppID, ma problemy ze
  środowiskiem Python/pipx albo po prostu nie jest zainstalowany —
  Proton Manager wtedy **omija protontricks całkowicie** (tryb bezpośredni)
  i woła `wine`/`winetricks`/`wineserver` wprost z wybranej instalacji Protona,
  z poprawnie ustawionymi zmiennymi środowiskowymi (`WINEPREFIX`,
  `STEAM_COMPAT_DATA_PATH`, `STEAM_COMPAT_CLIENT_INSTALL_PATH`).
- Automatyczne wykrywanie bibliotek Steam (w tym dodatkowych dysków z
  `libraryfolders.vdf`), gier posiadających prefix Proton (`compatdata`)
  oraz wszystkich zainstalowanych wersji Protona (Valve, GE, Experimental…)
  — bez pytania protontricks o cokolwiek.
- Wykrywanie protontricks natywnego lub we Flatpaku i wywoływanie go z GUI
  (winecfg, `--gui`, `--list`) — gdy akurat działa poprawnie.
- Panel logu na żywo pokazujący dokładnie co i z jakimi zmiennymi środowiskowymi
  zostało uruchomione (koniec z zagadkowymi cichymi błędami terminala).
- Szybkie akcje: winecfg, GUI winetricks, instalacja pojedynczego "verb"
  (np. `vcrun2019`, `corefonts`), uruchomienie dowolnego `.exe` w prefixie,
  zabicie `wineserver` dla konkretnego prefixu, otwarcie folderu prefixu.

## Struktura projektu

```
proton-manager/
├── meson.build              # główny plik budowania
├── src/
│   ├── meson.build
│   ├── main.vala             # punkt wejścia
│   ├── application.vala      # Adw.Application
│   ├── window.vala           # główne okno (lista gier + panel akcji + log)
│   ├── game.vala             # model gry / prefixu Proton
│   ├── steam-library.vala    # wykrywanie bibliotek Steam / gier / Protona
│   ├── protontricks.vala     # backend protontricks + tryb bezpośredni (bypass)
│   └── command-runner.vala   # asynchroniczne uruchamianie poleceń z logiem
└── data/
    ├── meson.build
    └── com.protonmanager.App.desktop.in
```

## Zależności (Ubuntu/Debian)

```bash
sudo apt install valac meson ninja-build libgtk-4-dev libadwaita-1-dev libgee-0.8-dev
```

Do pełnej funkcjonalności w systemie potrzebne są też: `winetricks`
(pakiet `winetricks`) oraz opcjonalnie `protontricks` (natywnie albo
przez Flatpak `com.github.Matoking.protontricks`) — ale program **działa
także bez protontricks**, korzystając wyłącznie z trybu bezpośredniego.

## Budowanie i uruchomienie

```bash
meson setup build
ninja -C build
./build/src/proton-manager
```

## Instalacja systemowa (opcjonalnie)

```bash
meson setup build --prefix=/usr/local
ninja -C build
sudo ninja -C build install
```

## Jak to naprawia protontricks?

Protontricks jest w praktyce cienką nakładką na `winetricks` uruchamiane
z odpowiednimi zmiennymi środowiskowymi Steam/Proton. Gdy zawiedzie
(np. źle rozpozna AppID, ma nieaktualną bazę Proton App ID, albo jego
zależności Pythona są rozjechane po aktualizacji dystrybucji), zwykle
i tak można ręcznie odtworzyć to, co próbuje zrobić — tylko trzeba pamiętać
poprawne ścieżki i zmienne. Proton Manager robi to za Ciebie: sam wykrywa
prefix gry i instalację Protona, sam buduje `WINEPREFIX`/`STEAM_COMPAT_*`
i uruchamia `wine`/`winetricks`/`wineserver` bezpośrednio, z pełnym logiem
na żywo, żebyś widział dokładnie co się dzieje zamiast walczyć z terminalem.
