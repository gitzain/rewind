using Gtk;

int main (string[] args) {
    Gtk.init (ref args);

    // Create snapshop button
    var icon_create_snapshot = new Image.from_icon_name("document-new", IconSize.SMALL_TOOLBAR);
    var button_create_snapshot = new ToolButton(icon_create_snapshot, "Create Snapshot");
    button_create_snapshot.is_important = true;

    // Restore button
    var icon_restore = new Image.from_icon_name("document-revert", IconSize.SMALL_TOOLBAR);
    var button_restore = new ToolButton(icon_restore, "Restore");
    button_restore.is_important = true;

    //appmenu
    var new_view_menuitem = new Gtk.MenuItem.with_label ("Add New View");
    //new_view_menuitem.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_NEW_VIEW;

    var remove_view_menuitem = new Gtk.MenuItem.with_label ("Remove Current View");
    //remove_view_menuitem.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_REMOVE_VIEW;

    var preferences_menuitem = new Gtk.MenuItem.with_label ("Preferences");
    //preferences_menuitem.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_PREFERENCES;

    // Settings Cog
    var menu = new Gtk.Menu();
    menu.add (new_view_menuitem);
    menu.add (remove_view_menuitem);
    menu.add (new Gtk.SeparatorMenuItem ());
    menu.add (preferences_menuitem);
    menu.show_all ();

    var app_menu = new Gtk.MenuButton ();
    app_menu.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
    app_menu.tooltip_text = "Menu";
    app_menu.popup = menu;





    var header = new Gtk.HeaderBar();
    header.set_show_close_button(true);
    header.set_title("Rewind");
    header.pack_start(button_create_snapshot);
    header.pack_start(button_restore);
header.pack_end(app_menu);

	var welcome_screen = new Granite.Widgets.Welcome ("Backup Your System", "Take your first snapshot.");
    welcome_screen.append ("document-new", "Take Snapshot", "A snapshot is a point in time backup of your system");

    var window = new Gtk.Window();
    window.set_titlebar(header);
    window.destroy.connect(Gtk.main_quit);
    window.set_default_size (1200, 800);
    window.add(welcome_screen);








    window.show_all();

    Gtk.main ();
    return 0;
}

