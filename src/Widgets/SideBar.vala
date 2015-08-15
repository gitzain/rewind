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
using Gdk;
using Gee;

using TeeJee.Devices;

using TeeJee.GtkHelper;

public class SideBar : Gtk.Box 
{
    public DriveList drive_list = new DriveList();
    private Gtk.ScrolledWindow scrolled_window = new Gtk.ScrolledWindow(null, null);

    public SideBar () 
    {
        scrolled_window.add(drive_list);
        pack_start (scrolled_window, true, true);
        //pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true);
    }

    public void refresh_items()
    {
        drive_list.list_drives();
    }
}