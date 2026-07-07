public class ProtonManager.Game : Object {
    public string appid { get; set; }
    public string name { get; set; }
    public string library_path { get; set; }   // .../steamapps
    public string install_dir { get; set; }     // .../steamapps/common/<Nazwa>
    public string compatdata_path { get; set; } // .../steamapps/compatdata/<appid>
    public bool has_prefix { get; set; }

    public Game (string appid, string name, string library_path) {
        this.appid = appid;
        this.name = name;
        this.library_path = library_path;
        this.install_dir = "";
        this.compatdata_path = Path.build_filename (library_path, "compatdata", appid);
        this.has_prefix = FileUtils.test (
            Path.build_filename (this.compatdata_path, "pfx"), FileTest.IS_DIR);
    }

    public string pfx_path () {
        return Path.build_filename (compatdata_path, "pfx");
    }

    public string display_subtitle () {
        if (has_prefix)
            return "AppID %s • prefix obecny".printf (appid);
        return "AppID %s • brak prefixu Proton".printf (appid);
    }
}
