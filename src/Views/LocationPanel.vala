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
    private Variant remembered_apps;
    private VariantDict remembered_apps_dict;
    private Gtk.ListBox listbox;
    private Gtk.Stack disabled_stack;

    private enum Columns {
        AUTHORIZED,
        NAME,
        ICON,
        APP_ID,
        N_COLUMNS
    }

    public LocationPanel () {
        Object (
            activatable: true,
            description: _("Allow the apps below to determine your location"),
            icon_name: "preferences-system-privacy-location",
            title: _("Location Services")
        );
    }

    construct {
        location_settings = new GLib.Settings (LOCATION_AGENT_ID);

        var placeholder = new Granite.Widgets.AlertView (
            _("No Apps Are Using Location Services"),
            _("When apps are installed that use location services they will automatically appear here."),
            ""
        );
        placeholder.show_all ();

        listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.set_placeholder (placeholder);

        populate_app_listbox ();

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.visible = true;
        scrolled.add (listbox);

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

        var frame = new Gtk.Frame (null);
        frame.add (disabled_stack);

        content_area.add (frame);

        location_settings.bind ("location-enabled", status_switch, "active", SettingsBindFlags.DEFAULT);

        update_status ();

        status_switch.notify["active"].connect (() => {
            update_status ();
        });

        listbox.row_activated.connect ((row) => {
            ((LocationRow) row).on_active_changed ();
        });

        location_settings.changed.connect ((key) => {
            populate_app_listbox ();
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

    private void populate_app_listbox () {
        load_remembered_apps ();

        foreach (var row in listbox.get_children ()) {
            listbox.remove (row);
        }

        foreach (var app in remembered_apps) {
            string app_id = app.get_child_value (0).get_string ();
            bool authed = app.get_child_value (1).get_variant ().get_child_value (0).get_boolean ();
            var app_info = new DesktopAppInfo (app_id + ".desktop");

            var app_row = new LocationRow (app_info, authed);

            app_row.active_changed.connect ((active) => {
                uint32 level = get_app_level (app_id);
                save_app_settings (app_id, active, level);
            });

            listbox.add (app_row);
        }
    }

    private void load_remembered_apps () {
        remembered_apps = location_settings.get_value ("remembered-apps");
        remembered_apps_dict = new VariantDict (location_settings.get_value ("remembered-apps"));
    }

    private void save_app_settings (string desktop_id, bool authorized, uint32 accuracy_level) {
        Variant[] tuple_vals = new Variant[2];
        tuple_vals[0] = new Variant.boolean (authorized);
        tuple_vals[1] = new Variant.uint32 (accuracy_level);
        remembered_apps_dict.insert_value (desktop_id, new Variant.tuple (tuple_vals));
        location_settings.set_value ("remembered-apps", remembered_apps_dict.end ());
        load_remembered_apps ();
    }

    private uint32 get_app_level (string desktop_id) {
        return remembered_apps.lookup_value (desktop_id, GLib.VariantType.TUPLE).get_child_value (1).get_uint32 ();
    }

    public static bool location_agent_installed () {
        var schemas = GLib.SettingsSchemaSource.get_default ();
        if (schemas.lookup (LOCATION_AGENT_ID, true) != null) {
            return true;
        }

        return false;
    }

    private class LocationRow : AppRow {
        public signal void active_changed (bool active);
        public bool authed { get; construct; }
        private Gtk.Switch active_switch;

        public LocationRow (DesktopAppInfo app_info, bool authed) {
            Object (
                app_info: app_info,
                authed: authed
            );
        }

        construct {
            active_switch = new Gtk.Switch ();
            active_switch.halign = Gtk.Align.END;
            active_switch.hexpand = true;
            active_switch.tooltip_text = _("Allow %s to use location services".printf (app_info.get_display_name ()));
            active_switch.valign = Gtk.Align.CENTER;
            active_switch.active = authed;

            main_grid.margin = 6;
            main_grid.attach (active_switch, 2, 0, 1, 2);
            show_all ();

            activate.connect (() => {
                active_switch.active = false;
            });

            active_switch.notify ["active"].connect (() => {
                active_changed (active_switch.active);
            });
        }

        public void on_active_changed () {
            active_switch.activate ();
        }
    }
}
