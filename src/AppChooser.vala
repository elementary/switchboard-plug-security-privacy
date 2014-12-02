// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014 Security & Privacy Plug (http://launchpad.net/switchboard-plug-security-privacy)
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
 * Authored by: Julien Spautz <spautz.julien@gmail.com>
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class SecurityPrivacy.Dialogs.AppChooser : Gtk.Popover {

    const string FALLBACK_ICON = "application-default-icon";
    public class AppRow : Gtk.Box {
        public DesktopAppInfo app_info { get; construct; }

        public AppRow (DesktopAppInfo app_info) {
            Object (app_info: app_info);
            orientation = Gtk.Orientation.HORIZONTAL;

            var name = app_info.get_display_name ();
            if (name == null)
                name = app_info.get_name ();
            var escaped_name = Markup.escape_text (name);
            var comment = app_info.get_description ();
            if (comment == null)
                comment = "";
            var escaped_comment = Markup.escape_text (comment);

            margin = 6;
            spacing = 12;

            var icon_theme = Gtk.IconTheme.get_default ();
            if (icon_theme.has_icon (app_info.get_icon ().to_string ()))
                add (new Gtk.Image.from_gicon (app_info.get_icon (), Gtk.IconSize.DND));
            else
                add (new Gtk.Image.from_icon_name (FALLBACK_ICON, Gtk.IconSize.DND));

            var label = new Gtk.Label ("<span font_weight=\"bold\" size=\"large\">%s</span>\n%s".printf (escaped_name, escaped_comment));
            label.use_markup = true;
            label.halign = Gtk.Align.START;
            label.ellipsize = Pango.EllipsizeMode.END;
            add (label);

            show_all ();
        }
    }

    public signal void app_chosen (DesktopAppInfo app_info);

    private Gtk.ListBox list;
    private Gtk.SearchEntry search_entry;

    public AppChooser (Gtk.Widget widget) {
        Object (relative_to: widget);
        setup_gui ();
        connect_signals ();
        init_list ();
    }

    void setup_gui () {
        var grid = new Gtk.Grid ();
        grid.margin = 12;
        grid.row_spacing = 6;

        search_entry = new Gtk.SearchEntry ();
        search_entry.placeholder_text = _("Search Application");

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.height_request = 200;
        scrolled.width_request = 250;
        scrolled.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        scrolled.shadow_type = Gtk.ShadowType.IN;

        list = new Gtk.ListBox ();
        list.expand = true;
        list.height_request = 250;
        list.width_request = 200;
        list.set_sort_func (sort_function);
        list.set_filter_func (filter_function);
        scrolled.add (list);

        grid.attach (search_entry, 0, 0, 1, 1);
        grid.attach (scrolled, 0, 1, 1, 1);

        add (grid);
    }

    public void init_list () {
        foreach (var app_info in AppInfo.get_all ()) {
            if (app_info.should_show () == false)
                continue;

            if (app_info is DesktopAppInfo) {
                var app_row = new AppRow ((DesktopAppInfo)app_info);
                list.prepend (app_row);
            }
        }
    }

    int sort_function (Gtk.ListBoxRow list_box_row_1,
                       Gtk.ListBoxRow list_box_row_2) {
        var row_1 = list_box_row_1.get_child () as AppRow;
        var row_2 = list_box_row_2.get_child () as AppRow;

        var name_1 = row_1.app_info.get_display_name ();
        var name_2 = row_2.app_info.get_display_name ();

        return name_1.collate (name_2);
    }

    bool filter_function (Gtk.ListBoxRow list_box_row) {
        var app_row = list_box_row.get_child () as AppRow;
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

    void connect_signals () {
        list.row_activated.connect (on_app_selected);
        search_entry.search_changed.connect (apply_filter);
    }

    void on_app_selected (Gtk.ListBoxRow list_box_row) {
        var app_row = list_box_row.get_child () as AppRow;
        app_chosen (app_row.app_info);
        hide ();
    }

    void apply_filter () {
        list.set_filter_func (filter_function);
    }
}
