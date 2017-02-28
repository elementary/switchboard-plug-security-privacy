public class ServiceList : Gtk.ListBox {
    Gee.HashMap<string, ServiceItem> services = new Gee.HashMap<string, ServiceItem> ();

    public ServiceList () {
        Object (activate_on_single_click: true,
                selection_mode: Gtk.SelectionMode.SINGLE);
    }

    ServiceItem? location_item;

    construct {
        var privacy_item = new ServiceItem ("document-open-recent", "tracking", _("History"));
        var lock_item = new ServiceItem ("system-lock-screen", "locking", _("Locking"));
        var firewall_item = new ServiceItem ("network-firewall", "firewall", _("Firewall"));

        add_service (privacy_item);
        add_service (lock_item);
        add_service (firewall_item);

        SecurityPrivacy.firewall.status_switch.notify["active"].connect (() => {
            if (SecurityPrivacy.firewall.status_switch.active) {
                firewall_item.status = ServiceItem.Status.ENABLED;
            } else {
                firewall_item.status = ServiceItem.Status.DISABLED;
            }
        });

        if (SecurityPrivacy.LocationPanel.location_agent_installed ()) {
            location_item = new ServiceItem ("find-location", "location", _("Location Services"));
            add_service (location_item);
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

    public void add_service (ServiceItem service) {
        add (service);
        services.set (service.title, service);
    }

    public void select_service_name (string name) {
        select_row (services[name]);
    }
}
