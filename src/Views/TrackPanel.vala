// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014-2018 elementary LLC. (https://elementary.io)
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
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public class SecurityPrivacy.TrackPanel : Switchboard.SettingsPage {
    public static SecurityPrivacy.Blacklist blacklist { get; private set; }

    public TrackPanel () {
        Object (
            activatable: true,
            description: _("%s can store local usage data to provide extra functionality like offering recently-used files and more relevant local search. Regardless of this setting, usage data is never transmitted off of this device or to third parties.").printf (get_operating_system_name ()),
            icon: new ThemedIcon ("document-open-recent"),
            title: _("History")
        );
    }

    static construct {
        blacklist = new Blacklist ();
    }

    construct {
        var description = ("%s %s\n\n%s".printf (
            _("%s won't retain any further usage data.").printf (get_operating_system_name ()),
            _("The additional functionality that this data provides will be affected."),
            _("This may not prevent apps from recording their own usage data, such as browser history.")
        ));

        var alert = new Granite.Placeholder (_("History Is Disabled")) {
            description = description
        };

        status_switch.active = true;

        var include_treeview = new IncludeTreeView ();
        var exclude_treeview = new ExcludeTreeView ();

        var content_box = new Gtk.Box (HORIZONTAL, 12);
        content_box.append (include_treeview);
        content_box.append (exclude_treeview);

        var stack = new Gtk.Stack ();
        stack.add_child (content_box);
        stack.add_child (alert);

        child = stack;
        show_end_title_buttons = true;

        var clear_button = add_button (_("Clear History…"));

        status_switch.notify["active"].connect (() => {
            bool privacy_mode = !status_switch.active;
            include_treeview.visible = !privacy_mode;
            exclude_treeview.visible = !privacy_mode;

            if (privacy_mode) {
                stack.visible_child = alert;
            } else {
                stack.visible_child = content_box;
            }

            if (privacy_mode != blacklist.get_incognito ()) {
                blacklist.set_incognito (privacy_mode);

                var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");
                privacy_settings.set_boolean ("remember-recent-files", !privacy_mode);
                privacy_settings.set_boolean ("remember-app-usage", !privacy_mode);
            }

            update_status_switch ();
        });

        status_switch.active = !blacklist.get_incognito ();

        update_status_switch ();

        clear_button.clicked.connect (() => {
            var clear_dialog = new Widgets.ClearUsageDialog () {
                modal = true,
                transient_for = (Gtk.Window) get_root ()
            };
            clear_dialog.present ();
        });
    }

    private static string get_operating_system_name () {
        return Environment.get_os_info (GLib.OsInfoKey.NAME) ?? _("Your system");
    }

    private void update_status_switch () {
        if (status_switch.active) {
            status_type = SUCCESS;
            status = _("Enabled");
        } else {
            warning ("Trying to set offline");
            status_type = OFFLINE;
            status = _("Disabled");
        }
    }
}
