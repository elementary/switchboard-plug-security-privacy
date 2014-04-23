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

public class SecurityPrivacy.AppsDialog : Gtk.Dialog {
    private enum Columns {
        NAME,
        ICON,
        APPINFO,
        N_COLUMNS
    }

    private Gtk.ListStore list_store;
    private ApplicationBlacklist app_blacklist;

    public AppsDialog (ApplicationBlacklist app_blacklist) {
        this.app_blacklist = app_blacklist;
        title = _("Select Application");
        destroy_with_parent = true;
        set_size_request (600, 400);
        skip_taskbar_hint = true;
        resizable = false;

        list_store = new Gtk.ListStore (Columns.N_COLUMNS, typeof (string), typeof (Icon), typeof (DesktopAppInfo));
        var view = new Gtk.TreeView.with_model (list_store);
        view.vexpand = true;
        view.headers_visible = false;
        var cell = new Gtk.CellRendererText ();
        var cellpixbuf = new Gtk.CellRendererPixbuf ();
        view.insert_column_with_attributes (-1, "", cellpixbuf, "gicon", Columns.ICON);
        view.insert_column_with_attributes (-1, "", cell, "markup", Columns.NAME);
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (view);
        scrolled.expand = true;

        add_buttons (_("Cancel"), Gtk.ResponseType.CANCEL, _("Add"), Gtk.ResponseType.OK);
        set_default_response (Gtk.ResponseType.OK);
        response.connect ((id) => {
            if (id == Gtk.ResponseType.OK) {
                Gtk.TreePath path;
                Gtk.TreeViewColumn column;
                view.get_cursor (out path, out column);
                Gtk.TreeIter iter;
                list_store.get_iter (out iter, path);
                Value val;
                list_store.get_value (iter, Columns.APPINFO, out val);
                DesktopAppInfo info = (DesktopAppInfo)val.get_object ();
                var file = File.new_for_path (info.filename);
                app_blacklist.block (file.get_basename ());
            }
            hide ();
        });

        get_content_area ().add (scrolled);

        Gtk.TreeIter iter;
        foreach (var app_info in AppInfo.get_all ()) {
            if (app_info is DesktopAppInfo) {
                list_store.append (out iter);
                list_store.set (iter, Columns.NAME, Markup.escape_text (app_info.get_display_name ()),
                        Columns.ICON, app_info.get_icon (),
                        Columns.APPINFO, (DesktopAppInfo)app_info);
            }
        }
    }
}