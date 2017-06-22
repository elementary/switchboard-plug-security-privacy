/*
* Copyright (c) 2017 elementary LLC. (https://elementary.io)
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Lesser General Public License as published by
* the Free Software Foundation, either version 2.1 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Library General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

public class Switchboard.SidebarRow : Gtk.ListBoxRow {
    public string? header { get; set; }

    public string icon_name {
        get {
            return _icon_name;
        }
        set {
            _icon_name = value;
            icon.icon_name = value;
        } 
    }

    public string title {
        get {
            return _title;
        }
        set {
            _title = value;
            title_label.label = value;
        }
    }

    private Gtk.Image icon;
    private Gtk.Label title_label;
    private string _icon_name;
    private string _title;

    public SidebarRow (string icon_name, string title) {
        Object (
            icon_name: icon_name,
            title: title
        );
    }

    construct {
        icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DND);
        icon.pixel_size = 32;

        title_label = new Gtk.Label (title);
        title_label.ellipsize = Pango.EllipsizeMode.END;
        title_label.xalign = 0;
        title_label.get_style_context ().add_class ("h3");

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.margin = 6;
        grid.add (icon);
        grid.add (title_label);

        add (grid);
    }
}
