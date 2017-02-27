public class ServiceList : Gtk.ListBox {
    public ServiceList () {
        Object (activate_on_single_click: true,
                selection_mode: Gtk.SelectionMode.SINGLE);
    }

    construct {
        var privacy_item = new ServiceItem ("document-open-recent", "tracking", _("Privacy"));
        var lock_item = new ServiceItem ("system-lock-screen", "locking", _("Locking"));
        var firewall_item = new ServiceItem ("network-firewall", "firewall", _("Firewall"));

        add (privacy_item);
        add (lock_item);
        add (firewall_item);

        SecurityPrivacy.firewall.status_switch.notify["active"].connect (() => {
            if (SecurityPrivacy.firewall.status_switch.active) {
                firewall_item.status = ServiceItem.Status.ENABLED;
            } else {
                firewall_item.status = ServiceItem.Status.DISABLED;
            }
        });
    }
}
