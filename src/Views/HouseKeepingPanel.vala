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
    public HouseKeepingPanel () {
        Object (
            icon_name: "edit-clear",
            title: _("Housekeeping")
        );
    }

    construct {
        var temp_files_label = new Gtk.Label (_("Automatically delete old temporary files:"));
        temp_files_label.xalign = 1;

        var temp_files_switch = new Gtk.Switch ();
        temp_files_switch.halign = Gtk.Align.START;

        var trash_files_label = new Gtk.Label (_("Automatically delete old trashed files:"));
        trash_files_label.xalign = 1;

        var trash_files_switch = new Gtk.Switch ();
        trash_files_switch.halign = Gtk.Align.START;

        var file_age_label = new Gtk.Label (_("Number of days to keep trash and temporary files:"));
        file_age_label.xalign = 1;

        var file_age_spinbutton = new Gtk.SpinButton.with_range (0, 90, 5);

        content_area.hexpand = true;
        content_area.halign = Gtk.Align.CENTER;
        content_area.attach (temp_files_label, 0, 0);
        content_area.attach (temp_files_switch, 1, 0);
        content_area.attach (trash_files_label, 0, 1);
        content_area.attach (trash_files_switch, 1, 1);
        content_area.attach (file_age_label, 0, 2);
        content_area.attach (file_age_spinbutton, 1, 2);

        var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");
        privacy_settings.bind ("remove-old-temp-files", temp_files_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        privacy_settings.bind ("remove-old-trash-files", trash_files_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        privacy_settings.bind ("old-files-age", file_age_spinbutton, "value", GLib.SettingsBindFlags.DEFAULT);
    }
}
