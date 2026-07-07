public class ProtonManager.Application : Adw.Application {

    public Application () {
        Object (
            application_id: "com.protonmanager.App",
            flags: ApplicationFlags.DEFAULT_FLAGS
        );

        var about_action = new SimpleAction ("about", null);
        about_action.activate.connect (show_about);
        this.add_action (about_action);
    }

    protected override void activate () {
        var window = this.active_window;
        if (window == null)
            window = new ProtonManager.Window (this);
        window.present ();
    }

    private void show_about () {
        var about = new Adw.AboutWindow () {
            application_name = "Proton Manager",
            application_icon = "applications-games-symbolic",
            developer_name = "Proton Manager Contributors",
            version = "0.1.0",
            license_type = Gtk.License.GPL_3_0,
            comments = "Nakładka na protontricks i Proton, ułatwiająca zarządzanie prefixami Wine/Proton oraz omijająca problemy protontricks trybem bezpośrednim.",
            transient_for = this.active_window,
        };
        about.present ();
    }
}
