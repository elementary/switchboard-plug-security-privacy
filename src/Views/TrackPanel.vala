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

public class SecurityPrivacy.TrackPanel : Granite.SimpleSettingsPage {
    private Widgets.ClearUsagePopover remove_popover;

    public TrackPanel () {
        Object (
            activatable: true,
            description: _("%s can store local usage data to provide extra functionality like offering recently-used files and more relevant local search. Regardless of this setting, usage data is never transmitted off of this device or to third parties.").printf (get_operating_system_name ()),
            icon_name: "document-open-recent",
            title: _("History")
        );
    }

    construct {
        var description = ("%s %s\n\n%s".printf (
            _("%s won't retain any usage data.").printf (get_operating_system_name ()),
            _("The additional functionality that this data provides will be affected."),
            _("This may not prevent apps from recording their own usage data, such as browser history.")
        ));

        var alert = new Granite.Widgets.AlertView (_("History Is Disabled"), description, "");
        alert.show_all ();

        var description_frame = new Gtk.Frame (null);
        description_frame.no_show_all = true;
        description_frame.add (alert);

        status_switch.active = true;

        var clear_data = new Gtk.ToggleButton.with_label (_("Clear History…"));
        clear_data.notify["active"].connect (() => {
            if (clear_data.active == false) {
                remove_popover.hide ();
            } else {
                remove_popover.show_all ();
            }
        });

        remove_popover = new Widgets.ClearUsagePopover (clear_data);
        remove_popover.closed.connect (() => {
            clear_data.active = false;
        });

        var include_treeview = new IncludeTreeView ();
        var exclude_treeview = new ExcludeTreeView ();

        content_area.attach (description_frame, 0, 1, 2, 1);
        content_area.attach (include_treeview, 0, 1, 1, 1);
        content_area.attach (exclude_treeview, 1, 1, 1, 1);

        action_area.add (clear_data);

        status_switch.notify["active"].connect (() => {
            bool privacy_mode = !status_switch.active;
            include_treeview.visible = !privacy_mode;
            exclude_treeview.visible = !privacy_mode;
            description_frame.visible = privacy_mode;

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
    }

    private static string get_operating_system_name () {
        string system = _("Your system");
        try {
            string contents = null;
            if (FileUtils.get_contents ("/etc/os-release", out contents)) {
                int start = contents.index_of ("NAME=") + "NAME=".length;
                int end = contents.index_of_char ('\n');
                system = contents.substring (start, end - start).replace ("\"", "");
            }
        } catch (FileError e) {
            debug ("Could not get OS name");
        }
        return system;
    }

    private void update_status_switch () {
        if (status_switch.active) {
            status_type = Granite.SettingsPage.StatusType.SUCCESS;
            status = _("Enabled");
        } else {
            warning ("Trying to set offline");
            status_type = Granite.SettingsPage.StatusType.OFFLINE;
            status = _("Disabled");
        }
    }
}

