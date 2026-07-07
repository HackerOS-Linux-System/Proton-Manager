public class ProtonManager.Window : Adw.ApplicationWindow {

    private Gtk.ListBox game_list;
    private Gtk.SearchEntry search_entry;
    private Gtk.TextView log_view;
    private Gtk.TextBuffer log_buffer;
    private Adw.WindowTitle window_title;
    private Gtk.Box action_box;
    private Adw.StatusPage empty_page;
    private Gtk.DropDown proton_dropdown;
    private Gtk.ScrolledWindow right_scroller;

    private Gee.ArrayList<Game> games = new Gee.ArrayList<Game> ();
    private Game? selected_game = null;
    private ProtontricksBackend backend = new ProtontricksBackend ();
    private Gee.ArrayList<string> proton_installs = new Gee.ArrayList<string> ();

    public Window (Adw.Application app) {
        Object (application: app);
        this.set_default_size (980, 640);
        this.set_title ("Proton Manager");
        build_ui ();
        reload_games ();
    }

    private void build_ui () {
        var toolbar_view = new Adw.ToolbarView ();

        var header = new Adw.HeaderBar ();
        window_title = new Adw.WindowTitle ("Proton Manager", backend.status_text ());
        header.set_title_widget (window_title);

        var refresh_btn = new Gtk.Button.from_icon_name ("view-refresh-symbolic");
        refresh_btn.set_tooltip_text ("Odśwież listę gier");
        refresh_btn.clicked.connect (() => reload_games ());
        header.pack_start (refresh_btn);

        var menu_btn = new Gtk.MenuButton ();
        menu_btn.set_icon_name ("open-menu-symbolic");
        var menu = new Menu ();
        menu.append ("O programie", "app.about");
        menu_btn.set_menu_model (menu);
        header.pack_end (menu_btn);

        toolbar_view.add_top_bar (header);

        var search_bar_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        search_bar_box.set_margin_start (8);
        search_bar_box.set_margin_end (8);
        search_bar_box.set_margin_top (6);
        search_bar_box.set_margin_bottom (6);
        search_entry = new Gtk.SearchEntry ();
        search_entry.set_placeholder_text ("Szukaj gry…");
        search_entry.set_hexpand (true);
        search_entry.search_changed.connect (filter_games);
        search_bar_box.append (search_entry);

        // Panel z listą gier (lewa strona)
        game_list = new Gtk.ListBox ();
        game_list.set_selection_mode (Gtk.SelectionMode.SINGLE);
        game_list.add_css_class ("navigation-sidebar");
        game_list.row_selected.connect (on_row_selected);

        var list_scroller = new Gtk.ScrolledWindow ();
        list_scroller.set_child (game_list);
        list_scroller.set_hexpand (false);
        list_scroller.set_size_request (300, -1);
        list_scroller.set_vexpand (true);

        var left_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        left_box.append (search_bar_box);
        left_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        left_box.append (list_scroller);

        // Panel akcji (prawa strona)
        action_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
        action_box.set_margin_start (18);
        action_box.set_margin_end (18);
        action_box.set_margin_top (18);
        action_box.set_margin_bottom (12);

        empty_page = new Adw.StatusPage ();
        empty_page.set_icon_name ("applications-games-symbolic");
        empty_page.set_title ("Wybierz grę");
        empty_page.set_description ("Wybierz z listy grę, aby zobaczyć dostępne narzędzia i naprawy prefixu Proton.");
        empty_page.set_vexpand (true);

        right_scroller = new Gtk.ScrolledWindow ();
        right_scroller.set_child (empty_page);
        right_scroller.set_hexpand (true);
        right_scroller.set_vexpand (true);

        var paned_top = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned_top.set_start_child (left_box);
        paned_top.set_end_child (right_scroller);
        paned_top.set_resize_start_child (false);
        paned_top.set_shrink_start_child (false);
        paned_top.set_position (300);
        paned_top.set_vexpand (true);

        // Konsola logów (dół)
        log_buffer = new Gtk.TextBuffer (null);
        log_view = new Gtk.TextView.with_buffer (log_buffer);
        log_view.set_editable (false);
        log_view.set_monospace (true);
        log_view.set_top_margin (6);
        log_view.set_left_margin (8);

        var log_scroller = new Gtk.ScrolledWindow ();
        log_scroller.set_child (log_view);
        log_scroller.set_min_content_height (140);
        log_scroller.set_vexpand (false);

        var log_frame = new Gtk.Frame (null);
        log_frame.set_child (log_scroller);
        log_frame.set_margin_start (8);
        log_frame.set_margin_end (8);
        log_frame.set_margin_bottom (8);

        var log_label = new Gtk.Label ("Log poleceń:");
        log_label.set_halign (Gtk.Align.START);
        log_label.set_margin_start (8);
        log_label.add_css_class ("heading");

        var bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);
        bottom_box.append (log_label);
        bottom_box.append (log_frame);

        var main_paned = new Gtk.Paned (Gtk.Orientation.VERTICAL);
        main_paned.set_start_child (paned_top);
        main_paned.set_end_child (bottom_box);
        main_paned.set_resize_end_child (false);
        main_paned.set_position (420);
        toolbar_view.set_content (main_paned);

        this.set_content (toolbar_view);
    }

    private void filter_games () {
        string query = search_entry.get_text ().down ();
        game_list.set_filter_func ((row) => {
            var r = row as GameRow;
            if (r == null)
                return true;
            return query == "" || r.game.name.down ().contains (query);
        });
    }

    private void reload_games () {
        games = SteamLibrary.find_proton_games ();
        proton_installs = SteamLibrary.find_proton_installations ();
        window_title.set_subtitle (backend.status_text ());

        game_list.remove_all ();
        foreach (var g in games) {
            var row = new GameRow (g);
            game_list.append (row);
        }
        append_log ("Znaleziono %d gier z prefixem Proton, %d instalacji Protona.".printf (
            games.size, proton_installs.size), false);
    }

    private void on_row_selected (Gtk.ListBoxRow? row) {
        var r = row as GameRow;
        selected_game = (r != null) ? r.game : null;
        build_action_panel ();
    }

    private void build_action_panel () {
        if (selected_game == null) {
            right_scroller.set_child (empty_page);
            return;
        }

        var game = selected_game;
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 14);
        box.set_margin_start (18);
        box.set_margin_end (18);
        box.set_margin_top (18);
        box.set_margin_bottom (18);

        var title = new Gtk.Label (game.name);
        title.add_css_class ("title-1");
        title.set_halign (Gtk.Align.START);
        box.append (title);

        var subtitle = new Gtk.Label (game.display_subtitle ());
        subtitle.add_css_class ("dim-label");
        subtitle.set_halign (Gtk.Align.START);
        box.append (subtitle);

        // Wybór wersji Proton do trybu bezpośredniego (bypass)
        var proton_label = new Gtk.Label ("Wersja Proton (tryb bezpośredni):");
        proton_label.set_halign (Gtk.Align.START);
        proton_label.set_margin_top (6);
        box.append (proton_label);

        var names = new Gee.ArrayList<string> ();
        foreach (var p in proton_installs)
            names.add (Path.get_basename (p));
        if (names.is_empty)
            names.add ("(brak wykrytej instalacji Proton)");

        var string_list = new Gtk.StringList (names.to_array ());
        proton_dropdown = new Gtk.DropDown (string_list, null);
        box.append (proton_dropdown);

        box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var group1 = new Gtk.Label ("Poprzez protontricks");
        group1.add_css_class ("heading");
        group1.set_halign (Gtk.Align.START);
        box.append (group1);

        box.append (make_action_button ("Otwórz protontricks (GUI winetricks)", "applications-system-symbolic",
            () => run_protontricks_gui (game)));
        box.append (make_action_button ("winecfg przez protontricks", "preferences-system-symbolic",
            () => run_protontricks_verb (game, "winecfg")));
        box.append (make_action_button ("Lista zainstalowanych verbs (protontricks -l)", "view-list-symbolic",
            () => run_protontricks_list_apps ()));

        box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var group2 = new Gtk.Label ("Tryb bezpośredni (bypass protontricks) — polecane, gdy protontricks zawodzi");
        group2.add_css_class ("heading");
        group2.set_halign (Gtk.Align.START);
        group2.set_wrap (true);
        box.append (group2);

        box.append (make_action_button ("winecfg bezpośrednio", "preferences-system-symbolic",
            () => run_direct (game, "winecfg", DirectBypass.winecfg_argv)));
        box.append (make_action_button ("winetricks (GUI) bezpośrednio", "applications-system-symbolic",
            () => run_direct (game, "winetricks", DirectBypass.winetricks_gui_argv)));
        box.append (make_action_button ("Zabij wineserver dla tego prefixu", "process-stop-symbolic",
            () => run_direct (game, "wineserver -k", DirectBypass.kill_wineserver_argv)));
        box.append (make_action_button ("Otwórz folder prefixu w menedżerze plików", "folder-open-symbolic",
            () => open_prefix_folder (game)));

        var verb_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        var verb_entry = new Gtk.Entry ();
        verb_entry.set_placeholder_text ("np. vcrun2019, corefonts, d3dx9…");
        verb_entry.set_hexpand (true);
        var verb_btn = new Gtk.Button.with_label ("Zainstaluj verb (bezpośrednio)");
        verb_btn.add_css_class ("suggested-action");
        verb_btn.clicked.connect (() => {
            string verb = verb_entry.get_text ().strip ();
            if (verb != "")
                run_direct (game, "winetricks %s".printf (verb),
                    (g, p) => { return DirectBypass.winetricks_verb_argv (g, p, verb); });
        });
        verb_box.append (verb_entry);
        verb_box.append (verb_btn);
        box.append (verb_box);

        var exe_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        var exe_btn = new Gtk.Button.with_label ("Uruchom plik .exe w prefixie…");
        exe_btn.clicked.connect (() => choose_and_run_exe (game));
        exe_box.append (exe_btn);
        box.append (exe_box);

        right_scroller.set_child (box);
    }

    private Gtk.Button make_action_button (string label, string icon_name, owned CommandCallback cb) {
        var btn = new Gtk.Button ();
        var content = new Adw.ButtonContent ();
        content.set_icon_name (icon_name);
        content.set_label (label);
        btn.set_child (content);
        btn.clicked.connect (() => cb ());
        return btn;
    }

    private delegate void CommandCallback ();

    private string? current_proton_dir () {
        if (proton_installs.is_empty)
            return null;
        uint idx = proton_dropdown.get_selected ();
        if (idx >= proton_installs.size)
            idx = 0;
        return proton_installs[(int) idx];
    }

    private void append_log (string text, bool is_error) {
        Gtk.TextIter iter;
        log_buffer.get_end_iter (out iter);
        log_buffer.insert (ref iter, (is_error ? "⚠ " : "") + text + "\n", -1);
        var mark = log_buffer.create_mark (null, iter, false);
        log_view.scroll_mark_onscreen (mark);
    }

    private void run_and_log (string[] argv, string[]? env, string label) {
        append_log ("$ %s".printf (string.joinv (" ", argv)), false);
        var runner = new CommandRunner ();
        runner.line_received.connect ((line, is_err) => append_log (line, is_err));
        runner.finished.connect ((status) => {
            append_log ("[%s] zakończono (kod %d)".printf (label, status), status != 0);
        });
        runner.run (argv, env);
    }

    private void run_protontricks_gui (Game game) {
        run_and_log (backend.build_argv ({ "--gui", game.appid }), null, "protontricks GUI");
    }

    private void run_protontricks_verb (Game game, string verb) {
        run_and_log (backend.build_argv ({ game.appid, verb }), null, "protontricks " + verb);
    }

    private void run_protontricks_list_apps () {
        run_and_log (backend.build_argv ({ "--list" }), null, "protontricks --list");
    }

    private delegate string[] ArgvBuilder (Game game, string proton_dir);

    private void run_direct (Game game, string label, ArgvBuilder builder) {
        string? proton_dir = current_proton_dir ();
        if (proton_dir == null) {
            append_log ("Brak wykrytej instalacji Proton — nie można uruchomić trybu bezpośredniego.", true);
            return;
        }
        var argv = builder (game, proton_dir);
        var env = DirectBypass.build_env (game, proton_dir);
        run_and_log (argv, env, label);
    }

    private void open_prefix_folder (Game game) {
        try {
            AppInfo.launch_default_for_uri ("file://" + game.pfx_path (), null);
        } catch (Error e) {
            append_log ("Nie udało się otworzyć folderu: %s".printf (e.message), true);
        }
    }

    private void choose_and_run_exe (Game game) {
        var dialog = new Gtk.FileDialog ();
        dialog.set_title ("Wybierz plik .exe do uruchomienia w prefixie");
        var filter = new Gtk.FileFilter ();
        filter.add_pattern ("*.exe");
        filter.name = "Pliki wykonywalne Windows";
        var filters = new ListStore (typeof (Gtk.FileFilter));
        filters.append (filter);
        dialog.set_filters (filters);

        dialog.open.begin (this, null, (obj, res) => {
            try {
                var file = dialog.open.end (res);
                if (file == null)
                    return;
                string path = file.get_path ();
                run_direct (game, "wine " + path, (g, p) => { return DirectBypass.run_exe_argv (g, p, path); });
            } catch (Error e) {
                // użytkownik anulował lub błąd - ignorujemy
            }
        });
    }
}

private class ProtonManager.GameRow : Gtk.ListBoxRow {
    public Game game;

    public GameRow (Game game) {
        this.game = game;
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        box.set_margin_start (10);
        box.set_margin_end (10);
        box.set_margin_top (8);
        box.set_margin_bottom (8);

        var name_label = new Gtk.Label (game.name);
        name_label.set_halign (Gtk.Align.START);
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        var sub_label = new Gtk.Label (game.display_subtitle ());
        sub_label.add_css_class ("dim-label");
        sub_label.add_css_class ("caption");
        sub_label.set_halign (Gtk.Align.START);

        box.append (name_label);
        box.append (sub_label);
        this.set_child (box);
    }
}
