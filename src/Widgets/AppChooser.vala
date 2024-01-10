/*-
* Copyright (c) 2014-2022 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Julien Spautz <spautz.julien@gmail.com>
*              Corentin Noël <corentin@elementaryos.org>
*/

public class SecurityPrivacy.Dialogs.AppChooser : Gtk.Popover {
    public signal void app_chosen (DesktopAppInfo app_info);

    private Gtk.SearchEntry search_entry;

    construct {
        search_entry = new Gtk.SearchEntry () {
            margin_end = 12,
            margin_start = 12,
            placeholder_text = _("Search Application")
        };

        var list = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true
        };
        list.set_sort_func (sort_function);
        list.set_filter_func (filter_function);

        var scrolled = new Gtk.ScrolledWindow () {
            child = list,
            height_request = 200,
            width_request = 500
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12,
            margin_bottom = 6
        };
        box.append (search_entry);
        box.append (scrolled);

        child = box;

        foreach (unowned var app_info in AppInfo.get_all ()) {
            if (app_info is DesktopAppInfo && app_info.should_show ()) {
                var app_row = new AppRow ((DesktopAppInfo)app_info);
                list.prepend (app_row);
            }
        }

        search_entry.grab_focus ();
        list.row_activated.connect (on_app_selected);
        search_entry.search_changed.connect (() => {
            list.invalidate_filter ();
        });
    }

    private int sort_function (Gtk.ListBoxRow list_box_row_1, Gtk.ListBoxRow list_box_row_2) {
        var row_1 = list_box_row_1 as AppRow;
        var row_2 = list_box_row_2 as AppRow;

        var name_1 = row_1.app_info.get_display_name ();
        var name_2 = row_2.app_info.get_display_name ();

        return name_1.collate (name_2);
    }

    private bool filter_function (Gtk.ListBoxRow list_box_row) {
        var app_row = list_box_row as AppRow;

        var name = app_row.app_info.get_display_name ();
        if (name == null) {
            name = app_row.app_info.get_name ();
        }

        var description = app_row.app_info.get_description ();
        if (description == null) {
            description = "";
        }

        var search = search_entry.text.down ();
        return search in name.down () || search in description.down ();
    }

    private void on_app_selected (Gtk.ListBoxRow list_box_row) {
        var app_row = list_box_row as AppRow;
        app_chosen (app_row.app_info);
        popdown ();
    }
}
