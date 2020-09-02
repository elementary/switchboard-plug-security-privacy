/*
 * Copyright (c) 2018 elementary, Inc. (https://elementary.io)
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
 */

public class SecurityPrivacy.HouseKeepingPanel : Granite.SimpleSettingsPage {
    private Granite.HeaderLabel spin_header_label;
    private Gtk.Label file_age_label;
    private Gtk.SpinButton file_age_spinbutton;
    private Gtk.CheckButton temp_files_switch;
    private Gtk.CheckButton trash_files_switch;

    public HouseKeepingPanel () {
        Object (
            description: "",
            icon_name: "preferences-system-privacy-housekeeping",
            title: _("Housekeeping")
        );
    }

    construct {
        var switch_header_label = new Granite.HeaderLabel (_("Automatically Delete:"));

        temp_files_switch = new Gtk.CheckButton.with_label (_("Unneeded temporary files"));
        temp_files_switch.margin_start = 12;

        trash_files_switch = new Gtk.CheckButton.with_label (_("Trashed files"));
        trash_files_switch.margin_bottom = 18;
        trash_files_switch.margin_start = 12;

        spin_header_label = new Granite.HeaderLabel (_("Delete Trashed and Temporary Files After:"));

        file_age_spinbutton = new Gtk.SpinButton.with_range (0, 90, 5);
        file_age_spinbutton.margin_start = 12;
        file_age_spinbutton.max_length = 2;
        file_age_spinbutton.xalign = 1;

        file_age_label = new Gtk.Label (null);
        file_age_label.halign = Gtk.Align.START;
        file_age_label.hexpand = true;

        content_area.column_spacing = content_area.row_spacing = 6;
        content_area.margin_start = 60;
        content_area.attach (switch_header_label, 0, 0, 2);
        content_area.attach (temp_files_switch, 0, 1, 2);
        content_area.attach (trash_files_switch, 0, 2, 2);
        content_area.attach (spin_header_label, 0, 3, 2);
        content_area.attach (file_age_label, 1, 4);
        content_area.attach (file_age_spinbutton, 0, 4);

        var view_trash_button = new Gtk.Button.with_label (_("Open Trash…"));

        action_area.add (view_trash_button);

        var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");
        privacy_settings.bind ("remove-old-temp-files", temp_files_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        privacy_settings.bind ("remove-old-trash-files", trash_files_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        privacy_settings.bind ("old-files-age", file_age_spinbutton, "value", GLib.SettingsBindFlags.DEFAULT);

        update_days (privacy_settings.get_uint ("old-files-age"));

        privacy_settings.changed["old-files-age"].connect (() => {
            update_days (privacy_settings.get_uint ("old-files-age"));
        });

        temp_files_switch.notify["active"].connect (update_status);
        trash_files_switch.notify["active"].connect (update_status);

        view_trash_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("trash:///", null);
            } catch (Error e) {
                warning ("Failed to open trash: %s", e.message);
            }
        });

        update_status ();
    }

    private void update_days (uint age) {
        description = dngettext (Build.GETTEXT_PACKAGE,
            "Old files can be automatically deleted after %u day to save space and help protect your privacy.",
            "Old files can be automatically deleted after %u days to save space and help protect your privacy.",
            age
        ).printf (age);

        file_age_label.label = dngettext (Build.GETTEXT_PACKAGE,
            "Day",
            "Days",
            age
        );
    }

    private void update_status () {
        var either_active = temp_files_switch.active || trash_files_switch.active;

        if (temp_files_switch.active && trash_files_switch.active) {
            status_type = Granite.SettingsPage.StatusType.SUCCESS;
        } else if (either_active) {
            status_type = Granite.SettingsPage.StatusType.WARNING;
        } else {
            status_type = Granite.SettingsPage.StatusType.OFFLINE;
        }

        file_age_label.sensitive = either_active;
        file_age_spinbutton.sensitive = either_active;
        spin_header_label.sensitive = either_active;
    }
}
