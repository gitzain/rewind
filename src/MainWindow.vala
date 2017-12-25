using Gtk;

namespace RewindUtil {



public class MainWindow : Window {

    private Gtk.HeaderBar header;
    private Gtk.Paned pane;
    private Granite.Widgets.Welcome backup_screen;
    private Granite.Widgets.Welcome restore_screen; 
    private Granite.Widgets.SourceList source_list;
    private Gtk.TreeView snapshots_list;
    private Gtk.ListStore listmodel;
    private Gtk.Stack stack;
    private Gtk.StackSwitcher view_mode; 
    


    public MainWindow()
    {
        // Setup the window
        this.destroy.connect(Gtk.main_quit);
        this.set_default_size (1000, 675);

        // Create and add header to window
        header = new Gtk.HeaderBar();
        header.set_show_close_button(true);
        header.set_title("Rewind");
        this.set_titlebar(header);

        // Create the backup welcome page
	    backup_screen = new Granite.Widgets.Welcome ("Backup Your System", "Take a snapshot.");
        backup_screen.append ("document-new", "Take Snapshot", "A snapshot is a point in time backup of your system");

        // Create the restore device list
        source_list = new Granite.Widgets.SourceList ();
        var device_category = new Granite.Widgets.SourceList.ExpandableItem ("Backups Location:");
        device_category.expanded = true;
        var player1_item = new Granite.Widgets.SourceList.Item ("Filesystem");
        player1_item.icon = new ThemedIcon.with_default_fallbacks("drive-harddisk-system");
        device_category.add (player1_item);
        source_list.root.add (device_category);

        // Create the restore welcome page
	    restore_screen = new Granite.Widgets.Welcome ("Restore Your System", "Select the drive containing your backups on the left.");

        // Create and add pane (split screen)
        pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        pane.position = 200;
        pane.pack1 (source_list, false, false);
        //pane.pack2 (restore_screen, true, false);







        snapshots_list = new Gtk.TreeView();
        listmodel = new Gtk.ListStore (4, typeof (string), typeof (string), typeof (string), typeof (string));
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
        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.NONE;
        stack.add_titled(backup_screen, "backup_screen", "Backup");
        stack.add_titled(pane, "restore_screen", "Restore");
        this.add (stack);

        // Backup or Restore mode buttons
        view_mode = new Gtk.StackSwitcher();
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
