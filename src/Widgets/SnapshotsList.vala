/*
 * SnapshoptsList.vala
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

using TeeJee.Devices;

using TeeJee.GtkHelper;

public class SnapshoptsList : Gtk.Box 
{
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

    public SnapshoptsList () 
    {
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

    }

    

}
