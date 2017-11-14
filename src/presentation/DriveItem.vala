public class DriveItem : Gtk.ListBoxRow {
    private string uuid;
    private Gtk.Grid row_grid;
    private Gtk.Image row_image;
    private Gtk.Label row_title;
    private Gtk.Label row_description;

    public DriveItem (string id, string drive_label, string drive_path, string description) 
    {
        uuid = id;

        row_grid = new Gtk.Grid ();
        row_grid.margin = 6;
        row_grid.column_spacing = 6;
        this.add (row_grid);

        try
        {

            row_image = new Gtk.Image.from_gicon (Icon.new_for_string ("drive-harddisk"), Gtk.IconSize.DND);
        }
        catch (Error e)
        {

        }
        row_image.pixel_size = 32;
        row_grid.attach (row_image, 0, 0, 1, 2);

        if (drive_label == "" || drive_label == null)
        {
            
        }

        row_title = new Gtk.Label (drive_label);
        row_title.get_style_context ().add_class ("h3");
        row_title.ellipsize = Pango.EllipsizeMode.END;
        row_title.halign = Gtk.Align.START;
        row_title.valign = Gtk.Align.END;
        row_grid.attach (row_title, 1, 0, 1, 1);

        row_description = new Gtk.Label (null);
        row_description.set_label (@"<span font_size=\"small\">$description</span>");
        row_description.use_markup = true;
        row_description.ellipsize = Pango.EllipsizeMode.END;
        row_description.halign = Gtk.Align.START;
        row_description.valign = Gtk.Align.START;
        row_grid.attach (row_description, 1, 1, 1, 1);
    }

    public string get_name()
    {
        return row_title.label;
    }

    public string get_id()
    {
        return uuid;
    }

}