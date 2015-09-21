/*
 * DriveList.vala
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

public class DriveList : Gtk.ListBox {
    private int item_count;

    public signal void item_changed (DriveItem item);
    public signal void list_loaded (int length);

    public DriveItem selected_row;

    private ArrayList<string> drives;

    public DriveList () {
        Gdk.RGBA color = new Gdk.RGBA();
        color.red = 0.8;
        color.green = 0.8;
        color.blue = 0.8;
        color.alpha = 0.5;
        override_background_color(Gtk.StateFlags.NORMAL, color);

        this.selection_mode = Gtk.SelectionMode.SINGLE;
        this.row_selected.connect ((row) => {
            if (row != null) {
                selected_row = row as DriveItem;
                item_changed (row as DriveItem);
            }
        });

        drives = new ArrayList<string>();

        list_drives ();

        item_changed.connect(sidebar_backup_device_changed);  
    }

    public void list_drives() 
    {
        foreach(Device pi in App.partition_list) 
        {
            if (!pi.has_linux_filesystem()) { continue; }

            var name = "";

            if (pi.label == "")
                name = pi.short_name_with_alias;
            else
                name = pi.label;


            var item = new DriveItem(pi.uuid, name, "path", pi.free + " free");

            if (!drives.contains(pi.uuid))
            {
                drives.add(pi.uuid);
                this.add(item);
                item_count += 1;
            }
        }

        list_loaded(item_count);
    }

    public void select_first () {
        if (item_count > 0) {
            var first_row = this.get_row_at_index (0);

            this.select_row (first_row);
            selected_row = first_row as DriveItem;
        }
    }

    public void select_none () {
        this.select_row (null);
    }

    private void sidebar_backup_device_changed(){
        if (selected_row.get_name() == null) { return; }
        
        // string txt;
        // if (selected == null) { 
        //  txt = "<b>" + _("WARNING:") + "</b>\n";
        //  txt += "Ø " + _("Please select a device for saving snapshots.") + "\n";
        //  txt = "<span foreground=\"#8A0808\">" + txt + "</span>";
        //  // set infobar text here
        //  App.snapshot_device = null;
        //  return; 
        // }

        foreach(Device pi in App.partition_list) 
        {
            if (pi.uuid == selected_row.get_id())
            {
                change_backup_device(pi);
                return;
            }
        }
    }

    private void change_backup_device(Device pi){
        //return if device has not changed
        if ((App.snapshot_device != null) && (pi.uuid == App.snapshot_device.uuid)){ return; }

        gtk_set_busy(true, get_parent_windowy());
        
        Device previous_device = App.snapshot_device;
        App.snapshot_device = pi;
        
        //try mounting the device
        if (App.mount_backup_device(get_parent_windowy())){
            App.update_partition_list();
            gtk_set_busy(false, get_parent_windowy());
            //timer_backup_device_init = Timeout.add(100, init_backup_device);
        }
        else{
            gtk_set_busy(false, get_parent_windowy());
            App.snapshot_device = previous_device;
            list_drives();
            return;
        }
    }

    private Gtk.Window get_parent_windowy()
    {
        Gtk.Widget toplevel = get_toplevel();
        return (Gtk.Window*) toplevel;
    }
}