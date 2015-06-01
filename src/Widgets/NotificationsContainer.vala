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

public class NotificationsContainer : Gtk.Overlay
{
    private InfoBar infobar_scheduled_snapshots;
    private InfoBar infobar_last_snapshot;

    public NotificationsContainer()
    {

    }

    public void scheduled_snapshots_notification_on()
    {
        infobar_scheduled_snapshots = new InfoBar();
        infobar_scheduled_snapshots.show();
        infobar_scheduled_snapshots.add_button ("Fix", 1);
        infobar_scheduled_snapshots.add_button ("Ignore", 2);
        infobar_scheduled_snapshots.set_message_type(Gtk.MessageType.WARNING);
        Gtk.Label infobar_scheduled_snapshots_text = new Gtk.Label("Scheduled snapshots disabled.");
        infobar_scheduled_snapshots_text.show();
        infobar_scheduled_snapshots.get_content_area().add(infobar_scheduled_snapshots_text);
        add(infobar_scheduled_snapshots);
        infobar_scheduled_snapshots.show();
    }

    public void scheduled_snapshots_notification_off()
    {
        remove(infobar_scheduled_snapshots);   
    }

    public void last_snapshot_notification_on(string days_old)
    {
        infobar_last_snapshot = new InfoBar();
        infobar_last_snapshot.show();
        infobar_last_snapshot.add_button ("Take Snapshot Now", 1);
        infobar_last_snapshot.add_button ("Ignore", 2);
        infobar_last_snapshot.set_message_type(Gtk.MessageType.QUESTION);
        Gtk.Label infobar_last_snapshot_text = new Gtk.Label("Last snapshot is" + days_old + "days old.");
        infobar_last_snapshot_text.show();
        infobar_last_snapshot.get_content_area().add(infobar_last_snapshot_text);
        add_overlay(infobar_last_snapshot);
    }

    public void last_snapshot_notification_off()
    {
        remove(infobar_last_snapshot);   
    }

}
