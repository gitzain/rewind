/*
 * NotificationsContainer.vala
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

public class NotificationsContainer : Gtk.Box
{
    private Gtk.Revealer revealer;
    private NotificationBar notification1;
    private NotificationBar notification2;
    private NotificationBar notification3;

    public NotificationsContainer()
    {
        orientation = Orientation.VERTICAL;


        notification1 = new NotificationBar("1");
        notification1.change_notification_type(Gtk.MessageType.WARNING);
        add(notification1);

        notification2 = new NotificationBar("2");
        notification2.change_notification_type(Gtk.MessageType.INFO);
        add(notification2);

        revealer = new Gtk.Revealer();
        revealer.transition_type = RevealerTransitionType.CROSSFADE;
        revealer.set_transition_duration(5000);
        revealer.set_reveal_child(true);
        revealer.add(notification3);
        add(revealer);


    }

}
