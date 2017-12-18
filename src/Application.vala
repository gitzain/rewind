using Gtk;

namespace RewindUtil {

public class Application : Granite.Application {
        public MainWindow app_window;


        public Application () {
            Object (flags: ApplicationFlags.FLAGS_NONE,
            application_id: "com.github.lainsce.coin");

            var rewind = new Rewind();

        }

        construct {
            app_icon = "com.github.lainsce.coin";
            exec_name = "com.github.lainsce.coin";
            app_launcher = "com.github.lainsce.coin";
        }


        protected override void activate () {
            if (get_windows ().length () > 0) {
                app_window.present ();
                return;
            }

            app_window = new MainWindow ();
            app_window.destroy.connect(main_quit);
            app_window.show_all ();
            Gtk.main ();
        }



        public static int main (string[] args) {
            var app = new RewindUtil.Application ();
            return app.run (args);
        }
}


}
