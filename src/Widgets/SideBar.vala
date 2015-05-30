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

public class SideBar : Granite.Widgets.SourceList 
{
    SideBarExpandableItem newExpandableItem;


    public SideBar () 
    {
        // Set properties
        width_request = 150;
        refresh_items();
        root.add(newExpandableItem);
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
}
