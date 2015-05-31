/*
 * NotificationBar.vala
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

public class NotificationBar : InfoBar
{
    Gtk.Label currentNotification;

    public NotificationBar(string text)
    {
        set_message_type(Gtk.MessageType.WARNING);
        set_show_close_button(true);

        add_button ("Yes", 1);
        add_button ("No", 2);

        currentNotification = new Gtk.Label (text);

        Gtk.Container content = get_content_area();
        content.add (currentNotification);
    }

    public void change_notification(string text, Gtk.MessageType message_type)
    {
        currentNotification.label = text;
        set_message_type(message_type);
    }

}
