/*
 * System.vala
 * 
 * Copyright 2012 Tony George <teejee2008@gmail.com>
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

namespace TeeJee.System{
	
	using TeeJee.ProcessManagement;
	using TeeJee.Logging;

	public double get_system_uptime_seconds(){
				
		/* Returns the system up-time in seconds */
		
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;
		
		try{
			cmd = "cat /proc/uptime";
			Process.spawn_command_line_sync(cmd, out std_out, out std_err, out ret_val);
			string uptime = std_out.split(" ")[0];
			double secs = double.parse(uptime);
			return secs;
		}
		catch(Error e){
			log_error (e.message);
			return 0;
		}
	}
	
	public string get_desktop_name(){
				
		/* Return the names of the current Desktop environment */
		
		int pid = -1;
		
		pid = get_pid_by_name("cinnamon");
		if (pid > 0){
			return "Cinnamon";
		}
		
		pid = get_pid_by_name("xfdesktop");
		if (pid > 0){
			return "Xfce";
		}

		pid = get_pid_by_name("lxsession");
		if (pid > 0){
			return "LXDE";
		}

		pid = get_pid_by_name("gnome-shell");
		if (pid > 0){
			return "Gnome";
		}
		
		pid = get_pid_by_name("wingpanel");
		if (pid > 0){
			return "Elementary";
		}
		
		pid = get_pid_by_name("unity-panel-service");
		if (pid > 0){
			return "Unity";
		}

		pid = get_pid_by_name("plasma-desktop");
		if (pid > 0){
			return "KDE";
		}
		
		return "Unknown";
	}

	public bool check_internet_connectivity(){
		int exit_code = -1;
		string std_err;
		string std_out;

		try {
			string cmd = "ping -c 1 google.com";
			Process.spawn_command_line_sync(cmd, out std_out, out std_err, out exit_code);
		}
		catch (Error e){
	        log_error (e.message);
	    }
		
	    return (exit_code == 0);
	}
	
	public bool shutdown (){
				
		/* Shutdown the system immediately */
		
		try{
			string[] argv = { "shutdown", "-h", "now" };
			Pid procId;
			Process.spawn_async(null, argv, null, SpawnFlags.SEARCH_PATH, null, out procId); 
			return true;
		} 
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public bool reboot(){
				
		/* Reboot the system immediately */

		try{
			string[] argv = { "shutdown", "-r", "now" };
			Pid procId;
			Process.spawn_async(null, argv, null, SpawnFlags.SEARCH_PATH, null, out procId); 
			return true;
		} 
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public bool xdg_open (string file){
		string path;
		path = get_cmd_path ("xdg-open");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("xdg-open \"" + file + "\"");
		}
		return false;
	}
	
	public bool exo_open_folder (string dir_path, bool xdg_open_try_first = true){
				
		/* Tries to open the given directory in a file manager */

		/*
		xdg-open is a desktop-independent tool for configuring the default applications of a user.
		Inside a desktop environment (e.g. GNOME, KDE, Xfce), xdg-open simply passes the arguments 
		to that desktop environment's file-opener application (gvfs-open, kde-open, exo-open, respectively).
		We will first try using xdg-open and then check for specific file managers if it fails. 
		*/
		
		string path;
		
		if (xdg_open_try_first){
			//try using xdg-open
			path = get_cmd_path ("xdg-open");
			if ((path != null)&&(path != "")){
				return execute_command_script_async ("xdg-open \"" + dir_path + "\"");
			}
		}
		
		path = get_cmd_path ("nemo");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("nemo \"" + dir_path + "\"");
		}
		
		path = get_cmd_path ("nautilus");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("nautilus \"" + dir_path + "\"");
		}
		
		path = get_cmd_path ("thunar");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("thunar \"" + dir_path + "\"");
		}

		path = get_cmd_path ("pantheon-files");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("pantheon-files \"" + dir_path + "\"");
		}
		
		path = get_cmd_path ("marlin");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("marlin \"" + dir_path + "\"");
		}

		if (xdg_open_try_first == false){
			//try using xdg-open
			path = get_cmd_path ("xdg-open");
			if ((path != null)&&(path != "")){
				return execute_command_script_async ("xdg-open \"" + dir_path + "\"");
			}
		}
		
		return false;
	}

	public bool exo_open_textfile (string txt){
				
		/* Tries to open the given text file in a text editor */
		
		string path;
		
		path = get_cmd_path ("exo-open");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("exo-open \"" + txt + "\"");
		}

		path = get_cmd_path ("gedit");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("gedit --new-document \"" + txt + "\"");
		}

		return false;
	}

	public bool exo_open_url (string url){
				
		/* Tries to open the given text file in a text editor */
		
		string path;
		
		path = get_cmd_path ("exo-open");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("exo-open \"" + url + "\"");
		}

		path = get_cmd_path ("firefox");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("firefox \"" + url + "\"");
		}

		path = get_cmd_path ("chromium-browser");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("chromium-browser \"" + url + "\"");
		}
		
		return false;
	}
	
	private DateTime dt_last_notification = null;
	private const int NOTIFICATION_INTERVAL = 3;
	
	public int notify_send (string title, string message, int durationMillis, string urgency, string dialog_type = "info"){
				
		/* Displays notification bubble on the desktop */

		int retVal = 0;
		
		switch (dialog_type){
			case "error":
			case "info":
			case "warning":
				//ok
				break;
			default:
				dialog_type = "info";
				break;
		}
		
		long seconds = 9999;
		if (dt_last_notification != null){
			DateTime dt_end = new DateTime.now_local();
			TimeSpan elapsed = dt_end.difference(dt_last_notification);
			seconds = (long)(elapsed * 1.0 / TimeSpan.SECOND);
		}
	
		if (seconds > NOTIFICATION_INTERVAL){
			string s = "notify-send -t %d -u %s -i %s \"%s\" \"%s\"".printf(durationMillis, urgency, "gtk-dialog-" + dialog_type, title, message);
			retVal = execute_command_sync (s);
			dt_last_notification = new DateTime.now_local();
		}

		return retVal;
	}
	
	public bool set_directory_ownership(string dir_name, string login_name){
		try {
			string cmd = "chown %s -R %s".printf(login_name, dir_name);
			int exit_code;
			Process.spawn_command_line_sync(cmd, null, null, out exit_code);
			
			if (exit_code == 0){
				//log_msg(_("Ownership changed to '%s' for files in directory '%s'").printf(login_name, dir_name));
				return true;
			}
			else{
				log_error(_("Failed to set ownership") + ": %s, %s".printf(login_name, dir_name));
				return false;
			}
		}
		catch (Error e){
			log_error (e.message);
			return false;
		}
	}
	
	public bool crontab_remove(string line){
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;
		
		cmd = "crontab -l | sed '/%s/d' | crontab -".printf(line);
		ret_val = execute_command_script_sync(cmd, out std_out, out std_err);
		
		if (ret_val != 0){
			log_error(std_err);
			return false;
		}
		else{
			return true;
		}
	}
	
	public bool crontab_add(string entry){
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;
		
		try{
			string crontab = crontab_read_all();
			crontab += crontab.has_suffix("\n") ? "" : "\n";
			crontab += entry + "\n";
			
			//remove empty lines
			crontab = crontab.replace("\n\n","\n"); //remove empty lines in middle
			crontab = crontab.has_prefix("\n") ? crontab[1:crontab.length] : crontab; //remove empty lines in beginning
			
			string temp_file = get_temp_file_path();
			write_file(temp_file, crontab);

			cmd = "crontab \"%s\"".printf(temp_file);
			Process.spawn_command_line_sync(cmd, out std_out, out std_err, out ret_val);
			
			if (ret_val != 0){
				log_error(std_err);
				return false;
			}
			else{
				return true;
			}
		}
		catch(Error e){
			log_error (e.message);
			return false;
		}
	}

	public string crontab_read_all(){
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;
		
		try {
			cmd = "crontab -l";
			Process.spawn_command_line_sync(cmd, out std_out, out std_err, out ret_val);
			if (ret_val != 0){
				log_debug(_("Crontab is empty"));
				return "";
			}
			else{
				return std_out;
			}
		}
		catch (Error e){
			log_error (e.message);
			return "";
		}
	}
	
	public string crontab_read_entry(string search_string, bool use_regex_matching = false){
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;
		
		try{
			Regex rex = null;
			MatchInfo match;
			if (use_regex_matching){
				rex = new Regex(search_string);
			}

			cmd = "crontab -l";
			Process.spawn_command_line_sync(cmd, out std_out, out std_err, out ret_val);
			if (ret_val != 0){
				log_debug(_("Crontab is empty"));
			}
			else{
				foreach(string line in std_out.split("\n")){
					if (use_regex_matching && (rex != null)){
						if (rex.match (line, 0, out match)){
							return line.strip();
						}
					}
					else {
						if (line.contains(search_string)){
							return line.strip();
						}
					}
				}
			}

			return "";
		}
		catch(Error e){
			log_error (e.message);
			return "";
		}
	}
}