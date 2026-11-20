# Proton Manager

Narzędzie GUI (GTK4 + libadwaita, napisane w **H#** z biblioteką **gtk** (bit.io), budowane przez **bit**),
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
├── Bit.hk                    # manifest bit (zależność: gtk) — zastępuje meson.build
├── build.hl
├── src/
│   ├── main.h#               # punkt wejścia
│   ├── window.h#             # główne okno (lista gier + panel akcji + log), stan Ui
│   ├── game.h#               # model gry / prefixu Proton
│   ├── steam_library.h#      # wykrywanie bibliotek Steam / gier / Protona
│   ├── protontricks.h#       # backend protontricks + tryb bezpośredni (bypass)
│   ├── command_runner.h#     # asynchroniczne uruchamianie poleceń z logiem na żywo
│   └── ffi.h#                # dodatkowe bindingi `extern static` (libc, GTK)
└── data/
    └── com.protonmanager.App.desktop.in
```

Przepisanie z Vali: `application.vala` zniknęło (rolę `Adw.Application` pełni
`gtk::App` z pętlą zdarzeń biblioteki gtk), pozostałe pliki mają swoje odpowiedniki
1:1. Poza oryginałem dodano: GE-Proton z `compatibilitytools.d`, wiele verbów naraz,
zapamiętanie wybranej wersji Protona.

## Zależności (Ubuntu/Debian)

```bash
sudo apt install libgtk-4-dev libadwaita-1-dev pkg-config
```

Potrzebny jest kompilator **H#** (0.9 z obsługą domknięć — backend C++) oraz `bit`.
Do pełnej funkcjonalności w systemie przydają się też: `winetricks` oraz opcjonalnie
`protontricks` (natywnie albo Flatpak `com.github.Matoking.protontricks`) — program
**działa także bez protontricks**, korzystając z trybu bezpośredniego.

## Budowanie i uruchomienie

```bash
bit                      # instaluje zależności (gtk) i buduje wg [default-build]
./cache/build/release/proton-manager
# albo:
bit install-local        # instaluje binarkę i plik .desktop do /usr/local
```

Jeśli `bit` nie widzi własnego `h#`, wskaż go: `BIT_HSHARP=/ścieżka/do/h# bit`.

## Licencja

Zobacz plik `LICENSE`.
