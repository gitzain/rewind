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

public class SideBar : Granite.Widgets.SourceList 
{
    public SideBar () 
    {
        // Set properties
        width_request = 150;
    }

    public void create_and_add_item(string name, string icon, string badgeText)
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
        
        // Add the item to the root node 
        root.add (newItem);
    }

    public void add_expandable_item(SideBarExpandableItem newExpandableItem)
    {
        // Add the new expandable item to the root node 
        root.add (newExpandableItem);
    }

    public void create_and_add_expandable_item(string name, bool expanded)
    {
        // Create the new expandable item based on the parameters
        SideBarExpandableItem newExpandableItem = new SideBarExpandableItem(name);
        newExpandableItem.expanded = expanded;

        // Add the new expandable item to the root node 
        root.add (newExpandableItem);
    }

    public void delete_all_items()
    {
        root = new Granite.Widgets.SourceList.ExpandableItem();
    }
}
