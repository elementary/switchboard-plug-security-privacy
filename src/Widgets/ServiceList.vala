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

        if (location_agent_installed ()) {
            var location_item = new ServiceItem ("find-location", "location", _("Location"));
            add (location_item);
        }      
    }

    private bool location_agent_installed () {
        var schemas = GLib.SettingsSchemaSource.get_default ();
        if (schemas.lookup ("org.pantheon.agent-geoclue2", true) != null) {
            return true;
        }

        return false;
    }
}
