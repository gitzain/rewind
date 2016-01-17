/*
 * FileSystem.vala
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

namespace TeeJee.FileSystem{
	
	/* Convenience functions for handling files and directories */
	
	using TeeJee.Logging;
	using TeeJee.FileSystem;
	using TeeJee.ProcessManagement;
	using TeeJee.Misc;
	
	public void file_delete(string filePath){
		
		/* Check and delete file */
		
		try {
			var file = File.new_for_path (filePath);
			if (file.query_exists ()) { 
				file.delete (); 
			}
		} catch (Error e) {
	        log_error (e.message);
	    }
	}
	
	public bool file_exists (string filePath){
		/* Check if file exists */
		return ( FileUtils.test(filePath, GLib.FileTest.EXISTS) && FileUtils.test(filePath, GLib.FileTest.IS_REGULAR));
	}
	
	public bool device_exists (string filePath){
		/* Check if device exists */
		return (FileUtils.test(filePath, GLib.FileTest.EXISTS));
	}
	
	public void file_copy (string src_file, string dest_file){
		try{
			var file_src = File.new_for_path (src_file);
			if (file_src.query_exists()) { 
				var file_dest = File.new_for_path (dest_file);
				file_src.copy(file_dest,FileCopyFlags.OVERWRITE,null,null);
			}
		}
		catch(Error e){
	        log_error (e.message);
		}
	}
	
	public bool dir_exists (string filePath){
		
		/* Check if directory exists */
		
		return ( FileUtils.test(filePath, GLib.FileTest.EXISTS) && FileUtils.test(filePath, GLib.FileTest.IS_DIR));
	}
	
	public bool create_dir (string filePath){
		
		/* Creates a directory along with parents */
		
		try{
			var dir = File.parse_name (filePath);
			if (dir.query_exists () == false) {
				dir.make_directory_with_parents (null);
			}
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}

	public bool check_and_create_dir_with_parents (string filePath){
		
		/* Creates a directory along with parents */
		
		try{
			var dir = File.parse_name (filePath);
			if (dir.query_exists () == false) {
				dir.make_directory_with_parents (null);
			}
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public bool move_file (string sourcePath, string destPath){
		
		/* Move file from one location to another */
		
		try{
			File fromFile = File.new_for_path (sourcePath);
			File toFile = File.new_for_path (destPath);
			fromFile.move (toFile, FileCopyFlags.NONE);
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public bool copy_file (string sourcePath, string destPath){
		
		/* Copy file from one location to another */
		
		try{
			File fromFile = File.new_for_path (sourcePath);
			File toFile = File.new_for_path (destPath);
			fromFile.copy (toFile, FileCopyFlags.NONE);
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public string? read_file (string file_path){
		
		/* Reads text from file */
		
		string txt;
		size_t size;
		
		try{
			GLib.FileUtils.get_contents (file_path, out txt, out size);
			return txt;	
		}
		catch (Error e){
	        log_error (e.message);
	    }
	    
	    return null;
	}
	
	public bool write_file (string file_path, string contents){
		
		/* Write text to file */
		
		try{
			var file = File.new_for_path (file_path);
			if (file.query_exists ()) { file.delete (); }
			var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
			var data_stream = new DataOutputStream (file_stream);
			data_stream.put_string (contents);
			data_stream.close();
			return true;
		}
		catch (Error e) {
	        log_error (e.message);
	        return false;
	    } 
	}
	
	public long get_file_count(string path){
				
		/* Return total count of files and directories */
		
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;
		
		cmd = "find \"%s\" | wc -l".printf(path);
		ret_val = execute_command_script_sync(cmd, out std_out, out std_err);
		return long.parse(std_out);
	}

	public long get_file_size(string path){
				
		/* Returns size of files and directories in KB*/
		
		string cmd = "";
		string output = "";
		
		cmd = "du -s \"%s\"".printf(path);
		output = execute_command_sync_get_output(cmd);
		return long.parse(output.split("\t")[0]);
	}

	public string get_file_size_formatted(string path){
				
		/* Returns size of files and directories in KB*/
		
		string cmd = "";
		string output = "";
		
		cmd = "du -s -h \"%s\"".printf(path);
		output = execute_command_sync_get_output(cmd);
		return output.split("\t")[0].strip();
	}
	
	public int chmod (string file, string permission){
				
		/* Change file permissions */
		
		return execute_command_sync ("chmod " + permission + " \"%s\"".printf(file));
	}
	
	public string resolve_relative_path (string filePath){
				
		/* Resolve the full path of given file using 'realpath' command */
		
		string filePath2 = filePath;
		if (filePath2.has_prefix ("~")){
			filePath2 = Environment.get_home_dir () + "/" + filePath2[2:filePath2.length];
		}
		
		try {
			string output = "";
			Process.spawn_command_line_sync("realpath \"%s\"".printf(filePath2), out output);
			output = output.strip ();
			if (FileUtils.test(output, GLib.FileTest.EXISTS)){
				return output;
			}
		}
		catch(Error e){
	        log_error (e.message);
	    }
	    
	    return filePath2;
	}
	
	public int rsync (string sourceDirectory, string destDirectory, bool updateExisting, bool deleteExtra){
				
		/* Sync files with rsync */
		
		string cmd = "rsync --recursive --perms --chmod=a=rwx";
		cmd += updateExisting ? "" : " --ignore-existing";
		cmd += deleteExtra ? " --delete" : "";
		cmd += " \"%s\"".printf(sourceDirectory + "//");
		cmd += " \"%s\"".printf(destDirectory);
		return execute_command_sync (cmd);
	}
}