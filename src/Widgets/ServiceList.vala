public class ServiceList : Gtk.ListBox {
    public ServiceList () {
        Object (activate_on_single_click: true,
                selection_mode: Gtk.SelectionMode.SINGLE);
    }

    construct {
        var privacy_item = new ServiceItem ("view-private", "tracking", _("Privacy"));
        var lock_item = new ServiceItem ("system-lock-screen", "locking", _("Locking"));
        var firewall_item = new ServiceItem ("preferences-system-network", "firewall", _("Firewall"));

        add (privacy_item);
        add (lock_item);
        add (firewall_item);
    }
}
