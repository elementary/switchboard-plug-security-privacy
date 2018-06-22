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
    private Gtk.Label file_age_label;
    private Gtk.SpinButton file_age_spinbutton;
    private Gtk.Switch temp_files_switch;
    private Gtk.Switch trash_files_switch;

    public HouseKeepingPanel () {
        Object (
            icon_name: "edit-clear",
            title: _("Housekeeping")
        );
    }

    construct {
        var temp_files_label = new Gtk.Label (_("Automatically delete old temporary files:"));
        temp_files_label.xalign = 1;

        temp_files_switch = new Gtk.Switch ();
        temp_files_switch.halign = Gtk.Align.START;

        var trash_files_label = new Gtk.Label (_("Automatically delete old trashed files:"));
        trash_files_label.xalign = 1;

        trash_files_switch = new Gtk.Switch ();
        trash_files_switch.halign = Gtk.Align.START;

        file_age_label = new Gtk.Label (_("Number of days to keep trashed and temporary files:"));
        file_age_label.xalign = 1;

        file_age_spinbutton = new Gtk.SpinButton.with_range (0, 90, 5);

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

        temp_files_switch.notify["active"].connect (update_status);
        trash_files_switch.notify["active"].connect (update_status);

        update_status ();
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
    }
}
