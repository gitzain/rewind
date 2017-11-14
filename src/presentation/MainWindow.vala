/*
 * MainWindow.vala
 * 
 * Copyright 2015 Zain Khan <emailzainkhan@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * test
 */
 
using Gtk;
using Gee;
using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.Devices;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

class MainWindow : Gtk.Window {

    private HeaderBar headerbar;
	private Box box_main;
	private Gtk.Paned paned;
	private SideBar sidebar;
	private SnapshotsList snapshots_list_widget;
	
	//timers
	private uint timer_status_message;
	private uint timer_progress;
	private uint timer_backup_device_init;
	
	//other
	private Device snapshot_device_original;
	private Gtk.Paned pane;

	public MainWindow () 
	{
		this.title = AppName;
        this.window_position = WindowPosition.CENTER;
        this.modal = true;
        this.set_default_size (800, 550);
		this.delete_event.connect(on_delete_event);
		this.icon = get_app_icon(16);
		this.set_position(Gtk.WindowPosition.CENTER);
		this.set_size_request (500, 250);
		
        //headerbar ---------------------------------------------------
		headerbar = new HeaderBar();
		this.set_titlebar(headerbar);

		//main container under headerbar------------------------------
        box_main = new Box (Orientation.VERTICAL, 0);
        box_main.margin = 0;
        this.add(box_main);

		//sidebar ----------------------------------------------------
		sidebar = new SideBar();
		sidebar.drive_list.item_changed.connect(sidebar_updated);

	    //snapshot list ----------------------------------------------------
	    snapshots_list_widget = new SnapshotsList();

		headerbar.btn_restore_backup.clicked.connect(snapshots_list_widget.restore);

		snapshots_list_widget.tv_backups.cursor_changed.connect(() => {
			TreeSelection selection = snapshots_list_widget.tv_backups.get_selection();

			if (selection.count_selected_rows() == 1)
			{
				headerbar.btn_restore_backup.sensitive = true;
			}
			else 
			{
				headerbar.btn_restore_backup.sensitive = false;	
			}
		});

		//Create a 2 section pane and add the sidebar and snapshot list above------------------------------
		pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
		pane.add1(sidebar);
		pane.add2(snapshots_list_widget);

		pane.set_position(150);
		box_main.pack_start(pane);

        snapshot_device_original = App.snapshot_device;
		
		sidebar.refresh_items();
		sidebar.select_first_item();
		timer_backup_device_init = Timeout.add(100, init_backup_device);

    }

    private void sidebar_updated()
    {
    	timer_backup_device_init = Timeout.add(100, init_backup_device);
    }

	private bool init_backup_device(){
		
		/* updates statusbar messages and snapshot list after backup device is changed */
		
		if (timer_backup_device_init > 0){
			Source.remove(timer_backup_device_init);
			timer_backup_device_init = -1;
		}
		
		update_ui(false);
		
		sidebar.refresh_items(); 

		snapshots_list_widget.refresh_tv_backups();

		update_ui(true);

		return false;
	}
	
	private bool on_delete_event(Gdk.EventAny event){
		
		this.delete_event.disconnect(on_delete_event); //disconnect this handler

		if (App.is_rsync_running()){
			log_error (_("Main window closed by user"));
			App.kill_rsync();
		}

		if (!App.is_scheduled){
			return false; //close window
		}
		
		//else - check backup device -------------------------------
		
		string message;
		int status_code = App.check_backup_device(out message);

		switch(status_code){
			case 1:
				string msg = message + "\n";
				msg += _("Scheduled snapshots will be disabled.");

				var dialog = new Gtk.MessageDialog.with_markup(this, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.OK_CANCEL, msg);
				dialog.set_title(_("Disable Scheduled Snapshots"));
				dialog.set_default_size (300, -1);
				dialog.set_transient_for(this);
				dialog.set_modal(true);
				int response = dialog.run();
				dialog.destroy();
				
				if (response == Gtk.ResponseType.OK){
					App.is_scheduled = false;
					return false; //close window
				}
				else{
					this.delete_event.connect(on_delete_event); //reconnect this handler
					return true; //keep window open
				}

			case 2:
				string msg = _("Selected device does not have enough space.") + "\n";
				msg += _("Scheduled snapshots will be disabled till another device is selected.") + "\n";
				msg += _("Do you want to select another device now?") + "\n";
				
				var dialog = new Gtk.MessageDialog.with_markup(this, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.YES_NO, msg);
				dialog.set_title(_("Disable Scheduled Snapshots"));
				dialog.set_default_size (300, -1);
				dialog.set_transient_for(this);
				dialog.set_modal(true);
				int response = dialog.run();
				dialog.destroy();
				
				if (response == Gtk.ResponseType.YES){
					this.delete_event.connect(on_delete_event); //reconnect this handler
					return true; //keep window open
				}
				else{
					App.is_scheduled = false;
					return false; //close window
				}
				
			case 3:
				string msg = _("Scheduled jobs will be enabled only after the first snapshot is taken.") + "\n";
				msg += message + (" space and 10 minutes to complete.") + "\n";
				msg += _("Do you want to take the first snapshot now?") + "\n";
				
				var dialog = new Gtk.MessageDialog.with_markup(this, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.YES_NO, msg);
				dialog.set_title(_("First Snapshot"));
				dialog.set_default_size (300, -1);
				dialog.set_transient_for(this);
				dialog.set_modal(true);
				int response = dialog.run();
				dialog.destroy();
				
				if (response == Gtk.ResponseType.YES){
					backup_clicked();
					this.delete_event.connect(on_delete_event); //reconnect this handler
					return true; //keep window open
				}
				else{
					App.is_scheduled = false;
					return false; //close window
				}
				
			case 0:
				if (App.snapshot_device.uuid != snapshot_device_original.uuid){
					log_debug(_("snapshot device changed"));
					
					string msg = _("Scheduled snapshots will be saved to ") + "<b>%s</b>\n".printf(App.snapshot_device.device);
					msg += _("Click 'OK' to confirm") + "\n";
					
					var dialog = new Gtk.MessageDialog.with_markup(this, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK_CANCEL, msg);
					dialog.set_title(_("Backup Device Changed"));
					dialog.set_default_size (300, -1);
					dialog.set_transient_for(this);
					dialog.set_modal(true);
					int response = dialog.run();
					dialog.destroy();
					
					if (response == Gtk.ResponseType.CANCEL){
						this.delete_event.connect(on_delete_event); //reconnect this handler
						return true; //keep window open
					}
				}
				break;
				
			case -1:
				string msg = _("The backup device is not set or unavailable.") + "\n";
				msg += _("Scheduled snapshots will be disabled.") + "\n";
				msg += _("Do you want to select another device?");

				var dialog = new Gtk.MessageDialog.with_markup(this, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK_CANCEL, msg);
				dialog.set_title(_("Backup Device Changed"));
				dialog.set_default_size (300, -1);
				dialog.set_transient_for(this);
				dialog.set_modal(true);
				int response = dialog.run();
				dialog.destroy();
				
				if (response == Gtk.ResponseType.YES){
					this.delete_event.connect(on_delete_event); //reconnect this handler
					return true; //keep window open
				}
				else{
					App.is_scheduled = false;
					return false; //close window
				}
			
		}

		return false;
	}

	private void backup_clicked()
	{
		headerbar.btn_backup_clicked();
	}
	
	private void update_ui(bool enable){
		headerbar.sensitive = enable;
		snapshots_list_widget.sensitive = enable;
		gtk_set_busy(!enable, this);
	}
	
	private void update_progress_start(){
		timer_progress = Timeout.add_seconds(1, update_progress);
	}
	
    private bool update_progress (){
		if (timer_progress > 0){
			Source.remove(timer_progress);
			timer_progress = 0;
		}
		
		timer_progress = Timeout.add_seconds(1, update_progress);
		return true;
	}

	private void update_progress_stop(){
		if (timer_progress > 0){
			Source.remove(timer_progress);
			timer_progress = 0;
		}
	}

	public void action_about () {
            App.show_about (this);
        }
}
