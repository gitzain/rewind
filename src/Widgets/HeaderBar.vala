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
    private ToolButton btn_backup;
    private Gtk.ToolButton btn_scheduled_backup;
    private Granite.Widgets.AppMenu appmenu;

    public HeaderBar()
    {
        //set properties
        set_title(AppName);
        set_show_close_button (true);

        //btn_backup
        btn_backup = new Gtk.ToolButton.from_stock ("gtk-missing-image");
        btn_backup.is_important = true;
        btn_backup.set_tooltip_text (_("Take a manual (ondemand) snapshot"));
        btn_backup.icon_widget = get_shared_icon("document-new","document-new.svg",24);
        add(btn_backup);
        btn_backup.clicked.connect (btn_backup_clicked);

        //btn_scheduled_backup
        btn_scheduled_backup = new Gtk.ToolButton.from_stock ("gtk-missing-image");
        btn_scheduled_backup.is_important = true;
        btn_scheduled_backup.set_tooltip_text (_("Schedule Snapshots"));
        btn_scheduled_backup.icon_widget = get_shared_icon("office-calendar","office-calendar.svg",24);
        add(btn_scheduled_backup);

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
            btn_backup.sensitive = false;
        }
    }

    public void btn_backup_clicked()
    {
        
        //check root device --------------
        
        if (App.check_btrfs_root_layout() == false){
            return;
        }
        
        //check snapshot device -----------
        
        string msg;
        int status_code = App.check_backup_device(out msg);
        
        switch(status_code){
            case -1:
                //check_backup_device_online();
                return;
            case 1:
            case 2:
                gtk_messagebox(_("Low Disk Space"),_("Backup device does not have enough space"),null, true);
                //update_statusbar();
                return;
        }

        //update UI ------------------
        
        //update_ui(false);

        //statusbar_message(_("Taking snapshot..."));
        
        //update_progress_start();
        
        //take snapshot ----------------
        
        bool is_success = App.take_snapshot(true,"",get_window_parent()); 

        //update_progress_stop();
        
        if (is_success){
            //statusbar_message_with_timeout(_("Snapshot saved successfully"), true);
        }
        else{
            //statusbar_message_with_timeout(_("Error: Unable to save snapshot"), false);
        }
        
        //update UI -------------------
        
        App.update_partition_list();
        //sidebar.refresh_items();
        //refresh_tv_backups();
        //update_statusbar();
        
        //update_ui(true);
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