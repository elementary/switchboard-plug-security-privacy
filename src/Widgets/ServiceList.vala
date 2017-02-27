public class ServiceList : Gtk.ListBox {
    public ServiceList () {
        Object (activate_on_single_click: true,
                selection_mode: Gtk.SelectionMode.SINGLE);
    }

    ServiceItem? location_item;

    construct {
        var privacy_item = new ServiceItem ("document-open-recent", "tracking", _("History"));
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

        if (location_agent_installed ()) {
            location_item = new ServiceItem ("find-location", "location", _("Location"));
            add (location_item);
            update_location_status ();
            SecurityPrivacy.location.status_switch.notify["active"].connect (() => {
                update_location_status ();
            });
        }      
    }

    private void update_location_status () {
        if (SecurityPrivacy.location.status_switch.active) {
            location_item.status = ServiceItem.Status.ENABLED;
        } else {
            location_item.status = ServiceItem.Status.DISABLED;
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
