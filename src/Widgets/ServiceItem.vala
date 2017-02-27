public class ServiceItem: Gtk.ListBoxRow {
    public enum Status {
        ENABLED,
        DISABLED
    }

    public Status status {
        set {
            switch (value) {
                case Status.ENABLED:
                    status_icon.icon_name = "user-available";
                    status_label.label = _("Enabled");
                    break;
                case Status.DISABLED:
                    status_icon.icon_name = "user-offline";
                    status_label.label = _("Disabled");
                    break;
            }
            status_label.no_show_all = false;
            status_label.label = "<span font_size='small'>" + status_label.label + "</span>";
        }
    }

    private Gtk.Image status_icon;
    private Gtk.Label status_label;

    public string icon_name { get; construct; }
    public string label { get; construct; }
    public string title { get; construct; }

    public ServiceItem (string icon_name, string title, string label) {
        Object (icon_name: icon_name,
                label: label,
                title: title);
    }

    construct {
        var icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DND);

        var title_label = new Gtk.Label (label);
        title_label.get_style_context ().add_class ("h3");
        title_label.ellipsize = Pango.EllipsizeMode.END;
        title_label.xalign = 0;

        status_icon = new Gtk.Image ();
        status_icon.halign = Gtk.Align.END;
        status_icon.valign = Gtk.Align.END;

        status_label = new Gtk.Label (null);
        status_label.no_show_all = true;
        status_label.use_markup = true;
        status_label.ellipsize = Pango.EllipsizeMode.END;
        status_label.xalign = 0;

        var overlay = new Gtk.Overlay ();
        overlay.width_request = 38;
        overlay.add (icon);
        overlay.add_overlay (status_icon);

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 6;
        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (title_label, 1, 0, 1, 1);
        grid.attach (status_label, 1, 1, 1, 1);

        add (grid);
    }
}
