/*-
 * Copyright 2017-2023 elementary, Inc. (https://elementary.io)
 * Copyright (C) 2017 David Hewitt <davidmhewitt@gmail.com>   
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Authored by: David Hewitt <davidmhewitt@gmail.com>
 */

public class SecurityPrivacy.LocationPanel : Granite.SimpleSettingsPage {
    private const string PERMISSIONS_TABLE = "location";
    private const string PERMISSIONS_ID = "location";

    private Gtk.Stack disabled_stack;
    private ListStore liststore;
    private PermissionStore permission_store;

    public LocationPanel () {
        Object (
            activatable: true,
            description: _("Allow the apps below to determine your location"),
            icon_name: "find-location",
            title: _("Location Services")
        );
    }

    construct {
        liststore = new ListStore (typeof (AppPermission));

        var placeholder = new Granite.Widgets.AlertView (
            _("No Apps Are Using Location Services"),
            _("When apps are installed that use location services they will automatically appear here."),
            ""
        );
        placeholder.show_all ();

        var listbox = new Gtk.ListBox ();
        listbox.bind_model (liststore, create_widget_func);
        listbox.set_placeholder (placeholder);

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            child = listbox,
            hexpand = true,
            vexpand = true,
            visible = true
        };

        var alert = new Granite.Widgets.AlertView (
            _("Location Services Are Disabled"),
            "%s\n%s\n%s".printf (
                _("While location services are disabled, location requests from apps will be automatically rejected."),
                _("The additional functionality that location access provides in those apps will be affected."),
                _("This will not prevent apps from trying to determine your location based on IP address.")
            ),
            ""
        );
        alert.visible = true;

        disabled_stack = new Gtk.Stack ();
        disabled_stack.add_named (alert, "disabled");
        disabled_stack.add_named (scrolled, "enabled");

        var frame = new Gtk.Frame (null) {
            child = disabled_stack
        };

        content_area.add (frame);

        var location_settings = new Settings ("org.gnome.system.location");
        location_settings.bind ("enabled", status_switch, "active", SettingsBindFlags.DEFAULT);

        update_status ();

        status_switch.notify["active"].connect (() => {
            update_status ();
        });

        init_interfaces.begin ((obj, res) => {
            init_interfaces.end (res);
            load_permissions ();
        });
    }

    private async void init_interfaces () {
        try {
            permission_store = yield Bus.get_proxy (BusType.SESSION, "org.freedesktop.impl.portal.PermissionStore", "/org/freedesktop/impl/portal/PermissionStore");
            permission_store.changed.connect (load_permissions);
        } catch (IOError e) {
            critical ("Unable to connect to GNOME session interface: %s", e.message);
        }
    }

    private void update_status () {
        if (status_switch.active) {
            disabled_stack.visible_child_name = "enabled";

            status_type = Granite.SettingsPage.StatusType.SUCCESS;
            status = _("Enabled");
        } else {
            disabled_stack.visible_child_name = "disabled";

            status_type = Granite.SettingsPage.StatusType.OFFLINE;
            status = _("Disabled");
        }
    }

    private Gtk.Widget create_widget_func (Object object) {
        var app_permission = (AppPermission) object;
        var app_row = new LocationRow (app_permission);
        app_row.notify["level"].connect (() => {
            string[] permissions = {app_row.level, app_row.timestamp};
            try {
                permission_store.set_permission (PERMISSIONS_TABLE, true, PERMISSIONS_ID, app_permission.id, permissions);
            } catch (Error e) {
                critical (e.message);
            }

        });

        return app_row;
    }

    private void load_permissions () {
        liststore.remove_all ();

        try {
            Variant permissions, data;
            permission_store.lookup (PERMISSIONS_TABLE, PERMISSIONS_ID, out permissions, out data);

            string app_id = "";
            string[] app_permissions = {""};
            var iter = permissions.iterator ();
            while (iter.next ("{s^as}", ref app_id, ref app_permissions)) {
                var app_permission = new AppPermission (
                    app_id,
                    app_permissions[0],
                    app_permissions[1]
                );

                liststore.append (app_permission);
            }
        } catch (Error e) {
            critical (e.message);
        }
    }

    private class AppPermission : Object {
        public string id { get; construct; }
        public string level { get; construct; }
        public string timestamp { get; construct;}

        public AppPermission (string id, string level, string timestamp) {
            Object (
                id: id,
                level: level,
                timestamp: timestamp
            );
        }
    }

    private class LocationRow : AppRow {
        public string level { get; construct set; }
        public string timestamp { get; construct;}

        public LocationRow (AppPermission permission) {
            Object (
                app_info: new GLib.DesktopAppInfo (permission.id + ".desktop"),
                level: permission.level,
                timestamp: permission.timestamp
            );
        }

        construct {
            var level_combo = new Gtk.ComboBoxText () {
                halign = Gtk.Align.END,
                hexpand = true,
                valign = Gtk.Align.CENTER
            };
            level_combo.append ("NONE", _("None"));
            level_combo.append ("COUNTRY", _("Country"));
            level_combo.append ("CITY", _("City"));
            level_combo.append ("NEIGHBORHOOD", _("Neighborhood"));
            level_combo.append ("STREET", _("Street"));
            level_combo.append ("EXACT", _("Exact"));

            var timestamp_label = new Gtk.Label (
                Granite.DateTime.get_relative_datetime (new DateTime.from_unix_utc (int64.parse (timestamp)))
            );
            timestamp_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

            main_grid.margin_top = 6;
            main_grid.margin_end = 6;
            main_grid.margin_bottom = 6;
            main_grid.margin_start = 6;
            main_grid.remove (app_comment);
            main_grid.attach (timestamp_label, 1, 1);
            main_grid.attach (level_combo, 2, 0, 1, 2);
            show_all ();

            bind_property ("level", level_combo, "active-id", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }
    }
}
