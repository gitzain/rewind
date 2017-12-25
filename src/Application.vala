using Gtk;

namespace RewindUtil 
{
    public class Application : Granite.Application 
    {
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







	//backup
	
	public bool take_snapshot (bool is_ondemand, string snapshot_comments, Gtk.Window? parent_win)
    {
		if (check_btrfs_root_layout() == false)
        {
			return false;
		}
		
		bool status;
		bool update_symlinks = false;

		try
		{
			//create a timestamp
			DateTime now = new DateTime.now_local();

			//mount_backup_device
			if (!mount_backup_device(parent_win)){
				return false;
			}
			
			//check backup device
			string msg;
			int status_code = check_backup_device(out msg);
			
			if (!is_ondemand){
				//check if first snapshot was taken
				if (status_code == 2){
					log_error(_("First snapshot not taken"));
					log_error(_("Please take the first snapshot by running 'sudo rewind --backup-now'"));
					return false;
				}
			}
			
			//check space
			if ((status_code == 1) || (status_code == 2)){
				is_scheduled = false;
				log_error(_("Backup device does not have enough space!") + " " + msg);
				return false;
			}

			//create snapshot root if missing
			var f = File.new_for_path(snapshot_dir);
			if (!f.query_exists()){
				f.make_directory_with_parents();
			}

			//ondemand
			if (is_ondemand)
            {
				bool ok = backup_and_rotate("ondemand",now);

				if(!ok)
                {
					return false;
				}
				else
                {
					update_symlinks = true;
				}
			}
			else
            {
				log_msg(_("Scheduled snapshots are disabled") + " - " + _("Nothing to do!"));
				cron_job_update();
			}

			auto_delete_backups();
			
			if (update_symlinks){
				update_snapshot_list();
				create_symlinks();
			}
		}
		catch(Error e){
			log_error (e.message);
			return false;
		}

		return true;
	}









    }

}
