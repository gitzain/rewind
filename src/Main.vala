/*
 * Main.vala
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

using GLib;
using Gtk;
using Gee;
using Json;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.Devices;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

 	//initialization

	public static int main (string[] args) {
		set_locale();

		//show help and exit
		if (args.length > 1) {
			switch (args[1].down()) {
				case "--help":
				case "-h":
					stdout.printf (Main.help_message ());
					return 0;
			}
		}
		
		//init TMP
		LOG_ENABLE = false;
		init_tmp();
		LOG_ENABLE = true;
		
		/*
		 * Note:
		 * init_tmp() will fail if timeshift is run as normal user
		 * logging will be disabled temporarily so that the error is not displayed to user
		 */
		
		/*
		var map = Device.get_mounted_filesystems_using_mtab();
		foreach(Device pi in map.values){
			log_msg(pi.description_full());
		}
		exit(0);
		*/
		
		LOG_TIMESTAMP = true;
				
		App = new Main(args);

		bool success = App.start_application(args);
		App.exit_app();
		
		return (success) ? 0 : 1;
	}
	
	private static void set_locale(){
		Intl.setlocale(GLib.LocaleCategory.MESSAGES, "timeshift");
		Intl.textdomain(GETTEXT_PACKAGE);
		Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
		Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALE_DIR);
	}