/*
 * SideBar.vala
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

public class SideBar : Granite.Widgets.SourceList 
{
    SideBarExpandableItem newExpandableItem;


    public SideBar () 
    {
        // Set properties
        width_request = 150;
        refresh_items();
        root.add(newExpandableItem);
        item_selected.connect(sidebar_backup_device_changed);
    }

    public void refresh_items()
    {
        newExpandableItem = new SideBarExpandableItem("Backup To:");
        newExpandableItem.expanded = true;
        Granite.Widgets.SourceList.Item newItem;

        foreach(Device pi in App.partition_list) 
        {
            newItem = create_item(pi.name, "disk", "%s".printf((pi.size_mb > 0) ? "%s GB".printf(pi.size) : "?? GB"));
            newExpandableItem.add(newItem);
        }
    }

    private Granite.Widgets.SourceList.Item create_item(string name, string icon, string badgeText)
    {
        // Create the new item based on the parameters
        Granite.Widgets.SourceList.Item newItem = new Granite.Widgets.SourceList.Item (name);

        if (icon != null)
        {
            string path = "/usr/share/timeshift/images/%s.%s";
            newItem.icon =  new GLib.FileIcon (GLib.File.new_for_path (path.printf (icon, "png")));
        }

        if (badgeText != null)
        {
            newItem.badge = badgeText;
        }
        
        return newItem;
    }

    private void sidebar_backup_device_changed(){
        if (selected.name == null) { return; }
        
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
            if (pi.name == selected.name)
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
            refresh_items();
            return;
        }
    }

    private Gtk.Window get_parent_windowy()
    {
        Gtk.Widget toplevel = get_toplevel();
        return (Gtk.Window*) toplevel;

    }
}
