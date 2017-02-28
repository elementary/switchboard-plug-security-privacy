// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014 Security & Privacy Plug (http://launchpad.net/your-project)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public class SecurityPrivacy.TrackPanel : Gtk.Grid {
    private Widgets.ClearUsagePopover remove_popover;
    private Gtk.Switch record_switch;

    public TrackPanel () {
        Object (column_spacing: 12,
                margin: 12,
                row_spacing: 12);
    }

    construct {
        var description = ("%s %s\n\n%s".printf (
                    _("%s won't retain any further data or statistics about file and application usage.").printf (get_operating_system_name ()),
                    _("The additional functionality that this data provides will be affected."),
                    _("This will not prevent apps from recording their own usage data like browser history.")));

        var alert = new Granite.Widgets.AlertView (_("History Is Disabled"), description, "");
        alert.show_all ();

        var description_frame = new Gtk.Frame (null);
        description_frame.no_show_all = true;
        description_frame.add (alert);

        var header_image = new Gtk.Image.from_icon_name ("document-open-recent", Gtk.IconSize.DIALOG);

        var record_label = new Gtk.Label (_("History"));
        record_label.get_style_context ().add_class ("h2");

        record_switch = new Gtk.Switch ();
        record_switch.active = true;
        record_switch.valign = Gtk.Align.CENTER;

        var info_button = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.MENU);
        info_button.hexpand = true;
        info_button.xalign = 0;
        info_button.tooltip_text = _("This operating system can gather useful statistics about file and app usage to provide extra functionality. If other people can see or access your account, you may wish to limit which items are recorded.");

        var header_grid = new Gtk.Grid ();
        header_grid.column_spacing = 12;
        header_grid.margin_bottom = 12;
        header_grid.add (header_image);
        header_grid.add (record_label);
        header_grid.add (info_button);
        header_grid.add (record_switch);

        var clear_data = new Gtk.ToggleButton.with_label (_("Clear History…"));
        clear_data.halign = Gtk.Align.END;
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

        attach (header_grid, 0, 0, 2, 1);
        attach (description_frame, 0, 1, 2, 1);
        attach (include_treeview, 0, 1, 1, 1);
        attach (exclude_treeview, 1, 1, 1, 1);
        attach (clear_data, 1, 2, 1, 1);

        record_switch.notify["active"].connect (() => {
            bool privacy_mode = !record_switch.active;
            include_treeview.visible = !privacy_mode;
            exclude_treeview.visible = !privacy_mode;
            description_frame.visible = privacy_mode;

            if (privacy_mode != blacklist.get_incognito ()) {
                blacklist.set_incognito (privacy_mode);

                var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");
                privacy_settings.set_boolean ("remember-recent-files", !privacy_mode);
                privacy_settings.set_boolean ("remember-app-usage", !privacy_mode);
            }
        });

        record_switch.active = !blacklist.get_incognito ();
    }
    
    public void focus_privacy_switch () {
        record_switch.grab_focus ();
    }

    private string get_operating_system_name () {
        string system = _("Your system");
        try {
            string contents = null;
            if (FileUtils.get_contents ("/etc/os-release", out contents)) {
                int start = contents.index_of ("NAME=") + "NAME=".length;
                int end = contents.index_of_char ('\n');
                system = contents.substring (start, end - start).replace ("\"", "");
            }
        } catch (FileError e) {
        }
        return system;
    }
}
