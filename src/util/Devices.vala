/*
 * Devices.vala
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

namespace TeeJee.Devices{
	
	/* Functions and classes for handling disk partitions */
		
	using TeeJee.Logging;
	using TeeJee.FileSystem;
	using TeeJee.ProcessManagement;

	public class Device : GLib.Object{
		
		/* Class for storing disk information */
		
		GUdev.Device udev_device;
		public string device = "";
		public string type = "";
		public string label = "";
		public string uuid = "";

		public string vendor = "";
		public string model = "";
		public bool removable = false;
		public string devtype = ""; //disk or partition
		
		public long size_mb = 0;
		public long used_mb = 0;

		public string available = "";
		public string used_percent = "";
		public string dist_info = "";
		public Gee.ArrayList<string> mount_points;
		public Gee.ArrayList<string> symlinks;
		public string mount_options = "";
		
		public static Gee.HashMap<string,Device> device_list_master;
		
		public Device(){
			mount_points = new Gee.ArrayList<string>();
			symlinks = new Gee.ArrayList<string>();
		}
		
		public Device.from_udev(GUdev.Device d){
			mount_points = new Gee.ArrayList<string>();
			symlinks = new Gee.ArrayList<string>();
			
			udev_device = d;
			
			device = d.get_device_file();
			
			devtype = d.get_devtype();
			//change devtype to 'partition' for device mapper disks
			if (device.has_prefix("/dev/dm-")){
				devtype = "partition";
			}
			
			label = d.get_property("ID_FS_LABEL");
			label = (label == null) ? "" : label;
			
			uuid = d.get_property("ID_FS_UUID");
			uuid = (uuid == null) ? "" : uuid.down();
			
			type = d.get_property("ID_FS_TYPE");
			type = (type == null) ? "" : type.down();
			type = type.contains("luks") ? "luks" : type;
			
			foreach (string symlink in d.get_device_file_symlinks()){
				symlinks.add(symlink);
			}
		}
		
		/* Returns: 
		 * 'sda3' for '/dev/sda3'
		 * 'luks' for '/dev/mapper/luks'
		 * */
		 
		public string name{
			owned get{
				if (devtype == "partition"){
					return udev_device.get_name();
				}
				else{
					return device.replace("/dev/mapper/","").replace("/dev/","");
				}
			}
		}

		public string full_name_with_alias{
			owned get{
				string text = "";
				string symlink = "";
				foreach(string sym in symlinks){
					if (sym.has_prefix("/dev/mapper/")){
						symlink = sym;
					}
				}
				text = device + ((symlink.length > 0) ? " (" + symlink + ")" : ""); //→
				if (devtype == "partition"){
					return text;
				}
				else{
					return name;
				}
			}
		}
		
		public string short_name_with_alias{
			owned get{
				string text = "";
				string symlink = "";
				foreach(string sym in symlinks){
					if (sym.has_prefix("/dev/mapper/")){
						symlink = sym.replace("/dev/mapper/","").replace("/dev/","");
					}
				}
				
				if (symlink.length > 15){
					symlink = symlink[0:14] + "...";
				}
				text = device.replace("/dev/mapper/","") + ((symlink.length > 0) ? " (" + symlink + ")" : ""); //→
				return text;
			}
		}

		public void print_properties(){
			if (udev_device != null){
				foreach(string key in udev_device.get_property_keys()){
					stdout.printf("%-50s %s\n".printf(key, udev_device.get_property(key)));
				}
			}
		}
		
		public string description(){
			return description_formatted().replace("<b>","").replace("</b>","");
		}

		public string description_formatted(){
			string s = "";
			
			if (devtype == "disk"){
				s += "<b>" + short_name_with_alias + "</b>";
				s += ((vendor.length > 0)||(model.length > 0)) ? (" ~ " + vendor + " " + model) : "";
			}
			else{
				s += "<b>" + short_name_with_alias + "</b>" ;
				s += (label.length > 0) ? " (" + label + ")": "";
				s += (type.length > 0) ? " ~ " + type : "";
				s += (used.length > 0) ? " ~ " + used + " / " + size + " GB used (" + used_percent + ")" : "";
			}
			
			return s;
		}
		
		public string description_full(){
			string s = "";
			s += device;
			s += (label.length > 0) ? " (" + label + ")": "";
			s += (uuid.length > 0) ? " ~ " + uuid : "";
			s += (type.length > 0) ? " ~ " + type : "";
			s += (used.length > 0) ? " ~ " + used + " / " + size + " GB used (" + used_percent + ")" : "";
			
			string mps = "";
			foreach(string mp in mount_points){
				mps += mp + " ";
			}
			s += (mps.length > 0) ? " ~ " + mps.strip() : "";
			
			return s;
		}
		
		public string description_usage(){
			if (used.length > 0){
				return used + " / " + size + " used (" + used_percent + ")";
			}
			else{
				return "";
			}
		}
		
		public string size{
			owned get{
				return (size_mb == 0) ? "" : "%.1f".printf(size_mb/1024.0);
			}
		}
		
		public string used{
			owned get{
				return (used_mb == 0) ? "" : "%.1f".printf(used_mb/1024.0);
			}
		}
		
		public long free_mb{
			get{
				return (size_mb - used_mb);
			}
		}
		
		public bool is_mounted{
			get{
				return (mount_points.size > 0);
			}
		}
		
		public string free{
			owned get{
				return (free_mb == 0) ? "" : "%.1f GB".printf(free_mb/1024.0);
			}
		}

		public bool has_linux_filesystem(){
			switch(type){
				case "ext2":
				case "ext3":
				case "ext4":
				case "reiserfs":
				case "reiser4":
				case "xfs":
				case "jfs":
				case "btrfs":
				case "luks":
					return true;
				default:
					return false;
			}
		}

		public static Gee.HashMap<string,Device> get_block_devices_using_udev(){
			var map = new Gee.HashMap<string,Device>();
			var uc = new GUdev.Client(null);
			GLib.List<GUdev.Device> devs = uc.query_by_subsystem("block");

			foreach (GUdev.Device d in devs){
				Device dev = new Device.from_udev(d);
				if ((dev.uuid.length > 0) && !map.has_key(dev.uuid)){
					map.set(dev.uuid, dev);
				}
			}
			
			device_list_master = map;
			
			return map;
		}
		
		public static Gee.HashMap<string,Device> get_block_devices_using_blkid(string device_file){

			/* Returns list of mounted partitions using 'blkid' command 
			   Populates device, type, uuid, label */

			var map = new Gee.HashMap<string,Device>();

			string std_out;
			string std_err;
			string cmd;
			int ret_val;
			Regex rex;
			MatchInfo match;
			
			cmd = "/sbin/blkid" + ((device_file.length > 0) ? " " + device_file: "");
			ret_val = execute_command_script_sync(cmd, out std_out, out std_err);
			if (ret_val != 0){
				log_error ("blkid: " + _("Failed to get partition list") + ((device_file.length > 0) ? ": " + device_file : ""));
				return map; //return empty map
			}
				
			/*
			sample output
			-----------------
			/dev/sda1: LABEL="System Reserved" UUID="F476B08076B04560" TYPE="ntfs" 
			/dev/sda2: LABEL="windows" UUID="BE00B6DB00B69A3B" TYPE="ntfs" 
			/dev/sda3: UUID="03f3f35d-71fa-4dff-b740-9cca19e7555f" TYPE="ext4"
			*/
			
			//parse output and build filesystem map -------------

			foreach(string line in std_out.split("\n")){
				if (line.strip().length == 0) { continue; }
				
				Device pi = new Device();
				
				pi.device = line.split(":")[0].strip();
				
				if (pi.device.length == 0) { continue; }
				
				//exclude non-standard devices --------------------

				if (!pi.device.has_prefix("/dev/")){
					continue;
				}
				
				if (pi.device.has_prefix("/dev/sd") || pi.device.has_prefix("/dev/hd") || pi.device.has_prefix("/dev/mapper/") || pi.device.has_prefix("/dev/dm")) { 
					//ok
				}
				else if (pi.device.has_prefix("/dev/disk/by-uuid/")){
					//ok, get uuid
					pi.uuid = pi.device.replace("/dev/disk/by-uuid/","");
				}
				else{
					continue; //skip
				}

				//parse & populate fields ------------------
				
				try{
					rex = new Regex("""LABEL=\"([^\"]*)\"""");
					if (rex.match (line, 0, out match)){
						pi.label = match.fetch(1).strip();
					}
					
					rex = new Regex("""UUID=\"([^\"]*)\"""");
					if (rex.match (line, 0, out match)){
						pi.uuid = match.fetch(1).strip();
					}
					
					rex = new Regex("""TYPE=\"([^\"]*)\"""");
					if (rex.match (line, 0, out match)){
						pi.type = match.fetch(1).strip();
					}
				}
				catch(Error e){
					log_error (e.message);
				}
							
				//add to map -------------------------
				
				if ((pi.uuid.length > 0) && !map.has_key(pi.uuid)){
					map.set(pi.uuid, pi);
				}
			}
			
			return map;
		}

		public static Gee.HashMap<string,Device> get_disk_space_using_df(string device_or_mount_point = ""){
			
			/* Returns list of mounted partitions using 'df' command 
			   Populates device, type, size, used and mount_point_list */
			 
			var map = new Gee.HashMap<string,Device>();
			
			string std_out;
			string std_err;
			string cmd;
			int ret_val;
			
			cmd = "df -T -BM" + ((device_or_mount_point.length > 0) ? " \"%s\"".printf(device_or_mount_point): "");
			ret_val = execute_command_script_sync(cmd, out std_out, out std_err);
			//ret_val is not reliable, no need to check
			
			/*
			sample output
			-----------------
			Filesystem     Type     1M-blocks    Used Available Use% Mounted on
			/dev/sda3      ext4        25070M  19508M     4282M  83% /
			none           tmpfs           1M      0M        1M   0% /sys/fs/cgroup
			udev           devtmpfs     3903M      1M     3903M   1% /dev
			tmpfs          tmpfs         789M      1M      788M   1% /run
			none           tmpfs           5M      0M        5M   0% /run/lock
			/dev/sda3      ext4        25070M  19508M     4282M  83% /mnt/rewind
			*/
			
			string[] lines = std_out.split("\n");

			int line_num = 0;
			foreach(string line in lines){

				if (++line_num == 1) { continue; }
				if (line.strip().length == 0) { continue; }
				
				Device pi = new Device();
				
				//parse & populate fields ------------------
				
				int k = 1;
				foreach(string val in line.split(" ")){
					
					if (val.strip().length == 0){ continue; }

					switch(k++){
						case 1:
							pi.device = val.strip();
							break;
						case 2:
							pi.type = val.strip();
							break;
						case 3:
							pi.size_mb = long.parse(val.strip().replace("M",""));
							break;
						case 4:
							pi.used_mb = long.parse(val.strip().replace("M",""));
							break;
						case 5:
							pi.available = val.strip();
							break;
						case 6:
							pi.used_percent = val.strip();
							break;
						case 7:
							//string mount_point = val.strip();
							//if (!pi.mount_point_list.contains(mount_point)){
							//	pi.mount_point_list.add(mount_point);
							//}
							break;
					}
				}
				
				/* Note: 
				 * The mount points displayed by 'df' are not reliable.
				 * For example, if same device is mounted at 2 locations, 'df' displays only the first location.
				 * Hence, we will not populate the 'mount_points' field in Device object
				 * Use get_mounted_filesystems_using_mtab() if mount info is required
				 * */
				 
				//exclude non-standard devices --------------------
				
				if (!pi.device.has_prefix("/dev/")){
					continue;
				}
					
				if (pi.device.has_prefix("/dev/sd") || pi.device.has_prefix("/dev/hd") || pi.device.has_prefix("/dev/mapper/") || pi.device.has_prefix("/dev/dm")) { 
					//ok
				}
				else if (pi.device.has_prefix("/dev/disk/by-uuid/")){
					//ok, get uuid
					pi.uuid = pi.device.replace("/dev/disk/by-uuid/","");
				}
				else{
					continue; //skip
				}

				//get uuid ---------------------------
				
				pi.uuid = get_device_uuid(pi.device);

				//add to map -------------------------
				
				if ((pi.uuid.length > 0) && !map.has_key(pi.uuid)){
					map.set(pi.uuid, pi);
				}
			}

			return map;
		}

		public static Gee.HashMap<string,Device> get_mounted_filesystems_using_mtab(){
			
			/* Returns list of mounted partitions by reading /proc/mounts
			   Populates device, type and mount_point_list */

			var map = new Gee.HashMap<string,Device>();
			
			string mtab_path = "/etc/mtab";
			string mtab_lines = "";
			
			File f;
			
			//find mtab file -----------
			 
			mtab_path = "/proc/mounts";
			f = File.new_for_path(mtab_path);
			if(!f.query_exists()){
				mtab_path = "/proc/self/mounts";
				f = File.new_for_path(mtab_path);
				if(!f.query_exists()){
					mtab_path = "/etc/mtab";
					f = File.new_for_path(mtab_path);
					if(!f.query_exists()){
						return map; //empty list
					}
				}
			}
			
			/* Note:
			 * /etc/mtab represents what 'mount' passed to the kernel 
			 * whereas /proc/mounts shows the data as seen inside the kernel
			 * Hence /proc/mounts is always up-to-date whereas /etc/mtab might not be
			 * */
			 
			//read -----------
			
			mtab_lines = read_file(mtab_path);
			
			/*
			sample mtab
			-----------------
			/dev/sda3 / ext4 rw,errors=remount-ro 0 0
			proc /proc proc rw,noexec,nosuid,nodev 0 0
			sysfs /sys sysfs rw,noexec,nosuid,nodev 0 0
			none /sys/fs/cgroup tmpfs rw 0 0
			none /sys/fs/fuse/connections fusectl rw 0 0
			none /sys/kernel/debug debugfs rw 0 0
			none /sys/kernel/security securityfs rw 0 0
			udev /dev devtmpfs rw,mode=0755 0 0

			device - the device or remote filesystem that is mounted.
			mountpoint - the place in the filesystem the device was mounted.
			filesystemtype - the type of filesystem mounted.
			options - the mount options for the filesystem
			dump - used by dump to decide if the filesystem needs dumping.
			fsckorder - used by fsck to detrmine the fsck pass to use. 
			*/
			
			/* Note:
			 * We are interested only in the last device that was mounted at a given mount point
			 * Hence the lines must be parsed in reverse order (from last to first)
			 * */
			 
			//parse ------------
			
			string[] lines = mtab_lines.split("\n");
			var mount_list = new Gee.ArrayList<string>();
			
			for (int i = lines.length - 1; i >= 0; i--){
				
				string line = lines[i].strip();
				if (line.length == 0) { continue; }
				
				Device pi = new Device();

				//parse & populate fields ------------------
								
				int k = 1;
				foreach(string val in line.split(" ")){
					if (val.strip().length == 0){ continue; }
					switch(k++){
						case 1: //device
							pi.device = val.strip();
							break;
						case 2: //mountpoint
							string mount_point = val.strip();
							if (!mount_list.contains(mount_point)){
								mount_list.add(mount_point);
								if (!pi.mount_points.contains(mount_point)){
									pi.mount_points.add(mount_point);
								}
							}
							break;
						case 3: //filesystemtype
							pi.type = val.strip();
							break;
						case 4: //options
							pi.mount_options = val.strip();
							break;
						default:
							//ignore
							break;
					}
				}
				
				//exclude unknown device names ----------------

				if (!pi.device.has_prefix("/dev/")){
					continue;
				}
				
				if (pi.device.has_prefix("/dev/sd") || pi.device.has_prefix("/dev/hd") || pi.device.has_prefix("/dev/mapper/") || pi.device.has_prefix("/dev/dm")) { 
					//ok
				}
				else if (pi.device.has_prefix("/dev/disk/by-uuid/")){
					//ok, get uuid
					pi.uuid = pi.device.replace("/dev/disk/by-uuid/","");
				}
				else{
					continue; //skip
				}

				//get uuid ---------------------------
				
				pi.uuid = get_device_uuid(pi.device);

				//add to map -------------------------
				
				if (pi.uuid.length > 0){
					if (!map.has_key(pi.uuid)){
						map.set(pi.uuid, pi);
					}
					else{
						//append mount points
						var pi2 = map.get(pi.uuid);
						foreach(string mp in pi.mount_points){
							pi2.mount_points.add(mp);
						}
					}
				}
			}

			return map;
		}
	
		public static Gee.HashMap<string,Device> get_filesystems(bool get_space = true, bool get_mounts = true){
			
			/* Returns list of block devices
			   Populates all fields in Device class */
			   
			var map = get_block_devices_using_udev();

			if (get_space){
				//get used space for mounted filesystems
				var map_df = get_disk_space_using_df();
				foreach(string key in map_df.keys){
					if (map.has_key(key)){
						var pi = map.get(key);
						var pi_df = map_df.get(key);
						pi.size_mb = pi_df.size_mb;
						pi.used_mb = pi_df.used_mb;
						pi.available = pi_df.available;
						pi.used_percent = pi_df.used_percent;
						
						if (pi.device.has_prefix("/dev/disk/by-uuid/") || pi.device.length > 25){
							//check if df has a more friendly device name 
							if (pi_df.device.has_prefix("/dev/hd") || pi_df.device.has_prefix("/dev/sd") || pi_df.device.has_prefix("/dev/mapper/") || pi_df.device.has_prefix("/dev/dm")){
								//get device name from df
								pi.device = pi_df.device;
							}
						}
					}
				}
			}
			
			if (get_mounts){
				//get mount points
				var map_mt = get_mounted_filesystems_using_mtab();
				foreach(string key in map.keys){
					if (map_mt.has_key(key)){
						var pi = map.get(key);
						var pi_mt = map_mt.get(key);
						pi.mount_points = pi_mt.mount_points;
					}
				}
			}

			return map;
		}
		
		public static Device refresh_partition_usage_info(Device pi){
		
			/* Updates disk space info and returns the given Device object */
			
			var map_df = get_disk_space_using_df(pi.device);
			if (map_df.has_key(pi.uuid)){
				var pi_df = map_df.get(pi.uuid);
				pi.size_mb = pi_df.size_mb;
				pi.used_mb = pi_df.used_mb;
				pi.available = pi_df.available;
				pi.used_percent = pi_df.used_percent;
			}

			return pi;
		}
		
		public static string get_device_uuid(string device){
			if (device_list_master == null){
				get_block_devices_using_udev();
			}
			
			foreach(Device dev in device_list_master.values){
				if (dev.device == device){
					return dev.uuid;
				}
				else{
					foreach(string symlink in dev.symlinks){
						if (symlink == device){
							return dev.uuid;
						}
					}
				}
			}
			
			return "";
		}

		public static Gee.ArrayList<string> get_mount_points(string device_or_uuid){
			string device = "";
			string uuid = "";
			
			if (device_or_uuid.has_prefix("/dev")){
				device = device_or_uuid;
				uuid = get_device_uuid(device_or_uuid);
			}
			else{
				uuid = device_or_uuid;
				device = "/dev/disk/by-uuid/%s".printf(uuid);
			}
				
			var map = get_mounted_filesystems_using_mtab();
			if (map.has_key(uuid)){
				var pi = map.get(uuid);
				return pi.mount_points;
			}
			
			return (new Gee.ArrayList<string>());
		}

	}

	public class FsTabEntry : GLib.Object{
		public bool is_comment = false;
		public bool is_empty_line = false;
		public string device = "";
		public string mount_point = "";
		public string type = "";
		public string options = "defaults";
		public string dump = "0";
		public string pass = "0";
		public string line = "";
		
		public static Gee.ArrayList<FsTabEntry> read_fstab_file(string fstab_file_path){
			Gee.ArrayList<FsTabEntry> list = new Gee.ArrayList<FsTabEntry>();
			
			if (!file_exists(fstab_file_path)){ return list; }
			
			string text = read_file(fstab_file_path);
			string[] lines = text.split("\n");
			foreach(string line in lines){
				FsTabEntry entry = new FsTabEntry();
				list.add(entry);
				
				entry.is_comment = line.strip().has_prefix("#");
				entry.is_empty_line = (line.strip().length == 0);
				
				if (entry.is_comment){
					entry.line = line;
				}
				else if (entry.is_empty_line){
					entry.line = "";
				}
				else{
					entry.line = line;
					
					string[] parts = line.replace("\t"," ").split(" ");
					int part_num = -1;
					foreach(string part in parts){
						if (part.strip().length == 0) { continue; }
						switch (++part_num){
							case 0:
								entry.device = part.strip();
								break;
							case 1:
								entry.mount_point = part.strip();
								break;
							case 2:
								entry.type = part.strip();
								break;
							case 3:
								entry.options = part.strip();
								break;
							case 4:
								entry.dump = part.strip();
								break;
							case 5:
								entry.pass = part.strip();
								break;
						}
					}
				}
			}
			
			return list;
		}

		public static string create_fstab_file(FsTabEntry[] fstab_entries, bool keep_comments_and_empty_lines = true){
			string text = "";
			foreach(FsTabEntry entry in fstab_entries){
				if (entry.is_comment || entry.is_empty_line){
					if (keep_comments_and_empty_lines){
						text += "%s\n".printf(entry.line);
					}
				}
				else {
					text += "%s\t%s\t%s\t%s\t%s\t%s\n".printf(entry.device, entry.mount_point, entry.type, entry.options, entry.dump, entry.pass);
				}
			}
			return text;
		}
	}
	
	public class MountEntry : GLib.Object{
		public Device device = null;
		public string mount_point = "";
		
		public MountEntry(Device device, string mount_point){
			this.device = device;
			this.mount_point = mount_point;
		}
	}

	public bool mount(string device_or_uuid, string mount_point, string mount_options = ""){
		
		/* Mounts specified device at specified mount point.
		 * */
		
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;
		string device = "";
		string uuid = "";

		//get uuid -----------------------------
		
		if (device_or_uuid.has_prefix("/dev")){
			device = device_or_uuid;
			uuid = Device.get_device_uuid(device_or_uuid);
		}
		else{
			uuid = device_or_uuid;
			device = "/dev/disk/by-uuid/%s".printf(uuid);
		}

		//check if already mounted -------------
		
		var map = Device.get_mounted_filesystems_using_mtab();
		if (map.has_key(uuid)){
			var pi = map.get(uuid);
			if (pi.mount_points.contains(mount_point)){
				return true;
			}
		}

		try{
			//check and create mount point -------------------
			
			File file = File.new_for_path(mount_point);
			if (!file.query_exists()){
				file.make_directory_with_parents();
			}

			//mount the device --------------------

			if (mount_options.length > 0){
				cmd = "mount -o %s \"%s\" \"%s\"".printf(mount_options, device, mount_point);
			} 
			else{
				cmd = "mount \"%s\" \"%s\"".printf(device, mount_point);
			}

			Process.spawn_command_line_sync(cmd, out std_out, out std_err, out ret_val);

			if (ret_val != 0){
				log_error ("Failed to mount device '%s' at mount point '%s'".printf(device, mount_point));
				log_error (std_err);
				return false;
			}
			else{
				log_debug ("Mounted device '%s' at mount point '%s'".printf(device, mount_point));
			}
		}
		catch(Error e){
			log_error (e.message);
			return false;
		}
		
		//check if mounted successfully -------------
			
		map = Device.get_mounted_filesystems_using_mtab();
		if (map.has_key(uuid)){
			var pi = map.get(uuid);
			if (pi.mount_points.contains(mount_point)){
				return true;
			}
		}
		return false;
	}
	
	public string automount(string device_or_uuid, string mount_options = "", string mount_prefix = "/mnt"){
		
		/* Returns the mount point of specified device.
		 * If unmounted, mounts the device to /mnt/<uuid> and returns the mount point.
		 * */
		 
		string device = "";
		string uuid = "";
		
		//get uuid -----------------------------
			
		if (device_or_uuid.has_prefix("/dev")){
			device = device_or_uuid;
			uuid = Device.get_device_uuid(device_or_uuid);
		}
		else{
			uuid = device_or_uuid;
			device = "/dev/disk/by-uuid/%s".printf(uuid);
		}
		
		//check if already mounted and return mount point -------------
		
		var map = Device.get_filesystems();
		if (map.has_key(uuid)){
			var pi = map.get(uuid);
			if ((pi.mount_points.size > 0) && (pi.size_mb > 0)){
				return pi.mount_points[0];
			}
		}
		
		//check and create mount point -------------------
		
		string mount_point = "%s/%s".printf(mount_prefix, uuid);
		
		try{
			File file = File.new_for_path(mount_point);
			if (!file.query_exists()){
				file.make_directory_with_parents();
			}
		}
		catch(Error e){
			log_error (e.message);
			return "";
		}
		
		//mount the device and return mount_point --------------------

		if (mount(uuid, mount_point, mount_options)){
			return mount_point;
		}
		else{
			return "";
		}
	}
	
	public bool unmount(string mount_point){
		
		/* Recursively unmounts all devices at given mount_point and subdirectories
		 * */

		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;

		//check if mounted -------------
			
		bool mounted = false;
		var map = Device.get_mounted_filesystems_using_mtab();
		foreach (Device pi in map.values){
			foreach (string mp in pi.mount_points){
				if (mp.has_prefix(mount_point)){ //check for any mount_point at or under the given mount_point
					mounted = true;
				}
			}
		}
		if (!mounted) { return true; }
		
		//try to unmount ------------------
		
		try{
			
			string cmd_unmount = "cat /proc/mounts | awk '{print $2}' | grep '%s' | sort -r | xargs umount".printf(mount_point);
			
			log_debug(_("Unmounting from") + ": '%s'".printf(mount_point));
			
			//sync before unmount
			cmd = "sync";
			Process.spawn_command_line_sync(cmd, out std_out, out std_err, out ret_val);
			//ignore success/failure
			
			//unmount
			ret_val = execute_command_script_sync(cmd_unmount, out std_out, out std_err);
			
			if (ret_val != 0){
				log_error (_("Failed to unmount"));
				log_error (std_err);
			}
		}
		catch(Error e){
			log_error (e.message);
			return false;
		}
		
		//check if unmounted --------------------------
		
		mounted = false;
		map = Device.get_mounted_filesystems_using_mtab();
		foreach (Device pi in map.values){
			foreach (string mp in pi.mount_points){
				if (mp.has_prefix(mount_point)){ //check for any mount_point at or under the given mount_point
					mounted = true;
				}
			}
		}
			
		return !mounted;
	}
	
	public string get_device_mount_point(string device_or_uuid){
		/* Returns the mount point of specified device.
		 * If unmounted, mounts the device to /mnt/<uuid> and returns the mount point.
		 * */
		 
		string device = "";
		string uuid = "";
		
		//get uuid -----------------------------
			
		if (device_or_uuid.has_prefix("/dev")){
			device = device_or_uuid;
			uuid = Device.get_device_uuid(device_or_uuid);
		}
		else{
			uuid = device_or_uuid;
			device = "/dev/disk/by-uuid/%s".printf(uuid);
		}
		
		//check if already mounted and return mount point -------------
		
		var map = Device.get_mounted_filesystems_using_mtab();
		if (map.has_key(uuid)){
			var pi = map.get(uuid);
			if (pi.mount_points.size > 0){
				return pi.mount_points[0];
			}
		}
		return "";
	}
	
	public Gee.ArrayList<Device> get_block_devices(){
		
		/* Returns a list of all storage devices including vendor and model number */
		
		var device_list = new Gee.ArrayList<Device>();
		
		string letters = "abcdefghijklmnopqrstuvwxyz";
		string letter = "";
		string path = "";
		string device = "";
		string model = "";
		string vendor = "";
		string removable = "";
		File f;
		
		for(int i=0; i<26; i++){
			letter = letters[i:i+1];

			path = "/sys/block/sd%s".printf(letter);
			f = File.new_for_path(path); 
			if (f.query_exists()){
				
				device = "";
				model = "";
				removable = "0";
				
				f = File.new_for_path(path + "/device/vendor"); 
				if (f.query_exists()){
					vendor = read_file(path + "/device/vendor");
				}
				
				f = File.new_for_path(path + "/device/model"); 
				if (f.query_exists()){
					model = read_file(path + "/device/model");
				}
				
				f = File.new_for_path(path + "/removable"); 
				if (f.query_exists()){
					removable = read_file(path + "/removable");
				}

				if ((vendor.length > 0) || (model.length > 0)){
					var dev = new Device();
					dev.device = "/dev/sd%s".printf(letter);
					dev.vendor = vendor.strip();
					dev.model = model.strip();
					dev.removable = (removable == "0") ? false : true;
					dev.devtype = "disk";
					device_list.add(dev);
				}
			}
		}
		
		return device_list;
	}
}