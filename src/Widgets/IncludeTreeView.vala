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
* Authored by: Corentin Noël <corentin@elementaryos.org>
*/

public class IncludeTreeView : Gtk.Grid {
    private SecurityPrivacy.FileTypeBlacklist filetype_blacklist;

    private enum Columns {
        ACTIVE,
        NAME,
        ICON,
        FILE_TYPE,
        N_COLUMNS
    }

    public IncludeTreeView () {
        Object (row_spacing: 6);
    }

    construct {
        filetype_blacklist = new SecurityPrivacy.FileTypeBlacklist (SecurityPrivacy.TrackPanel.blacklist);

        var list_store = new Gtk.ListStore (
            Columns.N_COLUMNS,
            typeof (bool),
            typeof (string),
            typeof (string),
            typeof (string)
        );

        var view = new Gtk.TreeView.with_model (list_store);
        view.vexpand = true;
        view.headers_visible = false;
        view.activate_on_single_click = true;

        var celltoggle = new Gtk.CellRendererToggle ();
        view.row_activated.connect ((path, column) => {
            Value active;
            Gtk.TreeIter iter;
            list_store.get_iter (out iter, path);
            list_store.get_value (iter, Columns.ACTIVE, out active);
            var is_active = !active.get_boolean ();
            list_store.set (iter, Columns.ACTIVE, is_active);
            Value name;
            list_store.get_value (iter, Columns.FILE_TYPE, out name);
            if (is_active == true) {
                filetype_blacklist.unblock (name.get_string ());
            } else {
                filetype_blacklist.block (name.get_string ());
            }
        });

        var cell = new Gtk.CellRendererText ();
        var cellpixbuf = new Gtk.CellRendererPixbuf () {
            icon_size = Gtk.IconSize.LARGE
        };
        view.insert_column_with_attributes (-1, "", celltoggle, "active", Columns.ACTIVE);
        view.insert_column_with_attributes (-1, "", cellpixbuf, "icon-name", Columns.ICON);
        view.insert_column_with_attributes (-1, "", cell, "markup", Columns.NAME);

        var scrolled = new Gtk.ScrolledWindow () {
            child = view,
            hexpand = true,
            vexpand = true,
            has_frame = true
        };

        var record_label = new Gtk.Label (_("Data Sources:"));
        record_label.xalign = 0;

        attach (record_label, 0, 0, 1, 1);
        attach (scrolled, 0, 1, 1, 1);

        set_inclue_iter_to_liststore (list_store, _("Chat Logs"), "internet-chat", Zeitgeist.NMO.IMMESSAGE);
        set_inclue_iter_to_liststore (list_store, _("Documents"), "x-office-document", Zeitgeist.NFO.DOCUMENT);
        set_inclue_iter_to_liststore (list_store, _("Music"), "audio-x-generic", Zeitgeist.NFO.AUDIO);
        set_inclue_iter_to_liststore (list_store, _("Pictures"), "image-x-generic", Zeitgeist.NFO.IMAGE);
        set_inclue_iter_to_liststore (
            list_store,
            _("Presentations"),
            "x-office-presentation",
            Zeitgeist.NFO.PRESENTATION
        );
        set_inclue_iter_to_liststore (
            list_store,
            _("Spreadsheets"),
            "x-office-spreadsheet",
            Zeitgeist.NFO.SPREADSHEET
        );
        set_inclue_iter_to_liststore (list_store, _("Videos"), "video-x-generic", Zeitgeist.NFO.VIDEO);
    }

    private void set_inclue_iter_to_liststore (Gtk.ListStore list_store, string name, string icon, string file_type) {
        Gtk.TreeIter iter;
        list_store.append (out iter);
        bool active = (filetype_blacklist.all_filetypes.contains (file_type) == false);
        list_store.set (iter, Columns.ACTIVE, active, Columns.NAME, name,
                        Columns.ICON, icon, Columns.FILE_TYPE, file_type);
    }
}
