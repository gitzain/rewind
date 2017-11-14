/*
 * Misc.vala
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

public class Size 
{
	public static const double KB = 1000;
	public static const double MB = 1000 * 1000;
	public static const double GB = 1000 * 1000 * 1000;

	public static const double KiB = 1024;
	public static const double MiB = 1024 * 1024;
	public static const double GiB = 1024 * 1024 * 1024;
}

namespace TeeJee.Misc {
	
	/* Various utility functions */
	
	using Gtk;
	using TeeJee.Logging;
	using TeeJee.FileSystem;
	using TeeJee.ProcessManagement;
	
	public class DistInfo : GLib.Object{
				
		/* Class for storing information about linux distribution */
		
		public string dist_id = "";
		public string description = "";
		public string release = "";
		public string codename = "";
		
		public DistInfo(){
			dist_id = "";
			description = "";
			release = "";
			codename = "";
		}
		
		public string full_name(){
			if (dist_id == ""){
				return "";
			}
			else{
				string val = "";
				val += dist_id;
				val += (release.length > 0) ? " " + release : "";
				val += (codename.length > 0) ? " (" + codename + ")" : "";
				return val;
			}
		}
		
		public static DistInfo get_dist_info(string root_path){
				
			/* Returns information about the Linux distribution 
			 * installed at the given root path */
		
			DistInfo info = new DistInfo();
			
			string dist_file = root_path + "/etc/lsb-release";
			var f = File.new_for_path(dist_file);
			if (f.query_exists()){

				/*
					DISTRIB_ID=Ubuntu
					DISTRIB_RELEASE=13.04
					DISTRIB_CODENAME=raring
					DISTRIB_DESCRIPTION="Ubuntu 13.04"
				*/
				
				foreach(string line in read_file(dist_file).split("\n")){
					
					if (line.split("=").length != 2){ continue; }
					
					string key = line.split("=")[0].strip();
					string val = line.split("=")[1].strip();
					
					if (val.has_prefix("\"")){
						val = val[1:val.length];
					}
					
					if (val.has_suffix("\"")){
						val = val[0:val.length-1];
					}
					
					switch (key){
						case "DISTRIB_ID":
							info.dist_id = val;
							break;
						case "DISTRIB_RELEASE":
							info.release = val;
							break;
						case "DISTRIB_CODENAME":
							info.codename = val;
							break;
						case "DISTRIB_DESCRIPTION":
							info.description = val;
							break;
					}
				}
			}
			else{
				
				dist_file = root_path + "/etc/os-release";
				f = File.new_for_path(dist_file);
				if (f.query_exists()){
					
					/*
						NAME="Ubuntu"
						VERSION="13.04, Raring Ringtail"
						ID=ubuntu
						ID_LIKE=debian
						PRETTY_NAME="Ubuntu 13.04"
						VERSION_ID="13.04"
						HOME_URL="http://www.ubuntu.com/"
						SUPPORT_URL="http://help.ubuntu.com/"
						BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
					*/
					
					foreach(string line in read_file(dist_file).split("\n")){
					
						if (line.split("=").length != 2){ continue; }
						
						string key = line.split("=")[0].strip();
						string val = line.split("=")[1].strip();
						
						switch (key){
							case "ID":
								info.dist_id = val;
								break;
							case "VERSION_ID":
								info.release = val;
								break;
							//case "DISTRIB_CODENAME":
								//info.codename = val;
								//break;
							case "PRETTY_NAME":
								info.description = val;
								break;
						}
					}
				}
			}

			return info;
		}
		
	}

	public static Gdk.RGBA hex_to_rgba (string hex_color){
				
		/* Converts the color in hex to RGBA */
		
		string hex = hex_color.strip().down();
		if (hex.has_prefix("#") == false){
			hex = "#" + hex;
		}
		
		Gdk.RGBA color = Gdk.RGBA();
		if(color.parse(hex) == false){
			color.parse("#000000");
		}
		color.alpha = 255;
		
		return color;
	}
	
	public static string rgba_to_hex (Gdk.RGBA color, bool alpha = false, bool prefix_hash = true){
				
		/* Converts the color in RGBA to hex */
		
		string hex = "";
		
		if (alpha){
			hex = "%02x%02x%02x%02x".printf((uint)(Math.round(color.red*255)),
									(uint)(Math.round(color.green*255)),
									(uint)(Math.round(color.blue*255)),
									(uint)(Math.round(color.alpha*255)))
									.up();
		}
		else {														
			hex = "%02x%02x%02x".printf((uint)(Math.round(color.red*255)),
									(uint)(Math.round(color.green*255)),
									(uint)(Math.round(color.blue*255)))
									.up();
		}	
		
		if (prefix_hash){
			hex = "#" + hex;
		}	
		
		return hex;													
	}

	public string timestamp2 (){
				
		/* Returns a numeric timestamp string */
		
		return "%ld".printf((long) time_t ());
	}
	
	public string timestamp (){	
			
		/* Returns a formatted timestamp string */
		
		Time t = Time.local (time_t ());
		return t.format ("%H:%M:%S");
	}

	public string timestamp3 (){	
			
		/* Returns a formatted timestamp string */
		
		Time t = Time.local (time_t ());
		return t.format ("%Y-%d-%m_%H-%M-%S");
	}
	
	public string format_file_size (int64 size){
				
		/* Format file size in MB */
		
		return "%0.1f MB".printf (size / (1024.0 * 1024));
	}

	public string format_file_size_auto (int64 size, bool binary_base = false){
				
		/* Format file size in human readable format */
		
		if (binary_base){
			if (size > 1 * Size.GiB){
				return "%0.1f GiB".printf (size / Size.GiB);
			}
			else if (size > 1 * Size.MiB){
				return "%0.0f MiB".printf (size / Size.MiB);
			}
			else if (size > 1 * Size.KiB){
				return "%0.0f KiB".printf (size / Size.KiB);
			}
			else{
				return "%0.0f B".printf (size);
			}
		}
		else{
			if (size > 1 * Size.GB){
				return "%0.1f GB".printf (size / Size.GB);
			}
			else if (size > 1 * Size.MB){
				return "%0.0f MB".printf (size / Size.MB);
			}
			else if (size > 1 * Size.KB){
				return "%0.0f KB".printf (size / Size.KB);
			}
			else{
				return "%0.0f B".printf (size);
			}
		}
	}
	
	public string format_duration (long millis){
				
		/* Converts time in milliseconds to format '00:00:00.0' */
		
	    double time = millis / 1000.0; // time in seconds

	    double hr = Math.floor(time / (60.0 * 60));
	    time = time - (hr * 60 * 60);
	    double min = Math.floor(time / 60.0);
	    time = time - (min * 60);
	    double sec = Math.floor(time);
	    
        return "%02.0lf:%02.0lf:%02.0lf".printf (hr, min, sec);
	}
	
	public double parse_time (string time){
				
		/* Converts time in format '00:00:00.0' to milliseconds */
		
		string[] arr = time.split (":");
		double millis = 0;
		if (arr.length >= 3){
			millis += double.parse(arr[0]) * 60 * 60;
			millis += double.parse(arr[1]) * 60;
			millis += double.parse(arr[2]);
		}
		return millis;
	}
	
	public string escape_html(string html){
		return html
		.replace("&","&amp;")
		.replace("\"","&quot;")
		//.replace(" ","&nbsp;") //pango markup throws an error with &nbsp;
		.replace("<","&lt;")
		.replace(">","&gt;")
		;
	}
	
	public string unescape_html(string html){
		return html
		.replace("&amp;","&")
		.replace("&quot;","\"")
		//.replace("&nbsp;"," ") //pango markup throws an error with &nbsp;
		.replace("&lt;","<")
		.replace("&gt;",">")
		;
	}
}

