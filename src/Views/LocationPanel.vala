// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC.
 * Copyright (C) 2017 David Hewitt <davidmhewitt@gmail.com>   
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Authored by: David Hewitt <davidmhewitt@gmail.com>
 */

public class SecurityPrivacy.LocationPanel : Gtk.Grid {

    private GLib.Settings location_settings;
    private Variant remembered_apps;
    private VariantDict remembered_apps_dict;
    private Gtk.ListStore list_store;
    private Gtk.TreeView tree_view;

    private enum Columns {
        AUTHORIZED,
        NAME,
        ICON,
        APP_ID,
        N_COLUMNS
    }

    construct {
        list_store = new Gtk.ListStore (Columns.N_COLUMNS, typeof (bool),
                typeof (string), typeof (string), typeof (string));

        location_settings = new GLib.Settings ("org.pantheon.agent-geoclue2");
        
        column_spacing = 12;
        row_spacing = 12;
        margin = 12;

        var location_icon = new Gtk.Image.from_icon_name ("find-location", Gtk.IconSize.DIALOG);
        location_icon.halign = Gtk.Align.START;

        var title = new Gtk.Label (_("Location Services"));
        title.get_style_context ().add_class ("h2");
        title.halign = Gtk.Align.START;
        title.hexpand = true;

        var control_switch = new Gtk.Switch ();
        control_switch.valign = Gtk.Align.CENTER;
        location_settings.bind ("location-enabled", control_switch, "active", GLib.SettingsBindFlags.DEFAULT);

        var treeview_grid = create_treeview ();
        attach (location_icon, 0, 0, 1, 1);
        attach (title, 1, 0, 1, 1);
        attach (control_switch, 2, 0, 1, 1);
        attach (treeview_grid, 0, 1, 3, 1);

        location_settings.changed.connect((key) => {
            populate_app_treeview ();
        });
    }

    private Gtk.Grid create_treeview () {
        tree_view = new Gtk.TreeView.with_model (list_store);
        tree_view.vexpand = true;
        tree_view.headers_visible = false;
        tree_view.activate_on_single_click = true;

        var celltoggle = new Gtk.CellRendererToggle ();
        tree_view.row_activated.connect ((path, column) => {
            Value active;
            Gtk.TreeIter iter;
            list_store.get_iter (out iter, path);
            list_store.get_value (iter, Columns.AUTHORIZED, out active);
            var is_active = !active.get_boolean ();
            list_store.set (iter, Columns.AUTHORIZED, is_active);
            Value app_id;
            list_store.get_value (iter, Columns.APP_ID, out app_id);

            uint32 level = get_app_level (app_id.get_string ());
            save_app_settings (app_id.get_string (), is_active, level);
        });

        var cell = new Gtk.CellRendererText ();
        var cellpixbuf = new Gtk.CellRendererPixbuf ();
        cellpixbuf.stock_size = Gtk.IconSize.DND;
        tree_view.insert_column_with_attributes (-1, "", celltoggle, "active", Columns.AUTHORIZED);
        tree_view.insert_column_with_attributes (-1, "", cellpixbuf, "icon-name", Columns.ICON);
        tree_view.insert_column_with_attributes (-1, "", cell, "markup", Columns.NAME);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.shadow_type = Gtk.ShadowType.IN;
        scrolled.expand = true;
        scrolled.add (tree_view);

        var locations_label = new Gtk.Label (_("Allow the apps below to determine your location"));
        locations_label.xalign = 0;

        var treeview_grid = new Gtk.Grid ();
        treeview_grid.row_spacing = 6;
        treeview_grid.attach (locations_label, 0, 0, 1, 1);
        treeview_grid.attach (scrolled, 0, 1, 1, 1);

        populate_app_treeview ();

        return treeview_grid;
    }

    private void populate_app_treeview () {
        load_remembered_apps ();
        Gtk.TreePath? current_selection;
        Gtk.TreeViewColumn? current_column;
        tree_view.get_cursor (out current_selection, out current_column);

        list_store.clear ();
        foreach (var app in remembered_apps) {
            string app_id = app.get_child_value (0).get_string ();
            bool authed = app.get_child_value (1).get_variant ().get_child_value (0).get_boolean ();
            var app_info = new DesktopAppInfo (app_id + ".desktop");
            add_liststore_item (list_store, authed, app_info.get_display_name (), app_info.get_icon ().to_string (), app_id);
        }

        tree_view.set_cursor (current_selection, current_column, false);
    }

    private void add_liststore_item (Gtk.ListStore list_store, bool active, string name, string icon, string app_id) {
        Gtk.TreeIter iter;
        list_store.append (out iter);
        list_store.set (iter, Columns.AUTHORIZED, active, Columns.NAME, name,
                        Columns.ICON, icon, Columns.APP_ID, app_id);
    }

	private void load_remembered_apps () {
	    remembered_apps = location_settings.get_value ("remembered-apps");
        remembered_apps_dict = new VariantDict (location_settings.get_value ("remembered-apps"));
	}

	private void save_app_settings (string desktop_id, bool authorized, uint32 accuracy_level) {
		Variant[2] tuple_vals = new Variant[2];
		tuple_vals[0] = new Variant.boolean (authorized);
		tuple_vals[1] = new Variant.uint32 (accuracy_level);
		remembered_apps_dict.insert_value (desktop_id, new Variant.tuple (tuple_vals));
		location_settings.set_value ("remembered-apps", remembered_apps_dict.end ());
        load_remembered_apps ();
	}

    private uint32 get_app_level (string desktop_id) {
        return remembered_apps.lookup_value (desktop_id, GLib.VariantType.TUPLE).get_child_value (1).get_uint32 ();
    }
}
