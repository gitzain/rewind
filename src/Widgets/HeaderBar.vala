/*
 * HeaderBar.vala
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

using TeeJee.Devices;


using TeeJee.GtkHelper;

using TeeJee.System;



public class HeaderBar : Gtk.HeaderBar
{
    private Granite.Widgets.AppMenu appmenu;

    public HeaderBar()
    {
        //set properties
        set_title(AppName);
        set_show_close_button (true);

        //appmenu
        Gtk.Menu menu = new Gtk.Menu();
        appmenu = new Granite.Widgets.AppMenu(menu);
        //view app logs button
        Gtk.MenuItem menu_item_log = new Gtk.MenuItem.with_label("View App Logs");
        menu_item_log.activate.connect (btn_view_app_logs_clicked);
        menu.append(menu_item_log);
        //seperator
        Gtk.SeparatorMenuItem seperator = new Gtk.SeparatorMenuItem();
        menu.append(seperator);
        //settings button
        Gtk.MenuItem menu_item_settings = new Gtk.MenuItem.with_label("Settings");
        menu_item_settings.activate.connect (btn_settings_clicked);
        menu.append(menu_item_settings);
        pack_end(appmenu);

        if (App.live_system()){
            appmenu.sensitive = false;
        }
    }
    
    private void btn_view_app_logs_clicked(){
        exo_open_folder(App.log_dir);
    }

    private void btn_settings_clicked(){
        var dialog = new SettingsWindow();
        dialog.set_transient_for (get_window_parent());
        dialog.response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
                dialog.hide_on_delete ();
            }
        });
        
        dialog.show_all();
        dialog.run();
        //update_statusbar();
    }

    private Gtk.Window get_window_parent()
    {
        Gtk.Widget toplevel = get_toplevel();
        return (Gtk.Window*) toplevel;

    }
    
}