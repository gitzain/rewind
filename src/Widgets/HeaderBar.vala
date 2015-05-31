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
    private ToolButton btn_settings;
    private ToolButton btn_view_app_logs;

    public HeaderBar()
    {
        //btn_settings
        btn_settings = new Gtk.ToolButton.from_stock ("gtk-missing-image");
        btn_settings.is_important = true;
        btn_settings.set_tooltip_text (_("Settings"));
        btn_settings.icon_widget = get_shared_icon("settings","settings.svg",24);
        pack_end(btn_settings);
        btn_settings.clicked.connect (btn_settings_clicked);
        
        //btn_view_app_logs
        btn_view_app_logs = new Gtk.ToolButton.from_stock ("gtk-file");
        btn_view_app_logs.label = _("TimeShift Logs");
        btn_view_app_logs.set_tooltip_text (_("View TimeShift Logs"));
        add(btn_view_app_logs);
        btn_view_app_logs.clicked.connect (btn_view_app_logs_clicked);

        if (App.live_system()){
            btn_settings.sensitive = false;
            btn_view_app_logs.sensitive = false;
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