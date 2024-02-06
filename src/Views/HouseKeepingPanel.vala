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

public class SecurityPrivacy.HouseKeepingPanel : Switchboard.SettingsPage {
    private Granite.HeaderLabel spin_header_label;
    private Gtk.Label file_age_label;
    private Gtk.SpinButton file_age_spinbutton;
    private Gtk.CheckButton download_files_check;
    private Gtk.CheckButton screenshot_files_check;
    private Gtk.CheckButton temp_files_switch;
    private Gtk.CheckButton trash_files_switch;

    public HouseKeepingPanel () {
        Object (
            icon: new ThemedIcon ("preferences-system-privacy-housekeeping"),
            title: _("Housekeeping")
        );
    }

    construct {
        var switch_header_label = new Granite.HeaderLabel (_("Automatically Delete:"));

        temp_files_switch = new Gtk.CheckButton () {
            halign = Gtk.Align.START,
            margin_start = 12
        };

        var temp_files_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        temp_files_grid.append (new Gtk.Image.from_icon_name ("folder") {
            margin_end = 6,
            pixel_size = 24
        });
        temp_files_grid.append (new Gtk.Label (_("Old temporary files")));
        temp_files_grid.set_parent (temp_files_switch);

        download_files_check = new Gtk.CheckButton () {
            halign = Gtk.Align.START,
            margin_start = 12
        };

        var download_files_box = new Gtk.Box (HORIZONTAL, 0);
        download_files_box.append (new Gtk.Image.from_icon_name ("folder-download") {
            margin_end = 6,
            pixel_size = 24
        });
        download_files_box.append (new Gtk.Label (_("Downloaded files")));
        download_files_box.set_parent (download_files_check);

        var screenshot_files_grid = new Gtk.Box (HORIZONTAL, 0);
        screenshot_files_grid.append (new Gtk.Image.from_icon_name ("folder-screenshots-icon") {
            margin_end = 6,
            pixel_size = 24
        });
        screenshot_files_grid.append (new Gtk.Label (_("Screenshot files")));

        screenshot_files_check = new Gtk.CheckButton () {
            halign = Gtk.Align.START,
            margin_start = 12
        };
        screenshot_files_grid.set_parent (screenshot_files_check);

        trash_files_switch = new Gtk.CheckButton () {
            halign = Gtk.Align.START,
            margin_start = 12,
            margin_bottom = 18
        };

        var trash_files_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        trash_files_grid.append (new Gtk.Image.from_icon_name ("user-trash-full") {
            margin_end = 6,
            pixel_size = 24
        });
        trash_files_grid.append (new Gtk.Label (_("Trashed files")));
        trash_files_grid.set_parent (trash_files_switch);

        spin_header_label = new Granite.HeaderLabel (_("Delete Old Files After:"));

        file_age_spinbutton = new Gtk.SpinButton.with_range (0, 90, 5);
        file_age_spinbutton.margin_start = 12;
        file_age_spinbutton.max_width_chars = 2;
        file_age_spinbutton.xalign = 1;

        file_age_label = new Gtk.Label (null);
        file_age_label.halign = Gtk.Align.START;
        file_age_label.hexpand = true;

        var grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6
        };
        grid.attach (switch_header_label, 0, 0, 2);
        grid.attach (download_files_check, 0, 1, 2);
        grid.attach (temp_files_switch, 0, 2, 2);
        grid.attach (screenshot_files_check, 0, 3, 2);
        grid.attach (trash_files_switch, 0, 4, 2);
        grid.attach (spin_header_label, 0, 5, 2);
        grid.attach (file_age_spinbutton, 0, 6);
        grid.attach (file_age_label, 1, 6);

        child = grid;

        var view_trash_button = add_button (_("Open Trash…"));

        var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");
        privacy_settings.bind ("remove-old-temp-files", temp_files_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        privacy_settings.bind ("remove-old-trash-files", trash_files_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        privacy_settings.changed.connect (update_status);

        var housekeeping_settings = new Settings ("io.elementary.settings-daemon.housekeeping");
        housekeeping_settings.bind ("cleanup-downloads-folder", download_files_check, "active", GLib.SettingsBindFlags.DEFAULT);
        housekeeping_settings.bind ("cleanup-screenshots-folder", screenshot_files_check, "active", GLib.SettingsBindFlags.DEFAULT);
        housekeeping_settings.bind ("old-files-age", file_age_spinbutton, "value", GLib.SettingsBindFlags.DEFAULT);
        housekeeping_settings.changed.connect (update_status);

        update_days ((uint) file_age_spinbutton.value);

        file_age_spinbutton.value_changed.connect (() => {
            update_days ((uint) file_age_spinbutton.value);
            privacy_settings.set_uint ("old-files-age", (uint) file_age_spinbutton.value);
        });

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
        var all_active = temp_files_switch.active && trash_files_switch.active && download_files_check.active && screenshot_files_check.active;
        var any_active = temp_files_switch.active || trash_files_switch.active || download_files_check.active || screenshot_files_check.active;

        if (all_active) {
            status_type = SUCCESS;
            status = _("Enabled");
        } else if (any_active) {
            status_type = WARNING;
            status = _("Partially Enabled");
        } else {
            status_type = OFFLINE;
            status = _("Disabled");
        }

        file_age_label.sensitive = any_active;
        file_age_spinbutton.sensitive = any_active;
        spin_header_label.sensitive = any_active;
    }
}
