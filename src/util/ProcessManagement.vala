/*
 * ProcessManagement.vala
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

namespace TeeJee.ProcessManagement{
	using TeeJee.Logging;
	using TeeJee.FileSystem;
	using TeeJee.Misc;
	
	public string TEMP_DIR;

	/* Convenience functions for executing commands and managing processes */
	
    public static void init_tmp(){
		string std_out, std_err;
		
		TEMP_DIR = Environment.get_tmp_dir() + "/" + AppShortName;
		create_dir(TEMP_DIR);

		execute_command_script_sync("echo 'ok'",out std_out,out std_err);
		if ((std_out == null)||(std_out.strip() != "ok")){
			TEMP_DIR = Environment.get_home_dir() + "/.temp/" + AppShortName;
			execute_command_sync("rm -rf '%s'".printf(TEMP_DIR));
			create_dir(TEMP_DIR);
		}
	}

	public int execute_command_sync (string cmd){
		
		/* Executes single command synchronously and returns exit code 
		 * Pipes and multiple commands are not supported */
		
		try {
			int exitCode;
			Process.spawn_command_line_sync(cmd, null, null, out exitCode);
	        return exitCode;
		}
		catch (Error e){
	        log_error (e.message);
	        return -1;
	    }
	}
	
	public string execute_command_sync_get_output (string cmd){
				
		/* Executes single command synchronously and returns std_out
		 * Pipes and multiple commands are not supported */
		
		try {
			int exitCode;
			string std_out;
			Process.spawn_command_line_sync(cmd, out std_out, null, out exitCode);
	        return std_out;
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}

	public bool execute_command_script_async (string cmd){
				
		/* Creates a temporary bash script with given commands and executes it asynchronously 
		 * Return value indicates if script was started successfully */
		
		try {
			
			string scriptfile = create_temp_bash_script (cmd);
			
			string[] argv = new string[1];
			argv[0] = scriptfile;
			
			Pid child_pid;
			Process.spawn_async_with_pipes(
			    null, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null,
			    out child_pid);
			return true;
		}
		catch (Error e){
	        log_error (e.message);
	        return false;
	    }
	}
	
	public string? create_temp_bash_script (string script_text){
				
		/* Creates a temporary bash script with given commands 
		 * Returns the script file path */
		
		var sh = "";
		sh += "#!/bin/bash\n";
		sh += script_text;

		string script_path = get_temp_file_path() + ".sh";

		if (write_file (script_path, sh)){  // create file
			chmod (script_path, "u+x");      // set execute permission
			return script_path;
		}
		else{
			return null;
		}
	}
	
	public string get_temp_file_path(){
				
		/* Generates temporary file path */
		
		return TEMP_DIR + "/" + timestamp2() + (new Rand()).next_int().to_string();
	}
	
	public int execute_command_script_sync (string script, out string std_out, out string std_err){
				
		/* Executes commands synchronously
		 * Returns exit code, output messages and error messages.
		 * Commands are written to a temporary bash script and executed. */
		
		string path = create_temp_bash_script(script);

		try {
			
			string[] argv = new string[1];
			argv[0] = path;
		
			int exit_code;
			
			Process.spawn_sync (
			    TEMP_DIR, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null,   // child_setup
			    out std_out,
			    out std_err,
			    out exit_code
			    );
			    
			return exit_code;
		}
		catch (Error e){
	        log_error (e.message);
	        return -1;
	    }
	}

	public int execute_script_sync_get_output (string script, out string std_out, out string std_err){
				
		/* Executes commands synchronously
		 * Returns exit code, output messages and error messages.
		 * Commands are written to a temporary bash script and executed. */
		
		string path = create_temp_bash_script(script);

		try {
			
			string[] argv = new string[1];
			argv[0] = path;
		
			int exit_code;
			
			Process.spawn_sync (
			    TEMP_DIR, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null,   // child_setup
			    out std_out,
			    out std_err,
			    out exit_code
			    );
			    
			return exit_code;
		}
		catch (Error e){
	        log_error (e.message);
	        return -1;
	    }
	}
	
	public int execute_script_sync(string script, bool suppress_output){
				
		/* Executes commands synchronously
		 * Returns exit code, output messages and error messages.
		 * Commands are written to a temporary bash script and executed. */
		
		string path = create_temp_bash_script(script);

		try {
			
			string[] argv = new string[1];
			argv[0] = path;
		
			int exit_code;
			string std_out, std_err;
			
			if (suppress_output){
				//output will be suppressed
				Process.spawn_sync (
					TEMP_DIR, //working dir
					argv, //argv
					null, //environment
					SpawnFlags.SEARCH_PATH,
					null,        //child_setup
					out std_out, //stdout
					out std_err, //stderr
					out exit_code
					);
			}
			else{
				//output will be displayed on terminal window if visible
				Process.spawn_sync (
					TEMP_DIR, //working dir
					argv, //argv
					null, //environment
					SpawnFlags.SEARCH_PATH,
					null, //child_setup
					null, //stdout
					null, //stderr
					out exit_code
					);
			}

			return exit_code;
		}
		catch (Error e){
	        log_error (e.message);
	        return -1;
	    }
	}
	
	public bool execute_command_script_in_terminal_sync (string script){
				
		/* Executes a command script in a terminal window */
		//TODO: Remove this
		
		try {
			
			string[] argv = new string[3];
			argv[0] = "x-terminal-emulator";
			argv[1] = "-e";
			argv[2] = script;
		
			Process.spawn_sync (
			    TEMP_DIR, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null   // child_setup
			    );
			    
			return true;
		}
		catch (Error e){
	        log_error (e.message);
	        return false;
	    }
	}

	public int execute_bash_script_fullscreen_sync (string script_file){
			
		/* Executes a bash script synchronously.
		 * Script is executed in a fullscreen terminal window */
		
		string path;
		
		path = get_cmd_path ("xfce4-terminal");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("xfce4-terminal --fullscreen -e \"%s\"".printf(script_file));
		}
		
		path = get_cmd_path ("gnome-terminal");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("gnome-terminal --full-screen -e \"%s\"".printf(script_file));
		}
		
		path = get_cmd_path ("xterm");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("xterm -fullscreen -e \"%s\"".printf(script_file));
		}
		
		//default terminal - unknown, normal window
		path = get_cmd_path ("x-terminal-emulator");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("x-terminal-emulator -e \"%s\"".printf(script_file));
		}
		
		return -1;
	}
	
	public int execute_bash_script_sync (string script_file){
			
		/* Executes a bash script synchronously in the default terminal window */
		
		string path = get_cmd_path ("x-terminal-emulator");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("x-terminal-emulator -e \"%s\"".printf(script_file));
		}
		
		return -1;
	}
	
	public string get_cmd_path (string cmd){
				
		/* Returns the full path to a command */
		
		try {
			int exitCode; 
			string stdout, stderr;
			Process.spawn_command_line_sync("which " + cmd, out stdout, out stderr, out exitCode);
	        return stdout;
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}

	public int get_pid_by_name (string name){
				
		/* Get the process ID for a process with given name */
		
		try{
			string output = "";
			Process.spawn_command_line_sync("pidof \"%s\"".printf(name), out output);
			if (output != null){
				string[] arr = output.split ("\n");
				if (arr.length > 0){
					return int.parse (arr[0]);
				}
			}
		} 
		catch (Error e) { 
			log_error (e.message); 
		}
		
		return -1;
	}
	
	public int[] get_pid_by_command (string proc_name, string command){
				
		/* Get the process IDs for given process name and command string */
		
		int[] proc_list = {};
		
		//'ps' output strips double and single quotes so we will remove it too for matching with output
		string cmd = command.replace("\"","").replace("'",""); 

		try{
			Regex rex = new Regex("""^[ \t]*([0-9]*)[ \t]*""");
			MatchInfo match;
			
			string txt = execute_command_sync_get_output ("ps ew -C " + proc_name); //ew = all users 
			
			log_msg(txt);
			foreach(string line in txt.split("\n")){
				if (line.index_of(cmd) != -1){
					if (rex.match (line, 0, out match)){
						proc_list += int.parse(match.fetch(1).strip());
					}
				}
			}
		} 
		catch (Error e) { 
			log_error (e.message); 
		}
		
		return proc_list;
	}
	
	public bool process_is_running(long pid){
				
		/* Checks if given process is running */
		
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;
		
		try{
			cmd = "ps --pid %ld".printf(pid);
			Process.spawn_command_line_sync(cmd, out std_out, out std_err, out ret_val);
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
		
		return (ret_val == 0);
	}

	public int[] get_process_children (Pid parentPid){
				
		/* Returns the list of child processes spawned by given process */
		
		string output;
		
		try {
			Process.spawn_command_line_sync("ps --ppid %d".printf(parentPid), out output);
		}
		catch(Error e){
	        log_error (e.message);
	    }
			
		int pid;
		int[] procList = {};
		string[] arr;
		
		foreach (string line in output.split ("\n")){
			arr = line.strip().split (" ");
			if (arr.length < 1) { continue; }
			
			pid = 0;
			pid = int.parse (arr[0]);
			
			if (pid != 0){
				procList += pid;
			}
		}
		return procList;
	}
	
	
	public void process_kill(Pid process_pid, bool killChildren = true){
				
		/* Kills specified process and its children (optional) */
		
		int[] child_pids = get_process_children (process_pid);
		Posix.kill (process_pid, 15);
		
		if (killChildren){
			Pid childPid;
			foreach (long pid in child_pids){
				childPid = (Pid) pid;
				Posix.kill (childPid, 15);
			}
		}
	}
	
	public int process_pause (Pid procID){
				
		/* Pause/Freeze a process */
		
		return execute_command_sync ("kill -STOP %d".printf(procID));
	}
	
	public int process_resume (Pid procID){
				
		/* Resume/Un-freeze a process*/
		
		return execute_command_sync ("kill -CONT %d".printf(procID));
	}

	public void command_kill(string cmd_name, string cmd){
				
		/* Kills a specific command */

		string txt = execute_command_sync_get_output ("ps w -C %s".printf(cmd_name));
		//use 'ps ew -C conky' for all users
		
		string pid = "";
		foreach(string line in txt.split("\n")){
			if (line.index_of(cmd) != -1){
				pid = line.strip().split(" ")[0];
				Posix.kill ((Pid) int.parse(pid), 15);
				log_debug(_("Stopped") + ": [PID=" + pid + "] ");
			}
		}
	}
	
	
	public void process_set_priority (Pid procID, int prio){
				
		/* Set process priority */
		
		if (Posix.getpriority (Posix.PRIO_PROCESS, procID) != prio)
			Posix.setpriority (Posix.PRIO_PROCESS, procID, prio);
	}
	
	public int process_get_priority (Pid procID){
				
		/* Get process priority */
		
		return Posix.getpriority (Posix.PRIO_PROCESS, procID);
	}
	
	public void process_set_priority_normal (Pid procID){
				
		/* Set normal priority for process */
		
		process_set_priority (procID, 0);
	}
	
	public void process_set_priority_low (Pid procID){
				
		/* Set low priority for process */
		
		process_set_priority (procID, 5);
	}
	

	public bool user_is_admin (){
				
		/* Check if current application is running with admin priviledges */
		
		try{
			// create a process
			string[] argv = { "sleep", "10" };
			Pid procId;
			Process.spawn_async(null, argv, null, SpawnFlags.SEARCH_PATH, null, out procId); 
			
			// try changing the priority
			Posix.setpriority (Posix.PRIO_PROCESS, procId, -5);
			
			// check if priority was changed successfully
			if (Posix.getpriority (Posix.PRIO_PROCESS, procId) == -5)
				return true;
			else
				return false;
		} 
		catch (Error e) { 
			//log_error (e.message); 
			return false;
		}
	}

	public string get_user_login(){
		/* 
		Returns Login ID of current user.
		If running as 'sudo' it will return Login ID of the actual user.
		*/

		string cmd = "echo ${SUDO_USER:-$(whoami)}";
		string std_out;
		string std_err;
		int ret_val;
		ret_val = execute_command_script_sync(cmd, out std_out, out std_err);
		
		string user_name;
		if ((std_out == null) || (std_out.length == 0)){
			user_name = "root";
		}
		else{
			user_name = std_out.strip();
		}
		
		return user_name;
	}

	public int get_user_id(string user_login){
		/* 
		Returns UID of specified user.
		*/
		
		int uid = -1;
		string cmd = "id %s -u".printf(user_login);
		string txt = execute_command_sync_get_output(cmd);
		if ((txt != null) && (txt.length > 0)){
			uid = int.parse(txt);
		}
		
		return uid;
	}
	
	
	public string get_app_path (){
				
		/* Get path of current process */
		
		try{
			return GLib.FileUtils.read_link ("/proc/self/exe");	
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}
	
	public string get_app_dir (){
				
		/* Get parent directory of current process */
		
		try{
			return (File.new_for_path (GLib.FileUtils.read_link ("/proc/self/exe"))).get_parent ().get_path ();	
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}
}