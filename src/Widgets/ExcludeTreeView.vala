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

public class ExcludeTreeView : Gtk.Grid {
    private SecurityPrivacy.Dialogs.AppChooser app_chooser;
    private SecurityPrivacy.ApplicationBlacklist app_blacklist;
    private SecurityPrivacy.PathBlacklist path_blacklist;

    private enum NotColumns {
        NAME,
        ICON,
        PATH,
        IS_APP,
        N_COLUMNS
    }

    construct {
        app_blacklist = new SecurityPrivacy.ApplicationBlacklist (SecurityPrivacy.blacklist);
        path_blacklist = new SecurityPrivacy.PathBlacklist (SecurityPrivacy.blacklist);

        var list_store = new Gtk.ListStore (
            NotColumns.N_COLUMNS,
            typeof (string),
            typeof (Icon),
            typeof (string),
            typeof (bool)
        );

        var view = new Gtk.TreeView.with_model (list_store);
        view.vexpand = true;
        view.headers_visible = false;

        var cell = new Gtk.CellRendererText ();
        var cellpixbuf = new Gtk.CellRendererPixbuf ();
        cellpixbuf.stock_size = Gtk.IconSize.DND;
        view.insert_column_with_attributes (-1, "", cellpixbuf, "gicon", NotColumns.ICON);
        view.insert_column_with_attributes (-1, "", cell, "markup", NotColumns.NAME);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (view);

        var add_app_button = new Gtk.ToolButton (
            new Gtk.Image.from_icon_name ("application-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
            null
        );
        add_app_button.tooltip_text = _("Add Application…");
        add_app_button.clicked.connect (() => {
            if (app_chooser.visible == false) {
                app_chooser.show_all ();
            }
        });

        app_chooser = new SecurityPrivacy.Dialogs.AppChooser (add_app_button);
        app_chooser.modal = true;
        app_chooser.app_chosen.connect ((info) => {
            var file = File.new_for_path (info.filename);
            app_blacklist.block (file.get_basename ());
        });

        var add_folder_button = new Gtk.ToolButton (
            new Gtk.Image.from_icon_name ("folder-new-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
            null
        );
        add_folder_button.tooltip_text = _("Add Folder…");
        add_folder_button.clicked.connect (() => {
            var chooser = new Gtk.FileChooserNative (
                _("Select a folder to blacklist"),
                null,
                Gtk.FileChooserAction.SELECT_FOLDER,
                _("Add"),
                _("Cancel")
            );

            if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                string folder = chooser.get_filename ();
                if (this.path_blacklist.is_duplicate (folder) == false) {
                    path_blacklist.block (folder);
                }
            }

            chooser.destroy ();
        });

        var remove_button = new Gtk.ToolButton (
            new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
            null
        );
        remove_button.tooltip_text = _("Delete");
        remove_button.sensitive = false;
        remove_button.clicked.connect (() => {
            Gtk.TreePath path;
            Gtk.TreeViewColumn column;
            view.get_cursor (out path, out column);
            if (path == null)
                return;

            Gtk.TreeIter iter;
            list_store.get_iter (out iter, path);
            Value is_app;
            list_store.get_value (iter, NotColumns.IS_APP, out is_app);
            if (is_app.get_boolean () == true) {
                string name;
                list_store.get (iter, NotColumns.PATH, out name);
                app_blacklist.unblock (name);
            } else {
                string name;
                list_store.get (iter, NotColumns.PATH, out name);
                path_blacklist.unblock (name);
            }

#if VALA_0_36
            list_store.remove (ref iter);
#else
            list_store.remove (iter);
#endif
        });

        var list_toolbar = new Gtk.Toolbar ();
        list_toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        list_toolbar.set_icon_size (Gtk.IconSize.SMALL_TOOLBAR);
        list_toolbar.insert (add_app_button, -1);
        list_toolbar.insert (add_folder_button, -1);
        list_toolbar.insert (remove_button, -1);

        var frame_grid = new Gtk.Grid ();
        frame_grid.orientation = Gtk.Orientation.VERTICAL;
        frame_grid.add (scrolled);
        frame_grid.add (list_toolbar);

        var frame = new Gtk.Frame (null);
        frame.add (frame_grid);

        var record_label = new Gtk.Label (_("Do not collect data from the following:"));
        record_label.xalign = 0;

        row_spacing = 6;
        orientation = Gtk.Orientation.VERTICAL;
        add (record_label);
        add (frame);

        view.cursor_changed.connect (() => {
            Gtk.TreePath path;
            Gtk.TreeViewColumn column;
            view.get_cursor (out path, out column);
            remove_button.sensitive = (path != null);
        });

        Gtk.TreeIter iter;
        foreach (var app_info in AppInfo.get_all ()) {
            if (app_info is DesktopAppInfo) {
                var file = File.new_for_path (((DesktopAppInfo)app_info).filename);
                if (app_blacklist.all_apps.contains (file.get_basename ())) {
                    list_store.append (out iter);
                    list_store.set (iter, NotColumns.NAME, Markup.escape_text (app_info.get_display_name ()),
                            NotColumns.ICON, app_info.get_icon (), NotColumns.PATH, file.get_basename (),
                            NotColumns.IS_APP, true);
                }
            }
        }

        foreach (var folder in path_blacklist.all_folders) {
            list_store.append (out iter);
            var file = File.new_for_path (folder);
            list_store.set (iter, NotColumns.NAME, Markup.escape_text (file.get_basename ()),
                    NotColumns.ICON, new ThemedIcon ("folder"), NotColumns.PATH, folder,
                    NotColumns.IS_APP, false);
        }

        app_blacklist.application_added.connect ((name, ev) => {
            Gtk.TreeIter it;
            foreach (var app_info in AppInfo.get_all ()) {
                if (app_info is DesktopAppInfo) {
                    var file = File.new_for_path (((DesktopAppInfo)app_info).filename);
                    if (file.get_basename () == name) {
                        list_store.append (out it);
                        list_store.set (it, NotColumns.NAME, Markup.escape_text (app_info.get_display_name ()),
                                NotColumns.ICON, app_info.get_icon (), NotColumns.PATH, file.get_basename (),
                                NotColumns.IS_APP, true);
                        break;
                    }
                }
            }
        });

        path_blacklist.folder_added.connect ((path) => {
            Gtk.TreeIter it;
            list_store.append (out it);
            var file = File.new_for_path (path);
            list_store.set (it, NotColumns.NAME, Markup.escape_text (file.get_basename ()),
                    NotColumns.ICON, new ThemedIcon ("folder"), NotColumns.PATH, path,
                    NotColumns.IS_APP, false);
        });
    }
}
