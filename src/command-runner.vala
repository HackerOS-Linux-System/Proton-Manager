public class ProtonManager.CommandRunner : Object {

    public signal void line_received (string line, bool is_error);
    public signal void finished (int exit_status);

    public void run (string[] argv, string[]? extra_env = null) {
        try {
            string[] env = Environ.get ();
            if (extra_env != null) {
                foreach (var kv in extra_env) {
                    int eq = kv.index_of ("=");
                    if (eq > 0)
                        env = Environ.set_variable (env, kv.substring (0, eq), kv.substring (eq + 1));
                }
            }

            var launcher = new SubprocessLauncher (
                SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_PIPE);
            launcher.set_environ (env);

            var proc = launcher.spawnv (argv);

            read_stream.begin (proc.get_stdout_pipe (), false);
            read_stream.begin (proc.get_stderr_pipe (), true);

            proc.wait_async.begin (null, (obj, res) => {
                try {
                    proc.wait_async.end (res);
                } catch (Error e) {}
                finished (proc.get_exit_status ());
            });
        } catch (Error e) {
            line_received ("Błąd uruchamiania: %s".printf (e.message), true);
            finished (-1);
        }
    }

    private async void read_stream (InputStream? stream, bool is_error) {
        if (stream == null)
            return;
        var dis = new DataInputStream (stream);
        try {
            string? line;
            while ((line = yield dis.read_line_async (Priority.DEFAULT)) != null) {
                line_received (line, is_error);
            }
        } catch (Error e) {
            // strumień zamknięty przy zakończeniu procesu — pomijamy
        }
    }
}
