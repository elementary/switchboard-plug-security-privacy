// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017-2018 elementary LLC. (https://elementary.io)
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
    private const string LOCATION_AGENT_ID = "io.elementary.desktop.agent-geoclue2";

    private GLib.Settings location_settings;
    private Gtk.Stack disabled_stack;
    private ListStore liststore;

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

        var listbox = new Gtk.ListBox () {
            activate_on_single_click = true
        };
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

        location_settings = new GLib.Settings (LOCATION_AGENT_ID);
        location_settings.bind ("location-enabled", status_switch, "active", SettingsBindFlags.DEFAULT);

        update_status ();

        status_switch.notify["active"].connect (() => {
            update_status ();
        });

        listbox.row_activated.connect ((row) => {
            ((LocationRow) row).on_active_changed ();
        });

        load_remembered_apps ();

        location_settings.changed["remembered-apps"].connect (() => {
            load_remembered_apps ();
        });
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

        app_row.notify["authed"].connect (() => {
            var tuple = new Variant ("(bu)", app_row.authed, (uint32) app_permission.level);

            var remembered_apps_dict = new VariantDict (location_settings.get_value ("remembered-apps"));
            remembered_apps_dict.insert_value (app_permission.id, tuple);

            location_settings.set_value ("remembered-apps", remembered_apps_dict.end ());
        });

        return app_row;
    }

    private void load_remembered_apps () {
        liststore.remove_all ();

        foreach (var app in location_settings.get_value ("remembered-apps")) {
            var app_permission = new AppPermission (
                app.get_child_value (0).get_string (),
                app.get_child_value (1).get_variant ().get_child_value (0).get_boolean (),
                app.get_child_value (1).get_variant ().get_child_value (1).get_uint32 ()
            );

            // Don't add uninstalled apps
            var app_info = new GLib.DesktopAppInfo (app_permission.id + ".desktop");
            if (app_info != null) {
                liststore.append (app_permission);
            }
        }
    }

    public static bool location_agent_installed () {
        var schemas = GLib.SettingsSchemaSource.get_default ();
        if (schemas.lookup (LOCATION_AGENT_ID, true) != null) {
            return true;
        }

        return false;
    }

    private class AppPermission : Object {
        public string id { get; construct; }
        public bool authed { get; construct; }
        public uint32 level { get; construct;}

        public AppPermission (string id, bool authed, uint32 level) {
            Object (
                id: id,
                authed: authed,
                level: level
            );
        }
    }

    private class LocationRow : AppRow {
        public bool authed { get; construct set; }

        public LocationRow (AppPermission permission) {
            Object (
                app_info: new GLib.DesktopAppInfo (permission.id + ".desktop"),
                authed: permission.authed
            );
        }

        construct {
            var active_switch = new Gtk.Switch () {
                active = authed,
                halign = Gtk.Align.END,
                hexpand = true,
                tooltip_text = _("Allow %s to use location services".printf (app_info.get_display_name ())),
                valign = Gtk.Align.CENTER
            };

            main_grid.margin_top = 6;
            main_grid.margin_end = 6;
            main_grid.margin_bottom = 6;
            main_grid.margin_start = 6;
            main_grid.attach (active_switch, 2, 0, 1, 2);
            show_all ();

            bind_property ("authed", active_switch, "active", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }

        public void on_active_changed () {
            authed = !authed;
        }
    }
}
