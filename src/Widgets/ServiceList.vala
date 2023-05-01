// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC. (http://launchpad.net/switchboard-plug-security-privacy)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class ServiceList : Gtk.ListBox {
    private ServiceItem housekeeping_item;
    Gee.HashMap<string, ServiceItem> services = new Gee.HashMap<string, ServiceItem> ();

    public ServiceList () {
        Object (activate_on_single_click: true,
                selection_mode: Gtk.SelectionMode.SINGLE);
    }

    construct {
        var privacy_item = new ServiceItem ("document-open-recent", "tracking", _("History"));
        var lock_item = new ServiceItem ("system-lock-screen", "locking", _("Locking"));
        var firewall_item = new ServiceItem ("network-firewall", "firewall", _("Firewall"));
        housekeeping_item = new ServiceItem (
            "preferences-system-privacy-housekeeping",
            "housekeeping",
            _("Housekeeping")
        );

        add_service (privacy_item);
        add_service (lock_item);
        add_service (firewall_item);
        add_service (housekeeping_item);

        SecurityPrivacy.firewall.status_switch.notify["active"].connect (() => {
            update_service_status (firewall_item, SecurityPrivacy.firewall.status_switch.active);
        });

        update_service_status (privacy_item, SecurityPrivacy.tracking.status_switch.active);

        SecurityPrivacy.housekeeping.notify["status-type"].connect (() => {
            update_housekeeping_status ();
        });

        update_housekeeping_status ();

        SecurityPrivacy.tracking.status_switch.notify["active"].connect (() => {
            update_service_status (privacy_item, SecurityPrivacy.tracking.status_switch.active);
        });

        if (SecurityPrivacy.LocationPanel.location_agent_installed ()) {
            var location_item = new ServiceItem ("preferences-system-privacy-location", "location", _("Location Services"));
            add_service (location_item);
            update_service_status (location_item, SecurityPrivacy.location.status_switch.active);

            SecurityPrivacy.location.status_switch.notify["active"].connect (() => {
                update_service_status (location_item, SecurityPrivacy.location.status_switch.active);
            });
        }
    }

    private void update_service_status (ServiceItem service_item, bool service_status) {
        if (service_status) {
            service_item.status = ServiceItem.Status.ENABLED;
        } else {
            service_item.status = ServiceItem.Status.DISABLED;
        }
    }

    private void update_housekeeping_status () {
        if (SecurityPrivacy.housekeeping.status_type == Granite.SettingsPage.StatusType.SUCCESS) {
            housekeeping_item.status = ServiceItem.Status.ENABLED;
        } else if (SecurityPrivacy.housekeeping.status_type == Granite.SettingsPage.StatusType.WARNING) {
            housekeeping_item.status = ServiceItem.Status.PARTIAL;
        } else if (SecurityPrivacy.housekeeping.status_type == Granite.SettingsPage.StatusType.OFFLINE) {
            housekeeping_item.status = ServiceItem.Status.DISABLED;
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
