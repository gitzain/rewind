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
	private Box box_snapshots;

	//snapshots
	private ScrolledWindow sw_backups;
	private TreeView tv_backups;
    private TreeViewColumn col_date;
    private TreeViewColumn col_tags;
    private TreeViewColumn col_system;
    private TreeViewColumn col_desc;
	private int tv_backups_sort_column_index = 0;
	private bool tv_backups_sort_column_desc = true;
	private Box contextButtons;

	private ToolButton btn_restore;
	private ToolButton btn_delete_snapshot;
	private ToolButton btn_browse_snapshot;
	private ToolButton btn_view_snapshot_log;
	
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
        box_snapshots = new Box (Orientation.VERTICAL, 0);
        box_snapshots.margin = 0;

        tv_backups = new TreeView();
		tv_backups.get_selection().mode = SelectionMode.MULTIPLE;
		tv_backups.headers_clickable = true;
		tv_backups.has_tooltip = true;
		tv_backups.set_rules_hint (true);

		contextButtons = new Box (Orientation.HORIZONTAL, 0);

		Button btnDelete = new Button.with_label ("Delete");
		btnDelete.get_style_context().add_class("destructive-action"); // Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION
		contextButtons.pack_start(btnDelete, false, false, 12);
		//btn_delete_snapshot.clicked.connect (btn_delete_snapshot_clicked);

		Button btnBrowse = new Button.with_label ("Browse");
		contextButtons.pack_end(btnBrowse, false, false, 12);
		//btn_browse_snapshot.clicked.connect (btn_browse_snapshot_clicked);

		Button btnRestore = new Button.with_label ("Restore");
		contextButtons.pack_end(btnRestore, false, false, 0);
		//btn_restore.clicked.connect (btn_restore_clicked);

		Button btnSnapshopLog = new Button.with_label ("View Snapshot Log");
		btnSnapshopLog.set_tooltip_text (_("View rsync log for selected snapshot"));
		contextButtons.pack_end(btnSnapshopLog, false, false, 12);
		btnSnapshopLog.clicked.connect (btn_view_snapshot_log_clicked);

		box_snapshots.pack_end(contextButtons, false, true, 12);

		//sw_backups
		sw_backups = new ScrolledWindow(null, null);
		sw_backups.set_shadow_type (ShadowType.ETCHED_IN);
		sw_backups.add (tv_backups);
		sw_backups.expand = true;
		// sw_backups.margin_left = 6;
		// sw_backups.margin_right = 6;
		// sw_backups.margin_top = 6;
		// sw_backups.margin_bottom = 6;
		box_snapshots.add(sw_backups);

        //col_date
		col_date = new TreeViewColumn();
		col_date.title = _("Snapshot");
		col_date.clickable = true;
		col_date.resizable = true;
		col_date.spacing = 1;
		
		CellRendererPixbuf cell_backup_icon = new CellRendererPixbuf ();
		cell_backup_icon.stock_id = "gtk-floppy";
		cell_backup_icon.xpad = 1;
		col_date.pack_start (cell_backup_icon, false);
		
		CellRendererText cell_date = new CellRendererText ();
		col_date.pack_start (cell_date, false);
		col_date.set_cell_data_func (cell_date, cell_date_render);
		
		tv_backups.append_column(col_date);
		
		col_date.clicked.connect(() => {
			if(tv_backups_sort_column_index == 0){
				tv_backups_sort_column_desc = !tv_backups_sort_column_desc;
			}
			else{
				tv_backups_sort_column_index = 0;
				tv_backups_sort_column_desc = true;
			}
			refresh_tv_backups();
		});
		
		//col_system
		col_system = new TreeViewColumn();
		col_system.title = _("System");
		col_system.resizable = true;
		col_system.clickable = true;
		col_system.min_width = 150;
		
		CellRendererText cell_system = new CellRendererText ();
		cell_system.ellipsize = Pango.EllipsizeMode.END;
		col_system.pack_start (cell_system, false);
		col_system.set_cell_data_func (cell_system, cell_system_render);
		tv_backups.append_column(col_system);
		
		col_system.clicked.connect(() => {
			if(tv_backups_sort_column_index == 1){
				tv_backups_sort_column_desc = !tv_backups_sort_column_desc;
			}
			else{
				tv_backups_sort_column_index = 1;
				tv_backups_sort_column_desc = false;
			}
			refresh_tv_backups();
		});
		
		//col_tags
		col_tags = new TreeViewColumn();
		col_tags.title = _("Tags");
		col_tags.resizable = true;
		//col_tags.min_width = 80;
		col_tags.clickable = true;
		CellRendererText cell_tags = new CellRendererText ();
		cell_tags.ellipsize = Pango.EllipsizeMode.END;
		col_tags.pack_start (cell_tags, false);
		col_tags.set_cell_data_func (cell_tags, cell_tags_render);
		tv_backups.append_column(col_tags);
		
		col_tags.clicked.connect(() => {
			if(tv_backups_sort_column_index == 2){
				tv_backups_sort_column_desc = !tv_backups_sort_column_desc;
			}
			else{
				tv_backups_sort_column_index = 2;
				tv_backups_sort_column_desc = false;
			}
			refresh_tv_backups();
		});

		//cell_desc
		col_desc = new TreeViewColumn();
		col_desc.title = _("Comments");
		col_desc.resizable = true;
		col_desc.clickable = true;
		CellRendererText cell_desc = new CellRendererText ();
		cell_desc.ellipsize = Pango.EllipsizeMode.END;
		col_desc.pack_start (cell_desc, false);
		col_desc.set_cell_data_func (cell_desc, cell_desc_render);
		tv_backups.append_column(col_desc);
		cell_desc.editable = true;
		
		cell_desc.edited.connect (cell_desc_edited);

		//tooltips
		tv_backups.query_tooltip.connect ((x, y, keyboard_tooltip, tooltip) => {
			TreeModel model;
			TreePath path;
			TreeIter iter;
			TreeViewColumn col;
			if (tv_backups.get_tooltip_context (ref x, ref y, keyboard_tooltip, out model, out path, out iter)){
				int bx, by;
				tv_backups.convert_widget_to_bin_window_coords(x, y, out bx, out by);
				if (tv_backups.get_path_at_pos (bx, by, null, out col, null, null)){
					if (col == col_date){
						tooltip.set_markup(_("<b>Snapshot Date:</b> Date on which snapshot was created"));
						return true;
					}
					else if (col == col_desc){
						tooltip.set_markup(_("<b>Comments</b> (double-click to edit)"));
						return true;
					}
					else if (col == col_system){
						tooltip.set_markup(_("<b>System:</b> Installed Linux distribution"));
						return true;
					}
					else if (col == col_tags){
						tooltip.set_markup(_("<b>Backup Levels</b>\n\nO	On demand (manual)\nB	Boot\nH	Hourly\nD	Daily\nW	Weekly\nM	Monthly"));
						return true;
					}
				}
			}

			return false;
		});

		//Create a 2 section pane and add the sidebar and snapshot list above------------------------------
		Gtk.Paned pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
		pane.add1 (sidebar);
		pane.add2 (box_snapshots);
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

		refresh_tv_backups();

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
	
	private void cell_date_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){
		TimeShiftBackup bak;
		model.get (iter, 0, out bak, -1);
		(cell as Gtk.CellRendererText).text = bak.date.format ("%Y-%m-%d %I:%M %p");
	}
	
	private void cell_tags_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){
		TimeShiftBackup bak;
		model.get (iter, 0, out bak, -1);
		(cell as Gtk.CellRendererText).text = bak.taglist_short;
	}

	private void cell_system_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){
		TimeShiftBackup bak;
		model.get (iter, 0, out bak, -1);
		(cell as Gtk.CellRendererText).text = bak.sys_distro;
	}
	
	private void cell_desc_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){
		TimeShiftBackup bak;
		model.get (iter, 0, out bak, -1);
		(cell as Gtk.CellRendererText).text = bak.description;
	}
	
	private void cell_desc_edited (string path, string new_text) {
		TimeShiftBackup bak;

		TreeIter iter;
		ListStore model = (ListStore) tv_backups.model;
		model.get_iter_from_string (out iter, path);
		model.get (iter, 0, out bak, -1);
		bak.description = new_text;
		bak.update_control_file();
	}

	private void cell_backup_device_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){
		Device info;
		model.get (iter, 0, out info, -1);

		(cell as Gtk.CellRendererText).markup = info.description_formatted();
	}

	private void refresh_tv_backups(){
		
		App.update_snapshot_list();
		
		ListStore model = new ListStore(1, typeof(TimeShiftBackup));
		
		var list = App.snapshot_list;
		
		if (tv_backups_sort_column_index == 0){
			
			if (tv_backups_sort_column_desc)
			{
				list.sort((a,b) => { 
					TimeShiftBackup t1 = (TimeShiftBackup) a;
					TimeShiftBackup t2 = (TimeShiftBackup) b;
					
					return (t1.date.compare(t2.date));
				});
			}
			else{
				list.sort((a,b) => { 
					TimeShiftBackup t1 = (TimeShiftBackup) a;
					TimeShiftBackup t2 = (TimeShiftBackup) b;
					
					return -1 * (t1.date.compare(t2.date));
				});
			}
		}
		else{
			if (tv_backups_sort_column_desc)
			{
				list.sort((a,b) => { 
					TimeShiftBackup t1 = (TimeShiftBackup) a;
					TimeShiftBackup t2 = (TimeShiftBackup) b;
					
					return strcmp(t1.taglist,t2.taglist);
				});
			}
			else{
				list.sort((a,b) => { 
					TimeShiftBackup t1 = (TimeShiftBackup) a;
					TimeShiftBackup t2 = (TimeShiftBackup) b;
					
					return -1 * strcmp(t1.taglist,t2.taglist);
				});
			}
		}

		TreeIter iter;
		foreach(TimeShiftBackup bak in list) {
			model.append(out iter);
			model.set (iter, 0, bak);
		}
			
		tv_backups.set_model (model);
		tv_backups.columns_autosize ();
	}

	private void backup_clicked()
	{
		headerbar.btn_backup_clicked();
	}

	private void btn_delete_snapshot_clicked(){
		TreeIter iter;
		TreeIter iter_delete;
		TreeSelection sel;
		bool is_success = true;
		
		//check if device is online
		if (!check_backup_device_online()) { return; }
		
		//check selected count ----------------
		
		sel = tv_backups.get_selection ();
		if (sel.count_selected_rows() == 0){ 
			gtk_messagebox(_("No Snapshots Selected"),_("Please select the snapshots to delete"),null,false);
			return; 
		}
		
		//update UI ------------------
		
		update_ui(false);
		
		statusbar_message(_("Removing selected snapshots..."));
		
		//get list of snapshots to delete --------------------

		var list_of_snapshots_to_delete = new Gee.ArrayList<TimeShiftBackup>();
		ListStore store = (ListStore) tv_backups.model;
		
		bool iterExists = store.get_iter_first (out iter);
		while (iterExists && is_success) { 
			if (sel.iter_is_selected (iter)){
				TimeShiftBackup bak;
				store.get (iter, 0, out bak);
				list_of_snapshots_to_delete.add(bak);
			}
			iterExists = store.iter_next (ref iter);
		}
		
		//clear selection ---------------
		
		tv_backups.get_selection().unselect_all();
		
		//delete snapshots --------------------------
		
		foreach(TimeShiftBackup bak in list_of_snapshots_to_delete){
			
			//find the iter being deleted
			iterExists = store.get_iter_first (out iter_delete);
			while (iterExists) { 
				TimeShiftBackup bak_current;
				store.get (iter_delete, 0, out bak_current);
				if (bak_current.path == bak.path){
					break;
				}
				iterExists = store.iter_next (ref iter_delete);
			}
			
			//select the iter being deleted
			tv_backups.get_selection().select_iter(iter_delete);
			
			statusbar_message(_("Deleting snapshot") + ": '%s'...".printf(bak.name));
			
			is_success = App.delete_snapshot(bak); 
			
			if (!is_success){
				statusbar_message_with_timeout(_("Error: Unable to delete snapshot") + ": '%s'".printf(bak.name), false);
				break;
			}
			
			//remove iter from tv_backups
			store.remove(iter_delete);
		}
		
		App.update_snapshot_list();
		if (App.snapshot_list.size == 0){
			statusbar_message(_("Deleting snapshot") + ": '.sync'...");
			App.delete_all_snapshots();
		}
		
		if (is_success){
			statusbar_message_with_timeout(_("Snapshots deleted successfully"), true);
		}
		
		//update UI -------------------
		
		App.update_partition_list();
		sidebar.refresh_items();
		refresh_tv_backups();
		update_statusbar();

		update_ui(true);
	}
	
	private void btn_restore_clicked(){
		App.mirror_system = false;
		restore();
	}
	
	private void restore(){
		TreeIter iter;
		TreeSelection sel;
		
		if (!App.mirror_system){
			//check if backup device is online (check #1)
			if (!check_backup_device_online()) { return; }
		}
		
		if (!App.mirror_system){

			//check if single snapshot is selected -------------
			
			sel = tv_backups.get_selection ();
			if (sel.count_selected_rows() == 0){ 
				gtk_messagebox(_("No Snapshots Selected"), _("Please select the snapshot to restore"),null,false);
				return; 
			}
			else if (sel.count_selected_rows() > 1){ 
				gtk_messagebox(_("Multiple Snapshots Selected"), _("Please select a single snapshot"),null,false);
				return; 
			}
			
			//get selected snapshot ------------------
			
			TimeShiftBackup snapshot_to_restore = null;
			
			ListStore store = (ListStore) tv_backups.model;
			sel = tv_backups.get_selection();
			bool iterExists = store.get_iter_first (out iter);
			while (iterExists) { 
				if (sel.iter_is_selected (iter)){
					store.get (iter, 0, out snapshot_to_restore);
					break;
				}
				iterExists = store.iter_next (ref iter);
			}
			
			App.snapshot_to_restore = snapshot_to_restore;
			App.restore_target = App.root_device;
		}
		else{
			App.snapshot_to_restore = null;
			App.restore_target = null;
		}
		
		//show restore window -----------------

		var dialog = new RestoreWindow();
		dialog.set_transient_for (this);
		dialog.show_all();
		int response = dialog.run();
		dialog.destroy();
		
		if (response != Gtk.ResponseType.OK){
			App.unmount_target_device();
			return; //cancel
		}
		
		if (!App.mirror_system){
			//check if backup device is online (check #2)
			if (!check_backup_device_online()) { return; }
		}
		
		//update UI ----------------
		
		update_ui(false);
		
		//take a snapshot if current system is being restored -----------------
		
		if (!App.live_system() && (App.restore_target.device == App.root_device.device) && (App.restore_target.uuid == App.root_device.uuid)){

			string msg = _("Do you want to take a snapshot of the current system before restoring the selected snapshot?");
			
			var dlg = new Gtk.MessageDialog.with_markup(this, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, msg);
			dlg.set_title(_("Take Snapshot"));
			dlg.set_default_size (200, -1);
			dlg.set_transient_for(this);
			dlg.set_modal(true);
			response = dlg.run();
			dlg.destroy();

			if (response == Gtk.ResponseType.YES){
				statusbar_message(_("Taking snapshot..."));
			
				update_progress_start();
				
				bool is_success = App.take_snapshot(true,"",this); 
				
				update_progress_stop();
				
				if (is_success){
					App.update_snapshot_list();
					var latest = App.get_latest_snapshot("ondemand");
					latest.description = _("Before restoring") + " '%s'".printf(App.snapshot_to_restore.name);
					latest.update_control_file();
				}
			}
		}

		if (!App.mirror_system){
			//check if backup device is online (check #3)
			if (!check_backup_device_online()) { return; }
		}
		
		//restore the snapshot --------------------

		if (App.snapshot_to_restore != null){
			log_msg("Restoring snapshot '%s' to device '%s'".printf(App.snapshot_to_restore.name,App.restore_target.device),true);
			statusbar_message(_("Restoring snapshot..."));
		}
		else{
			log_msg("Cloning current system to device '%s'".printf(App.restore_target.device),true);
			statusbar_message(_("Cloning system..."));
		}
		
		if (App.reinstall_grub2){
			log_msg("GRUB will be installed on '%s'".printf(App.grub_device),true);
		}

		bool is_success = App.restore_snapshot(this); 
		
		string msg;
		if (is_success){
			if (App.mirror_system){
				msg = _("System was cloned successfully on target device");
			}
			else{
				msg = _("Snapshot was restored successfully on target device");
			}
			statusbar_message_with_timeout(msg, true);
			
			var dlg = new Gtk.MessageDialog.with_markup(this,Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, msg);
			dlg.set_title(_("Finished"));
			dlg.set_modal(true);
			dlg.set_transient_for(this);
			dlg.run();
			dlg.destroy();
		}
		else{
			if (App.mirror_system){
				msg = _("Cloning Failed!");
			}
			else{
				msg = _("Restore Failed!");
			}

			statusbar_message_with_timeout(msg, true);

			var dlg = new Gtk.MessageDialog.with_markup(this,Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, msg);
			dlg.set_title(_("Error"));
			dlg.set_modal(true);
			dlg.set_transient_for(this);
			dlg.run();
			dlg.destroy();
		}
		
		//update UI ----------------
		
		update_ui(true);
	}
	
	private void btn_browse_snapshot_clicked(){
		
		//check if device is online
		if (!check_backup_device_online()) { 
			return; 
		}
		
		TreeSelection sel = tv_backups.get_selection ();
		if (sel.count_selected_rows() == 0){
			var f = File.new_for_path(App.snapshot_dir);
			if (f.query_exists()){
				exo_open_folder(App.snapshot_dir);
			}
			else{
				exo_open_folder(App.mount_point_backup);
			}
			return;
		}
		
		TreeIter iter;
		ListStore store = (ListStore)tv_backups.model;
		
		bool iterExists = store.get_iter_first (out iter);
		while (iterExists) { 
			if (sel.iter_is_selected (iter)){
				TimeShiftBackup bak;
				store.get (iter, 0, out bak);

				exo_open_folder(bak.path + "/localhost");
				return;
			}
			iterExists = store.iter_next (ref iter);
		}
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
		sw_backups.sensitive = enable;
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

	private void btn_view_snapshot_log_clicked(){
        TreeSelection sel = tv_backups.get_selection ();
        if (sel.count_selected_rows() == 0){
            gtk_messagebox(_("Select Snapshot"),_("Please select a snapshot to view the log!"),null,false);
            return;
        }
        
        TreeIter iter;
        ListStore store = (ListStore)tv_backups.model;
        
        bool iterExists = store.get_iter_first (out iter);
        while (iterExists) { 
            if (sel.iter_is_selected (iter)){
                TimeShiftBackup bak;
                store.get (iter, 0, out bak);

                exo_open_textfile(bak.path + "/rsync-log");
                return;
            }
            iterExists = store.iter_next (ref iter);
        }
    }
	
}