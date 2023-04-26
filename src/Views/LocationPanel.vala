/*-
 * Copyright (c) 2017-2023 elementary, Inc. (https://elementary.io)
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

    private Granite.Widgets.AlertView alert;
    private Gtk.ScrolledWindow scrolled;
    private Gtk.Stack disabled_stack;
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
        var placeholder = new Granite.Widgets.AlertView (
            _("No Apps Are Using Location Services"),
            _("When apps are installed that use location services they will automatically appear here."),
            ""
        );
        placeholder.show_all ();

        // var liststore = new ListStore (typeof (Flatpak.InstalledRef));

        var listbox = new Gtk.ListBox () {
            activate_on_single_click = true
        };
        // listbox.bind_model (liststore, create_widget_func);
        listbox.set_placeholder (placeholder);

        scrolled = new Gtk.ScrolledWindow (null, null) {
            hexpand = true,
            vexpand = true,
            child = listbox,
            visible = true
        };

        alert = new Granite.Widgets.AlertView (
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
        disabled_stack.add (alert);
        disabled_stack.add (scrolled);

        var frame = new Gtk.Frame (null);
        frame.add (disabled_stack);

        content_area.add (frame);

        listbox.row_activated.connect ((row) => {
            ((LocationRow) row).on_active_changed ();
        });

        var location_settings = new Settings ("org.gnome.system.location");
        location_settings.bind ("enabled", status_switch, "active", SettingsBindFlags.DEFAULT);

        update_status ();

        location_settings.changed["enabled"].connect (() => {
            update_status ();
        });

        init_interfaces.begin ((obj, res) => {
            init_interfaces.end (res);

            HashTable<string, Variant> results;
            Variant data;

            try {
                permission_store.lookup (PERMISSIONS_TABLE, PERMISSIONS_ID, out results, out data);
            } catch (Error e) {
                critical (e.message);
            }

            // foreach (var app in permissions) {
            //     string app_id = app.get_child_value (0).get_string ();
            //     bool authed = app.get_child_value (1).get_variant ().get_child_value (0).get_boolean ();
            //     var app_info = new DesktopAppInfo (app_id + ".desktop");

            //     var app_row = new LocationRow (app_info, false);

            //     // app_row.active_changed.connect ((active) => {
            //     //     uint32 level = get_app_level (app_id);
            //     //     save_app_settings (app_id, active, level);
            //     // });

            //     listbox.add (app_row);
            // }
        });
    }

    private async void init_interfaces () {
        try {
            permission_store = yield Bus.get_proxy (BusType.SESSION, "org.freedesktop.impl.portal.PermissionStore", "/org/freedesktop/impl/portal/PermissionStore");
        } catch (IOError e) {
            critical ("Unable to connect to GNOME session interface: %s", e.message);
        }
    }

    private void update_status () {
        if (status_switch.active) {
            disabled_stack.visible_child = scrolled;

            status_type = Granite.SettingsPage.StatusType.SUCCESS;
            status = _("Enabled");
        } else {
            disabled_stack.visible_child = alert;

            status_type = Granite.SettingsPage.StatusType.OFFLINE;
            status = _("Disabled");
        }
    }

    // private Gtk.Widget create_widget_func (Object object) {
    //     var appinfo = new GLib.DesktopAppInfo (id + ".desktop");

    //     var image = new Gtk.Image.from_gicon (appinfo.get_icon (), Gtk.IconSize.DND) {
    //         pixel_size = 32
    //     };

    //     var app_name = new Gtk.Label (appinfo.get_display_name ()) {
    //         ellipsize = Pango.EllipsizeMode.END,
    //         xalign = 0
    //     };
    //     app_name.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

    //     var app_comment = new Gtk.Label (appinfo.get_description ()) {
    //         ellipsize = Pango.EllipsizeMode.END,
    //         xalign = 0
    //     };
    //     app_comment.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

    //     var grid = new Gtk.Grid () {
    //         column_spacing = 12,
    //         margin_top = 6,
    //         margin_end = 12,
    //         margin_bottom = 6,
    //         margin_start = 10 // Account for icon position on the canvas
    //     };
    //     grid.attach (image, 0, 0, 1, 2);
    //     grid.attach (app_name, 1, 0);
    //     grid.attach (app_comment, 1, 1);
    //     grid.show_all ();

    //     return grid;
    // }

    // private void save_app_settings (string desktop_id, bool authorized, uint32 accuracy_level) {
    //     Variant[] tuple_vals = new Variant[2];
    //     tuple_vals[0] = new Variant.boolean (authorized);
    //     tuple_vals[1] = new Variant.uint32 (accuracy_level);
    //     remembered_apps_dict.insert_value (desktop_id, new Variant.tuple (tuple_vals));
    //     agent_settings.set_value ("remembered-apps", remembered_apps_dict.end ());
    //     load_remembered_apps ();
    // }

    // private uint32 get_app_level (string desktop_id) {
    //     return remembered_apps.lookup_value (desktop_id, GLib.VariantType.TUPLE).get_child_value (1).get_uint32 ();
    // }

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
            active_switch = new Gtk.Switch () {
                active = authed,
                halign = Gtk.Align.END,
                hexpand = true,
                tooltip_text = _("Allow %s to use location services".printf (app_info.get_display_name ())),
                valign = Gtk.Align.CENTER
            };

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
