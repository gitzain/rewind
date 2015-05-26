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
using TeeJee.GtkHelper;



public class SideBar : Granite.Widgets.SourceList {

    public SideBarExpandableItem genre_list_item;
    public Granite.Widgets.SourceList.Item all_stations_item;

    private HashMap <int,Granite.Widgets.SourceList.Item> genre_list_items;

    public SideBar () {
        build_interface ();
    }

    private void build_interface () {
        set_properties ();
        create_items ();
        append_items ();
    }

    private void set_properties () {
        width_request = 150;
    }

    private void create_items () {
        genre_list_items = new HashMap <int,Granite.Widgets.SourceList.Item> ();

        genre_list_item = new SideBarExpandableItem ("Backup To:");
        genre_list_item.expanded = true;

        Granite.Widgets.SourceList.Item item = new Granite.Widgets.SourceList.Item ("Test");
        item.badge = "10GB";
        string path = "/usr/share/timeshift/images/%s.%s";
        item.icon =  new GLib.FileIcon (GLib.File.new_for_path (path.printf ("disk", "png")));

        genre_list_item.add (item);
        genre_list_items[1] = item;

    }

    private void append_items () {
        root.add (all_stations_item);
        root.add (genre_list_item);
    }







}
