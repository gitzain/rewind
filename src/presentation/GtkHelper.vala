/*
 * GtkHelper.vala
 * 
 * Copyright 2012 Tony George <teejee2008@gmail.com>
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

namespace TeeJee.GtkHelper{
	
	using Gtk;
	using Logging;
	
	public void gtk_do_events (){
				
		/* Do pending events */
		
		while(Gtk.events_pending ())
			Gtk.main_iteration ();
	}

	public void gtk_set_busy (bool busy, Gtk.Window win) {
				
		/* Show or hide busy cursor on window */
		
		Gdk.Cursor? cursor = null;

		if (busy){
			cursor = new Gdk.Cursor(Gdk.CursorType.WATCH);
		}
		else{
			cursor = new Gdk.Cursor(Gdk.CursorType.ARROW);
		}
		
		var window = win.get_window ();
		
		if (window != null) {
			window.set_cursor (cursor);
		}
		
		gtk_do_events ();
	}
	
	public void gtk_messagebox(string title, string message, Gtk.Window? parent_win, bool is_error = false){
				
		/* Shows a simple message box */

		Gtk.MessageType type = Gtk.MessageType.INFO;
		if (is_error){
			type = Gtk.MessageType.ERROR;
		}
		else{
			type = Gtk.MessageType.INFO;
		}
		
		var dlg = new Gtk.MessageDialog.with_markup(null, Gtk.DialogFlags.MODAL, type, Gtk.ButtonsType.OK, message);
		dlg.title = title;
		dlg.set_default_size (300, -1);
		if (parent_win != null){
			dlg.set_transient_for(parent_win);
			dlg.set_modal(true);
		}
		dlg.run();
		dlg.destroy();
	}

	public string gtk_inputbox(string title, string message, Gtk.Window? parent_win, bool mask_password = false){
				
		/* Shows a simple input prompt */
		
		//vbox_main
        Gtk.Box vbox_main = new Box (Orientation.VERTICAL, 0);
        vbox_main.margin = 6;
        
		//lbl_input
		Gtk.Label lbl_input = new Gtk.Label(title);
		lbl_input.xalign = (float) 0.0;
		lbl_input.label = message;
		
		//txt_input
		Gtk.Entry txt_input = new Gtk.Entry();
		txt_input.margin_top = 3;
		txt_input.set_visibility(false);
		
		//create dialog
		var dlg = new Gtk.Dialog.with_buttons(title, parent_win, DialogFlags.MODAL);
		dlg.title = title;
		dlg.set_default_size (300, -1);
		if (parent_win != null){
			dlg.set_transient_for(parent_win);
			dlg.set_modal(true);
		}
		
		//add widgets
		Gtk.Box content = (Box) dlg.get_content_area ();
		vbox_main.pack_start (lbl_input, false, true, 0);
		vbox_main.pack_start (txt_input, false, true, 0);
		content.add(vbox_main);
		
		//add buttons
		dlg.add_button(_("OK"),Gtk.ResponseType.OK);
		dlg.add_button(_("Cancel"),Gtk.ResponseType.CANCEL);
		
		//keyboard shortcuts
		txt_input.key_press_event.connect ((w, event) => {
			if (event.keyval == 65293) {
				dlg.response(Gtk.ResponseType.OK);
				return true;
			}
			return false;
		});
		
		dlg.show_all();
		int response = dlg.run();
		string input_text = txt_input.text;
		dlg.destroy();
		
		if (response == Gtk.ResponseType.CANCEL){
			return "";
		}
		else{
			return input_text;
		}
	}
	
	public bool gtk_combobox_set_value (ComboBox combo, int index, string val){
		
		/* Conveniance function to set combobox value */
		
		TreeIter iter;
		string comboVal;
		TreeModel model = (TreeModel) combo.model;
		
		bool iterExists = model.get_iter_first (out iter);
		while (iterExists){
			model.get(iter, 1, out comboVal);
			if (comboVal == val){
				combo.set_active_iter(iter);
				return true;
			}
			iterExists = model.iter_next (ref iter);
		} 
		
		return false;
	}
	
	public string gtk_combobox_get_value (ComboBox combo, int index, string default_value){
		
		/* Conveniance function to get combobox value */
		
		if (combo.model == null) { return default_value; }
		if (combo.active < 0) { return default_value; }
		
		TreeIter iter;
		string val = "";
		combo.get_active_iter (out iter);
		TreeModel model = (TreeModel) combo.model;
		model.get(iter, index, out val);
			
		return val;
	}

	public class CellRendererProgress2 : Gtk.CellRendererProgress{
		public override void render (Cairo.Context cr, Gtk.Widget widget, Gdk.Rectangle background_area, Gdk.Rectangle cell_area, Gtk.CellRendererState flags) {
			if (text == "--") 
				return;
				
			int diff = (int) ((cell_area.height - height)/2);
			
			// Apply the new height into the bar, and center vertically:
			Gdk.Rectangle new_area = Gdk.Rectangle() ;
			new_area.x = cell_area.x;
			new_area.y = cell_area.y + diff;
			new_area.width = width - 5;
			new_area.height = height;
			
			base.render(cr, widget, background_area, new_area, flags);
		}
	} 
	
	public Gdk.Pixbuf? get_app_icon(int icon_size, string format = ".png"){
		var img_icon = get_shared_icon(AppShortName, AppShortName + format,icon_size,"pixmaps");
		if (img_icon != null){
			return img_icon.pixbuf;
		}
		else{
			return null;
		}
	}
	
	public Gtk.Image? get_shared_icon(string icon_name, string fallback_icon_file_name, int icon_size, string icon_directory = AppShortName + "/images"){
		Gdk.Pixbuf pix_icon = null;
		Gtk.Image img_icon = null;
		
		try {
			Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();
			pix_icon = icon_theme.load_icon (icon_name, icon_size, 0);
		} catch (Error e) {
			//log_error (e.message);
		}
		
		string fallback_icon_file_path = "/usr/share/%s/%s".printf(icon_directory, fallback_icon_file_name);
		
		if (pix_icon == null){ 
			try {
				pix_icon = new Gdk.Pixbuf.from_file_at_size (fallback_icon_file_path, icon_size, icon_size);
			} catch (Error e) {
				log_error (e.message);
			}
		}
		
		if (pix_icon == null){ 
			log_error (_("Missing Icon") + ": '%s', '%s'".printf(icon_name, fallback_icon_file_path));
		}
		else{
			img_icon = new Gtk.Image.from_pixbuf(pix_icon);
		}

		return img_icon; 
	}
}