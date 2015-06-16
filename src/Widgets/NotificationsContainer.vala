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
    private InfoBar infobar_live_system;

    public NotificationsContainer()
    {
        infobar_scheduled_snapshots = new InfoBar();
        infobar_scheduled_snapshots.add_button ("Fix", 1);
        infobar_scheduled_snapshots.add_button ("Ignore", 2);
        infobar_scheduled_snapshots.set_message_type(Gtk.MessageType.WARNING);
        Gtk.Label infobar_scheduled_snapshots_text = new Gtk.Label("Scheduled snapshots disabled.");
        infobar_scheduled_snapshots_text.show();
        infobar_scheduled_snapshots.get_content_area().add(infobar_scheduled_snapshots_text);
        infobar_scheduled_snapshots.response.connect(infobar_scheduled_snapshots_handler);
        add(infobar_scheduled_snapshots);
        infobar_scheduled_snapshots.hide();

        infobar_last_snapshot = new InfoBar();
        infobar_last_snapshot.add_button ("Take Snapshot Now", 1);
        infobar_last_snapshot.add_button ("Ignore", 2);
        infobar_last_snapshot.set_message_type(Gtk.MessageType.QUESTION);
        Gtk.Label infobar_last_snapshot_text = new Gtk.Label("Last snapshot is s few days old.");
        infobar_last_snapshot_text.show();
        infobar_last_snapshot.get_content_area().add(infobar_last_snapshot_text);
        infobar_last_snapshot.response.connect(infobar_last_snapshot_button_handler);

        infobar_live_system = new InfoBar();
        infobar_live_system.add_button ("Dismiss", 1);
        infobar_live_system.set_message_type(Gtk.MessageType.QUESTION);
        Gtk.Label infobar_live_system_text = new Gtk.Label("Running from Live CD/USB. ");
        infobar_live_system.get_content_area().add(infobar_live_system_text);
        infobar_live_system.response.connect(infobar_live_system_handler);
    }

    public void scheduled_snapshots_notification_on()
    {
        infobar_scheduled_snapshots.show();
    }

    private void infobar_scheduled_snapshots_handler(int response_id)
    {
        switch(response_id)
        {
            case 2:
                scheduled_snapshots_notification_off();
                break;

            default:
                return;
        }
    }

    public void scheduled_snapshots_notification_off()
    {
          infobar_scheduled_snapshots.hide();
    }

    public void last_snapshot_notification_on(string days_old)
    {
        infobar_last_snapshot.show();
        add_overlay(infobar_last_snapshot);
    }

    private void infobar_last_snapshot_button_handler(int response_id)
    {
        switch(response_id)
        {
            case 2:
                last_snapshot_notification_off();
                break;

            default:
                return;
        }
    }

    public void last_snapshot_notification_off()
    {
        remove(infobar_last_snapshot);   
    }

    public void live_system_notification_on()
    {
        infobar_live_system.show();
        add_overlay(infobar_live_system);
    }

    private void infobar_live_system_handler(int response_id)
    {
        switch(response_id)
        {
            case 1:
                live_system_notification_off();
                break;

            default:
                return;
        }
    }

    public void live_system_notification_off()
    {
        remove(infobar_live_system);
    }
}
