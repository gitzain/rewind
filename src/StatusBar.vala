/*
 * Statusbar.vala
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

public class StatusBar : Gtk.ActionBar
{
	//private Gtk.Button icon;
	private Gtk.Label label;

	public StatusBar()
	{
		// create and add icon
		Gtk.Button icon = new Gtk.Button.from_icon_name ("dialog-question", Gtk.IconSize.MENU);
		add(icon);

		//create and add label
		label = new Gtk.Label("Ready. Take a snapshot or restore one.");
		add(label);
	}

	public void set_message(string text)
	{
		label.set_label(text);
	}

}