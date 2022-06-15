// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
* Copyright (c) 2014-2017 elementary LLC. (http://launchpad.net/switchboard-plug-security-privacy)
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

    private Gtk.ListBox list;
    private Gtk.SearchEntry search_entry;

    construct {
        search_entry = new Gtk.SearchEntry ();
        search_entry.margin_end = 12;
        search_entry.margin_start = 12;
        search_entry.placeholder_text = _("Search Application");

        list = new Gtk.ListBox () {
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

        var grid = new Gtk.Grid ();
        grid.margin_top = 12;
        grid.row_spacing = 6;
        grid.attach (search_entry, 0, 0, 1, 1);
        grid.attach (scrolled, 0, 1, 1, 1);

        child = grid;

        search_entry.grab_focus ();
        list.row_activated.connect (on_app_selected);
        search_entry.search_changed.connect (apply_filter);

        init_list ();
    }

    public void init_list () {
        foreach (var app_info in AppInfo.get_all ()) {
            if (app_info is DesktopAppInfo && app_info.should_show ()) {
                var app_row = new AppRow ((DesktopAppInfo)app_info);
                list.prepend (app_row);
            }
        }
    }

    int sort_function (Gtk.ListBoxRow list_box_row_1,
                       Gtk.ListBoxRow list_box_row_2) {
        var row_1 = list_box_row_1 as AppRow;
        var row_2 = list_box_row_2 as AppRow;

        var name_1 = row_1.app_info.get_display_name ();
        var name_2 = row_2.app_info.get_display_name ();

        return name_1.collate (name_2);
    }

    bool filter_function (Gtk.ListBoxRow list_box_row) {
        var app_row = list_box_row as AppRow;
        string name = app_row.app_info.get_display_name ();
        if (name == null)
            name = app_row.app_info.get_name ();
        string description = app_row.app_info.get_description ();
        if (description == null)
            description = "";
        string search = search_entry.text.down ();
        return search in name.down ()
            || search in description.down ();
    }

    void on_app_selected (Gtk.ListBoxRow list_box_row) {
        var app_row = list_box_row as AppRow;
        app_chosen (app_row.app_info);
        hide ();
    }

    void apply_filter () {
        list.set_filter_func (filter_function);
    }
}
