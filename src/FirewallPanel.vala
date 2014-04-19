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

public class SecurityPrivacy.FirewallPanel : Gtk.Grid {
    Gtk.ListStore list_store;
    Gtk.TreeView view;
    Gtk.Toolbar list_toolbar;

    private enum Columns {
        ACTIVE,
        DESCRIPTION,
        ACTION,
        PROTOCOL,
        DIRECTION,
        PORTS,
        N_COLUMNS
    }

    private enum Action {
        ALLOW,
        DENY,
        REJECT,
        LIMIT
    }

    private enum Protocol {
        BOTH,
        UDP,
        TCP
    }

    public FirewallPanel () {
        column_spacing = 12;
        row_spacing = 6;
        margin_bottom = 12;
        
        var status_grid = new Gtk.Grid ();
        status_grid.column_spacing = 12;
        var status_label = new Gtk.Label ("");
        status_label.set_markup ("<b>%s</b>".printf (_("Firewall Status:")));
        
        var status_switch = new Gtk.Switch ();

        var fake_grid_left = new Gtk.Grid ();
        fake_grid_left.hexpand = true;
        var fake_grid_right = new Gtk.Grid ();
        fake_grid_right.hexpand = true;
        status_grid.attach (status_label, 0, 0, 1, 1);
        status_grid.attach (status_switch, 1, 0, 1, 1);

        attach (fake_grid_left, 0, 0, 1, 1);
        attach (status_grid, 1, 0, 1, 1);
        attach (fake_grid_right, 2, 0, 1, 1);

        create_treeview ();
    }

    private void create_treeview () {
        list_store = new Gtk.ListStore (Columns.N_COLUMNS, typeof (bool),
                typeof (string), typeof (string), typeof (string),
                typeof (string), typeof (string));

        // The View:
        view = new Gtk.TreeView.with_model (list_store);
        view.vexpand = true;
        view.search_column = Columns.DESCRIPTION;

        var celltoggle = new Gtk.CellRendererToggle ();
        view.insert_column_with_attributes (-1, _("Status"), celltoggle, "active", Columns.ACTIVE);

        var cell = new Gtk.CellRendererText ();
        view.insert_column_with_attributes (-1, _("Description"), cell, "text", Columns.DESCRIPTION);
        view.insert_column_with_attributes (-1, _("Action"), cell, "text", Columns.ACTION);
        view.insert_column_with_attributes (-1, _("Protocol"), cell, "text", Columns.PROTOCOL);
        view.insert_column_with_attributes (-1, _("Direction"), cell, "text", Columns.DIRECTION);
        view.insert_column_with_attributes (-1, _("Ports"), cell, "text", Columns.PORTS);

        Gtk.TreeIter iter;

        list_store.append (out iter);
        list_store.set (iter, Columns.ACTIVE, true, Columns.DESCRIPTION, "Test");

        list_toolbar = new Gtk.Toolbar ();
        list_toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        list_toolbar.set_icon_size (Gtk.IconSize.SMALL_TOOLBAR);
        var add_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        add_button.clicked.connect (() => {
            try {
                string standard_output;
                var lang = GLib.Environment.get_variable ("LANGUAGE");
                GLib.Environment.set_variable ("LANGUAGE", "C", true);
                Process.spawn_command_line_sync ("pkexec ufw status", out standard_output);
                //GLib.Environment.set_variable ("LANGUAGE", lang, true);
                warning (standard_output);
            } catch (Error e) {
                warning (e.message);
            }
            
        });
        list_toolbar.insert (add_button, -1);
        var remove_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        list_toolbar.insert (remove_button, -1);

        var view_grid = new Gtk.Grid ();
        var frame = new Gtk.Frame (null);
        frame.add (view);
        view_grid.attach (frame, 0, 0, 1, 1);
        view_grid.attach (list_toolbar, 0, 1, 1, 1);
        attach (view_grid, 1, 1, 1, 1);
    }
}