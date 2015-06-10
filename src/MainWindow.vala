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
 * 
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

	//headerbar
    private HeaderBar headerbar;
	

    //
	private Box box_main;

    //infobar
    private NotificationsContainer notification_container;

    //
	private Paned paned;
	private SideBar sidebar;

	

	//snapshots
	private SnapshotsList snapshots_list_widget;
	
	//timers
	private uint timer_status_message;
	private uint timer_progress;
	private uint timer_backup_device_init;
	
	//other
	private Device snapshot_device_original;

	public MainWindow () 
	{
		this.title = AppName;
        this.window_position = WindowPosition.CENTER;
        this.modal = true;
        this.set_default_size (800, 600);
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

		//infobar ----------------------------------------------------
		notification_container = new NotificationsContainer();
		box_main.pack_start(notification_container, false, false, 0);

		//sidebar ----------------------------------------------------
		sidebar = new SideBar();
		sidebar.item_selected.connect(sidebar_updated);

	    //snapshot list ----------------------------------------------------
	    snapshots_list_widget = new SnapshotsList();

		//Create a 2 section pane and add the sidebar and snapshot list above------------------------------
		Gtk.Paned pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
		pane.add1 (sidebar);
		pane.add2(snapshots_list_widget);
		pane.set_position(150);
		box_main.pack_start(pane, false, true, 0);
        
        
        snapshot_device_original = App.snapshot_device;
		
		sidebar.refresh_items();
		timer_backup_device_init = Timeout.add(100, init_backup_device);
    }

    private void boom()
    {
				string msg = "it works.";

				var dialog = new Gtk.MessageDialog.with_markup(this, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.OK_CANCEL, msg);
				dialog.set_title(_("Disable Scheduled Snapshots"));
				dialog.set_default_size (300, -1);
				dialog.set_transient_for(this);
				dialog.set_modal(true);
				int response = dialog.run();
				dialog.destroy();
				
				if (response == Gtk.ResponseType.OK){

				}
				else{

				}

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
		
		if (App.live_system()){
			statusbar_message(_("Checking backup device..."));
		}
		else{
			statusbar_message(_("Estimating system size..."));
		}
		
		sidebar.refresh_items(); 

		//refresh_tv_backups();

		update_statusbar();

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

	private void show_statusbar_icons(bool visible){
		//hide a loading icon on this line
		// turn off the progress bar here on this line
		// hide status message on this line
		
		//if (App.is_live_system()){
			//visible = false;
		//}
		
	}

	private void statusbar_message (string message){
		if (timer_status_message > 0){
			Source.remove (timer_status_message);
			timer_status_message = -1;
		}

		// the message coming in here is for the status bar set it on this line
	}
	
	private void statusbar_message_with_timeout (string message, bool success){
		if (timer_status_message > 0){
			Source.remove (timer_status_message);
			timer_status_message = -1;
		}

		// the message coming in here is for the status bar set it on this line
		
		// trn on the loading icon here on this line
		// turn on the progress bar here
		
		
		timer_status_message = Timeout.add_seconds (5, statusbar_clear);
	}
	
    private bool statusbar_clear (){
		if (timer_status_message > 0){
			Source.remove (timer_status_message);
			timer_status_message = -1;
		}
		// clear the status message on this line
		show_statusbar_icons(true);
		return true;
	}
	
	private void update_ui(bool enable){
		headerbar.sensitive = enable;
		//sw_backups.sensitive = enable;
		show_statusbar_icons(enable);
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
		
		// set the message on this line on the status bar from App.progress_text;
		
		timer_progress = Timeout.add_seconds(1, update_progress);
		return true;
	}

	private void update_progress_stop(){
		if (timer_progress > 0){
			Source.remove(timer_progress);
			timer_progress = 0;
		}
	}
	
	private bool check_backup_device_online(){
		if (!App.backup_device_online()){
			gtk_messagebox(_("Device Offline"),_("Backup device is not available"), null, true);
			update_statusbar();
			return false;
		}
		else{
			return true;
		}
	}

	private void update_statusbar(){
		string img_dot_red = App.share_folder + "/timeshift/images/item-red.png";
		string img_dot_green = App.share_folder + "/timeshift/images/item-green.png";
		
		//check free space on backup device ---------------------------
			
		string message = "";
		int status_code = App.check_backup_device(out message);
		string txt;

		switch(status_code){
			case -1:
				if (App.snapshot_device == null){
					txt = _("Please select the backup device");
				}
				else{
					txt = _("Backup device is not mounted!");;
				}
				txt = "<span foreground=\"#8A0808\">" + txt + "</span>";
				//lbl_backup_device_warning.label = txt;
				//lbl_backup_device_warning.visible = true;
				break;
				
			case 1:
				txt = _("Backup device does not have enough space!");
				txt = "<span foreground=\"#8A0808\">" + txt + "</span>";
				//lbl_backup_device_warning.label = txt;
				//lbl_backup_device_warning.visible = true;
				break;
				
			case 2:
				long required = App.calculate_size_of_first_snapshot();
				txt = _("Backup device does not have enough space!") + " ";
				txt += _("First snapshot needs") + " %.1f GB".printf(required/1024.0);
				txt = "<span foreground=\"#8A0808\">" + txt + "</span>";
				//lbl_backup_device_warning.label = txt;
				//lbl_backup_device_warning.visible = true;
				break;
			 
			default:
				//lbl_backup_device_warning.label = "";
				//lbl_backup_device_warning.visible = false;
				break;
		}

		// statusbar icons ---------------------------------------------------------
		
		//status - scheduled snapshots -----------


		if (App.live_system()){
			notification_container.live_system_notification_on();
		}
		else
		{
			if (!App.is_scheduled)
			{
				notification_container.scheduled_snapshots_notification_on();
			}
			else 
			{
				notification_container.scheduled_snapshots_notification_off();
			}
		}

		//status - last snapshot -----------
		
		if (status_code >= 0)
		{
			DateTime now = new DateTime.now_local();
			TimeShiftBackup last_snapshot = App.get_latest_snapshot();
			DateTime last_snapshot_date = (last_snapshot == null) ? null : last_snapshot.date;
			
			if (last_snapshot != null)
			{
				float days = ((float) now.difference(last_snapshot_date) / TimeSpan.DAY);
				float hours = ((float) now.difference(last_snapshot_date) / TimeSpan.HOUR);
				
				if (days > 1){
					// last snapshot older than a day so let the user know they should take a snapshot
					notification_container.last_snapshot_notification_on(" %.0f ".printf(days));
				}
				else {
					// last snapshot is less than a day old so why bug the user
					notification_container.last_snapshot_notification_off();
				}
			}
		}
		else
		{
			// not sure why we''re here
			notification_container.last_snapshot_notification_off();
		}
	}
	
}