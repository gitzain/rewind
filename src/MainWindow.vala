using Gtk;

namespace RewindUtil {



public class MainWindow : Window {






public class SettingLabel : Gtk.Label {
    public SettingLabel (string label) {
        Object (label: label);
    }

    construct {
        halign = Gtk.Align.END;
        margin_start = 12;
    }
}


    public MainWindow()
    {
        // Setup the window
        this.destroy.connect(Gtk.main_quit);
        this.set_default_size (1000, 675);

        // Create and add header to window
        var header = new Gtk.HeaderBar();
        header.set_show_close_button(true);
        header.set_title("Rewind");
        this.set_titlebar(header);

        // Create snapshop button
        var icon_create_snapshot = new Image.from_icon_name("document-new", IconSize.SMALL_TOOLBAR);
        var button_create_snapshot = new ToolButton(icon_create_snapshot, "Create Snapshot");
        button_create_snapshot.is_important = true;
        header.pack_start(button_create_snapshot);



        // Create the backup welcome page
	    //var backup_screen = new Granite.Widgets.Welcome ("Backup Your System", "Take your first snapshot.");
        //backup_screen.append ("document-new", "Take Snapshot", "A snapshot is a point in time backup of your system");
        var backup_screen = new Gtk.Grid();
        backup_screen.margin = 12;
        backup_screen.row_spacing = 12;
        backup_screen.halign = Gtk.Align.CENTER;



        var source_grid = new Gtk.Grid();

        var title_label = new Gtk.Label ("Source");
        title_label.xalign = 0;
        title_label.hexpand = true;
        title_label.get_style_context ().add_class ("h4");

        var system_files_switch = new Gtk.Switch ();
        system_files_switch.halign = Gtk.Align.START;

        var help_icon_system_switch = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.BUTTON);
        help_icon_system_switch.halign = Gtk.Align.START;
        help_icon_system_switch.hexpand = true;
        help_icon_system_switch.tooltip_text = "Pressing the control key will highlight the position of the pointer";



        var reveal_pointer_switch = new Gtk.Switch ();
        reveal_pointer_switch.halign = Gtk.Align.START; 

        var help_icon = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.BUTTON);
        help_icon.halign = Gtk.Align.START;
        help_icon.hexpand = true;
        help_icon.tooltip_text = "Pressing the control key will highlight the position of the pointer";





        source_grid.row_spacing = 12;
        source_grid.column_spacing = 12;

        source_grid.attach (title_label, 0, 0, 1, 1);

        source_grid.attach (new SettingLabel ("System files:"), 0, 1, 1, 1);
        source_grid.attach (system_files_switch, 1, 1, 2, 1);
        source_grid.attach (help_icon_system_switch, 2, 1, 1, 1);

        source_grid.attach (new SettingLabel ("User files:"), 0, 2, 1, 1);
        source_grid.attach (reveal_pointer_switch, 1, 2, 1, 1);
        source_grid.attach (help_icon, 2, 2, 1, 1);








        var title_label2 = new Gtk.Label ("Target");
        title_label2.xalign = 0;
        title_label2.hexpand = true;
        title_label2.get_style_context ().add_class ("h4");
        //Plug.start_size_group.add_widget (title_label);

        var scrolling_combobox = new Gtk.ComboBoxText ();
        scrolling_combobox.hexpand = true;
        scrolling_combobox.append ("two-finger-scrolling", "Two-finger");
        scrolling_combobox.append ("edge-scrolling", "Edge");
        scrolling_combobox.append ("disabled", "Disabled");

scrolling_combobox.width_request = 256;


        source_grid.row_spacing = 12;
        source_grid.column_spacing = 12;

        source_grid.attach (title_label2, 0, 3, 1, 1);
        source_grid.attach (new SettingLabel ("Backup location:"), 0, 4, 1, 1);
        source_grid.attach (scrolling_combobox, 1, 4, 1, 1);




            var start_bt = new Gtk.Button.with_label ("Start Recording");
            start_bt.can_default = true;
            start_bt.get_style_context ().add_class ("noundo");
            start_bt.get_style_context ().add_class ("suggested-action");

            var cancel_bt = new Gtk.Button.with_label ("Close");




            var home_buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
            home_buttons.homogeneous = true;
            home_buttons.pack_start (cancel_bt, false, true, 0);
            home_buttons.pack_end (start_bt, false, true, 0);
            home_buttons.margin_top = 24;
            



        backup_screen.attach (source_grid, 0, 0, 1, 1);
backup_screen.attach (home_buttons, 0, 3, 1, 1);
        //backup_screen.attach (touchpad_section, 0, 2, 1, 1);
        backup_screen.show_all ();




        // Create the device list
        var source_list = new Granite.Widgets.SourceList ();
        var device_category = new Granite.Widgets.SourceList.ExpandableItem ("Backups Location:");
        device_category.expanded = true;
        var player1_item = new Granite.Widgets.SourceList.Item ("Filesystem");
        player1_item.icon = new ThemedIcon.with_default_fallbacks("drive-harddisk-system");
        device_category.add (player1_item);
        source_list.root.add (device_category);

        // Create the restore welcome page
	    var restore_screen = new Granite.Widgets.Welcome ("Restore Your System", "Select the drive containing your backups on the left.");

        // Create and add pane (split screen)
        var pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        pane.position = 200;
        pane.pack1 (source_list, false, false);
        //pane.pack2 (restore_screen, true, false);





var snapshots_list = new Gtk.TreeView();


var listmodel = new Gtk.ListStore (4, typeof (string), typeof (string), typeof (string), typeof (string));

snapshots_list.set_model (listmodel);

        snapshots_list.insert_column_with_attributes (-1, "Date", new CellRendererText (), "text", 0);
        snapshots_list.insert_column_with_attributes (-1, "Description", new CellRendererText (), "text", 1);

        TreeIter iter;
        listmodel.append (out iter);
        listmodel.set (iter, 0, "18/12/17 19:00", 1, "Perfect state");

        listmodel.append (out iter);
        listmodel.set (iter, 0, "18/12/17 19:30", 1, "Just installed android studio");



pane.pack2 (snapshots_list, true, false);




        //
        var stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.NONE;
        stack.add_titled(backup_screen, "backup_screen", "Backup");
        stack.add_titled(pane, "restore_screen", "Restore");
        this.add (stack);

        // Backup or Restore mode buttons
        var view_mode = new Gtk.StackSwitcher();
        view_mode.stack = stack;
        view_mode.valign = Gtk.Align.CENTER;
        view_mode.homogeneous = true;
        header.set_custom_title(view_mode);


    }

    public void addSnapshot(int no, string date, string name)
    {

    }

    public void removeSnapshot(int no, string date, string name)
    {

    }
}

}
