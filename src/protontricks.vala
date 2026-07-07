public enum ProtonManager.BackendKind {
    NONE,
    NATIVE,
    FLATPAK
}

public class ProtonManager.ProtontricksBackend : Object {
    public BackendKind kind { get; private set; default = BackendKind.NONE; }

    public ProtontricksBackend () {
        detect ();
    }

    private void detect () {
        string? native = Environment.find_program_in_path ("protontricks");
        if (native != null) {
            kind = BackendKind.NATIVE;
            return;
        }

        string? flatpak = Environment.find_program_in_path ("flatpak");
        if (flatpak != null) {
            try {
                string std_out;
                Process.spawn_command_line_sync (
                    "flatpak list --app --columns=application", out std_out, null, null);
                if (std_out.contains ("com.github.Matoking.protontricks")) {
                    kind = BackendKind.FLATPAK;
                    return;
                }
            } catch (SpawnError e) {}
        }

        kind = BackendKind.NONE;
    }

    public string status_text () {
        switch (kind) {
            case BackendKind.NATIVE:
                return "protontricks: wersja natywna wykryta";
            case BackendKind.FLATPAK:
                return "protontricks: wersja Flatpak wykryta";
            default:
                return "protontricks: nie znaleziono (dostępny tylko tryb bezpośredni)";
        }
    }

    /* Buduje argv wołające protontricks z podanymi argumentami. */
    public string[] build_argv (string[] args) {
        var argv = new Gee.ArrayList<string> ();
        switch (kind) {
            case BackendKind.FLATPAK:
                argv.add ("flatpak");
                argv.add ("run");
                argv.add ("com.github.Matoking.protontricks");
                break;
            case BackendKind.NATIVE:
                argv.add ("protontricks");
                break;
            default:
                argv.add ("protontricks"); // spróbuje i tak, zgłosi błąd uruchomienia
                break;
        }
        foreach (var a in args)
            argv.add (a);

        var result = new string[argv.size];
        for (int i = 0; i < argv.size; i++)
            result[i] = argv[i];
        return result;
    }
}

/* Tryb awaryjny: pomija protontricks całkowicie i woła wine/winetricks
 * bezpośrednio ze wskazanej instalacji Proton, wskazując WINEPREFIX na
 * konkretny prefix gry. To właśnie ten tryb "naprawia" sytuacje, w
 * których protontricks się wiesza, źle wykrywa grę albo w ogóle nie
 * działa w danej dystrybucji. */
public class ProtonManager.DirectBypass : Object {

    public static string[] winecfg_argv (Game game, string proton_dir) {
        return {
            Path.build_filename (proton_dir, "files", "bin", "wine"),
            "winecfg"
        };
    }

    public static string[] winetricks_gui_argv (Game game, string proton_dir) {
        return { "winetricks" };
    }

    public static string[] winetricks_verb_argv (Game game, string proton_dir, string verb) {
        return { "winetricks", verb };
    }

    public static string[] run_exe_argv (Game game, string proton_dir, string exe_path) {
        return {
            Path.build_filename (proton_dir, "files", "bin", "wine"),
            exe_path
        };
    }

    public static string[] kill_wineserver_argv (Game game, string proton_dir) {
        return {
            Path.build_filename (proton_dir, "files", "bin", "wineserver"),
            "-k"
        };
    }

    public static string[] build_env (Game game, string proton_dir) {
        string? steam_root = SteamLibrary.find_steam_root ();
        string install = steam_root ?? "";
        return {
            "WINEPREFIX=%s".printf (game.pfx_path ()),
            "STEAM_COMPAT_DATA_PATH=%s".printf (game.compatdata_path),
            "STEAM_COMPAT_CLIENT_INSTALL_PATH=%s".printf (install),
            "WINE=%s".printf (Path.build_filename (proton_dir, "files", "bin", "wine")),
            "WINELOADER=%s".printf (Path.build_filename (proton_dir, "files", "bin", "wine")),
            "WINESERVER=%s".printf (Path.build_filename (proton_dir, "files", "bin", "wineserver")),
            "PATH=%s:%s".printf (Path.build_filename (proton_dir, "files", "bin"), Environment.get_variable ("PATH") ?? "/usr/bin")
        };
    }
}
