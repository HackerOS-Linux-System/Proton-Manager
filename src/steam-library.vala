public class ProtonManager.SteamLibrary : Object {

    public static string? find_steam_root () {
        string home = Environment.get_home_dir ();
        string[] candidates = {
            Path.build_filename (home, ".steam", "steam"),
            Path.build_filename (home, ".local", "share", "Steam"),
            Path.build_filename (home, ".var", "app", "com.valvesoftware.Steam", ".local", "share", "Steam"),
        };
        foreach (var c in candidates) {
            if (FileUtils.test (Path.build_filename (c, "steamapps"), FileTest.IS_DIR))
                return c;
        }
        return null;
    }

    /* Zwraca listę katalogów .../steamapps dla wszystkich bibliotek
     * (główna + dodatkowe dyski, wg libraryfolders.vdf) */
    public static Gee.ArrayList<string> find_library_folders () {
        var result = new Gee.ArrayList<string> ();
        string? root = find_steam_root ();
        if (root == null)
            return result;

        string main_steamapps = Path.build_filename (root, "steamapps");
        result.add (main_steamapps);

        string vdf_path = Path.build_filename (main_steamapps, "libraryfolders.vdf");
        string content;
        try {
            FileUtils.get_contents (vdf_path, out content);
        } catch (Error e) {
            return result;
        }

        /* Format: "path"		"/jakas/sciezka" - proste wyciąganie regexem,
         * bez potrzeby pełnego parsera VDF. */
        try {
            var regex = new Regex ("\"path\"\\s*\"([^\"]+)\"");
            MatchInfo info;
            regex.match (content, 0, out info);
            while (info.matches ()) {
                string p = info.fetch (1);
                p = p.replace ("\\\\", "/");
                string steamapps = Path.build_filename (p, "steamapps");
                if (FileUtils.test (steamapps, FileTest.IS_DIR) && !result.contains (steamapps))
                    result.add (steamapps);
                info.next ();
            }
        } catch (RegexError e) {
            warning ("Nie udało się sparsować libraryfolders.vdf: %s", e.message);
        }

        return result;
    }

    /* Skanuje pliki appmanifest_*.acf i zwraca gry, które posiadają
     * folder compatdata (czyli były kiedyś uruchomione pod Protonem). */
    public static Gee.ArrayList<Game> find_proton_games () {
        var games = new Gee.ArrayList<Game> ();

        foreach (var steamapps in find_library_folders ()) {
            Dir dir;
            try {
                dir = Dir.open (steamapps, 0);
            } catch (FileError e) {
                continue;
            }

            string? fname;
            while ((fname = dir.read_name ()) != null) {
                if (!fname.has_prefix ("appmanifest_") || !fname.has_suffix (".acf"))
                    continue;

                string full = Path.build_filename (steamapps, fname);
                string content;
                try {
                    FileUtils.get_contents (full, out content);
                } catch (Error e) {
                    continue;
                }

                string? appid = extract_field (content, "appid");
                string? name = extract_field (content, "name");
                string? installdir = extract_field (content, "installdir");
                if (appid == null || name == null)
                    continue;

                var game = new Game (appid, name, steamapps);
                if (installdir != null)
                    game.install_dir = Path.build_filename (steamapps, "common", installdir);

                if (game.has_prefix)
                    games.add (game);
            }
        }

        games.sort ((a, b) => strcmp (a.name, b.name));
        return games;
    }

    private static string? extract_field (string content, string key) {
        try {
            var regex = new Regex ("\"%s\"\\s*\"([^\"]*)\"".printf (Regex.escape_string (key)));
            MatchInfo info;
            if (regex.match (content, 0, out info))
                return info.fetch (1);
        } catch (RegexError e) {}
        return null;
    }

    /* Wykrywa zainstalowane wersje Protona (Valve, GE, Experimental...)
     * we wszystkich bibliotekach steamapps/common. */
    public static Gee.ArrayList<string> find_proton_installations () {
        var result = new Gee.ArrayList<string> ();
        foreach (var steamapps in find_library_folders ()) {
            string common = Path.build_filename (steamapps, "common");
            Dir dir;
            try {
                dir = Dir.open (common, 0);
            } catch (FileError e) {
                continue;
            }
            string? fname;
            while ((fname = dir.read_name ()) != null) {
                if (fname.has_prefix ("Proton")) {
                    string candidate = Path.build_filename (common, fname);
                    string wine_bin = Path.build_filename (candidate, "files", "bin", "wine");
                    if (FileUtils.test (wine_bin, FileTest.IS_EXECUTABLE))
                        result.add (candidate);
                }
            }
        }
        return result;
    }
}
