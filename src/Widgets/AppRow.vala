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

public class AppRow : Gtk.ListBoxRow {
    public DesktopAppInfo app_info { get; construct; }
    protected Gtk.Grid main_grid;
    protected Gtk.Label app_comment;

    public AppRow (DesktopAppInfo app_info) {
        Object (app_info: app_info);
    }

    construct {
        var image = new Gtk.Image.from_icon_name (get_icon_name (), Gtk.IconSize.DND);
        image.pixel_size = 32;

        var app_name = new Gtk.Label (get_app_name ());
        app_name.get_style_context ().add_class ("h3");
        app_name.xalign = 0;
        app_name.ellipsize = Pango.EllipsizeMode.END;

        app_comment = new Gtk.Label ("<span font_size='small'>" + get_app_comment () + "</span>");
        app_comment.xalign = 0;
        app_comment.use_markup = true;
        app_comment.ellipsize = Pango.EllipsizeMode.END;

        main_grid = new Gtk.Grid ();
        main_grid.margin = 6;
        main_grid.margin_end = 12;
        main_grid.margin_start = 10; // Account for icon position on the canvas
        main_grid.column_spacing = 12;
        main_grid.attach (image, 0, 0, 1, 2);
        main_grid.attach (app_name, 1, 0, 1, 1);
        main_grid.attach (app_comment, 1, 1, 1, 1);

        add (main_grid);
        show_all ();
    }

    private string get_app_comment () {
        var comment = app_info.get_description ();

        if (comment == null) {
            comment = "";
        }

        return Markup.escape_text (comment);
    }

    private string get_app_name () {
        var name = app_info.get_display_name ();

        if (name == null) {
            name = app_info.get_name ();
        }

        return Markup.escape_text (name);
    }

    private string get_icon_name () {
        var icon_theme = Gtk.IconTheme.get_default ();

        if (icon_theme.has_icon (app_info.get_icon ().to_string ())) {
            return app_info.get_icon ().to_string ();
        } else {
            return "application-default-icon";
        }
    }
}
