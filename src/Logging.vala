/*
 * Logging.vala
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

namespace TeeJee.Logging{
	
	/* Functions for logging messages to console and log files */

	using TeeJee.Misc;

	public DataOutputStream dos_log;
	
	public bool LOG_ENABLE = true;
	public bool LOG_TIMESTAMP = true;
	public bool LOG_COLORS = true;
	public bool LOG_DEBUG = false;
	public bool LOG_COMMANDS = false;
	
	public const string TERM_COLOR_YELLOW = "\033[" + "1;33" + "m";
	public const string TERM_COLOR_GREEN = "\033[" + "1;32" + "m";
	public const string TERM_COLOR_RED = "\033[" + "1;31" + "m";
	public const string TERM_COLOR_RESET = "\033[" + "0" + "m";

	public void log_msg (string message, bool highlight = false){

		if (!LOG_ENABLE) { return; }
		
		string msg = "";
		
		if (highlight && LOG_COLORS){
			msg += "\033[1;38;5;34m";
		}
		
		if (LOG_TIMESTAMP){
			msg += "[" + timestamp() +  "] ";
		}
		
		msg += message;
		
		if (highlight && LOG_COLORS){
			msg += "\033[0m";
		}
		
		msg += "\n";
		
		stdout.printf (msg);

		try {
			if (dos_log != null){
				dos_log.put_string ("[%s] %s\n".printf(timestamp(), message));
			}
		} 
		catch (Error e) {
			stdout.printf (e.message);
		}
	}
	
	public void log_msg_to_file (string message, bool highlight = false){
		try {
			if (dos_log != null){
				dos_log.put_string ("[%s] %s\n".printf(timestamp(), message));
			}
		} 
		catch (Error e) {
			stdout.printf (e.message);
		}
	}
	
	public void log_error (string message, bool highlight = true, bool is_warning = false){
		if (!LOG_ENABLE) { return; }
		
		string msg = "";
		
		if (highlight && LOG_COLORS){
			msg += "\033[1;38;5;9m";
		}
		
		if (LOG_TIMESTAMP){
			msg += "[" + timestamp() +  "] ";
		}
		
		string prefix = (is_warning) ? _("Warning") : _("Error");
		
		msg += prefix + ": " + message;
		
		if (highlight && LOG_COLORS){
			msg += "\033[0m";
		}
		
		msg += "\n";
		
		stdout.printf (msg);
		
		try {
			if (dos_log != null){
				dos_log.put_string ("[%s] %s: %s\n".printf(timestamp(), prefix, message));
			}
		} 
		catch (Error e) {
			stdout.printf (e.message);
		}
	}

	public void log_debug (string message){
		if (!LOG_ENABLE) { return; }
			
		if (LOG_DEBUG){
			//display output and write to log
			log_msg (message);
		}
		else{
			//write to log only
			try {
				if (dos_log != null){
					dos_log.put_string ("[%s] %s\n".printf(timestamp(), message));
				}
			} 
			catch (Error e) {
				stdout.printf (e.message);
			}
		}
	}
	
	public void log_empty_line(){
		if (!LOG_ENABLE) { return; }
			
		stdout.printf ("\n");
		stdout.flush();

		try {
			if (dos_log != null){
				dos_log.put_string ("\n");
			}
		} 
		catch (Error e) {
			stdout.printf (e.message);
		}
	}
}
