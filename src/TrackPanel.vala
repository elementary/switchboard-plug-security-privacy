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

public class SecurityPrivacy.TrackPanel : Gtk.Grid {

    private Gtk.RecentManager recent;
    private List<Gtk.RecentInfo> items;

    private Gtk.Popover info_popover;
    private Gtk.Popover remove_popover;
    private Dialogs.AppChooser app_chooser;
    private ApplicationBlacklist app_blacklist;
    private PathBlacklist path_blacklist;
    private FileTypeBlacklist filetype_blacklist;
    private Gtk.Grid record_grid;
    private Gtk.Container description_frame;
    private Gtk.Grid exclude_grid;

    private Granite.Widgets.DatePicker to_datepicker;
    private Granite.Widgets.DatePicker from_datepicker;
    private Gtk.RadioButton all_time_radio;
    private Gtk.RadioButton from_radio;
    private Gtk.RadioButton past_hour_radio;
    private Gtk.RadioButton past_day_radio;
    private Gtk.RadioButton past_week_radio;

    private enum Columns {
        ACTIVE,
        NAME,
        ICON,
        FILE_TYPE,
        N_COLUMNS
    }

    private enum NotColumns {
        NAME,
        ICON,
        PATH,
        IS_APP,
        N_COLUMNS
    }

    public TrackPanel () {
        app_blacklist = new ApplicationBlacklist (blacklist);
        path_blacklist = new PathBlacklist (blacklist);
        filetype_blacklist = new FileTypeBlacklist (blacklist);
        recent = new Gtk.RecentManager ();

        var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");

        var record_label = new Gtk.Label (_("Privacy Mode:"));
        record_label.get_style_context ().add_class ("h4");

        var record_switch = new Gtk.Switch ();
        record_switch.valign = Gtk.Align.CENTER;

        record_switch.notify["active"].connect (() => {
            bool privacy_mode = record_switch.active;
            record_grid.visible = !privacy_mode;
            exclude_grid.visible = !privacy_mode;
            description_frame.visible = privacy_mode;
            if (privacy_mode != blacklist.get_incognito ()) {
                blacklist.set_incognito (privacy_mode);
                privacy_settings.set_boolean ("remember-recent-files", !privacy_mode);
                privacy_settings.set_boolean ("remember-app-usage", !privacy_mode);
            }
        });

        create_description_panel ();

        var info_button = new Gtk.ToggleButton ();
        info_button.tooltip_text = _("Read more…");
        info_button.image = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.MENU);
        info_button.relief = Gtk.ReliefStyle.NONE;
        info_button.notify["active"].connect (() => {
            if (info_button.active == false) {
                info_popover.hide ();
            } else {
                info_popover.show_all ();
            }
        });

        var record_grid = new Gtk.Grid ();
        record_grid.column_spacing = 12;
        record_grid.add (record_label); 
        record_grid.add (record_switch);
        record_grid.add (info_button);

        /* Info Popover */

        var explain_label = new Gtk.Label (_("This operating system can gather useful statistics about file and app usage to provide extra functionality. If other people can see or access your account, you may wish to limit which items are recorded."));
        explain_label.wrap = true;
        explain_label.max_width_chars = 60;
        
        var info_popover_grid = new Gtk.Grid ();
        info_popover_grid.margin = 6;

        info_popover = new Gtk.Popover (info_button);
        info_popover.add (info_popover_grid);
        info_popover.closed.connect (() => {
            info_button.active = false;
        });

        info_popover_grid.add (explain_label);

        /* Remove Popover */

        var clear_data = new Gtk.ToggleButton.with_label (_("Clear Usage Data…"));
        clear_data.halign = Gtk.Align.END;
        clear_data.notify["active"].connect (() => {
            if (clear_data.active == false) {
                remove_popover.hide ();
            } else {
                remove_popover.show_all ();
            }
        });

        var clear_label = new Gtk.Label (_("Remove system-collected file and application usage data from:"));
        clear_label.halign = Gtk.Align.START;

        past_hour_radio = new Gtk.RadioButton.with_label (null, _("The past hour"));
        past_day_radio = new Gtk.RadioButton.with_label_from_widget (past_hour_radio, _("The past day"));
        past_week_radio = new Gtk.RadioButton.with_label_from_widget (past_hour_radio, _("The past week"));
        from_radio = new Gtk.RadioButton.with_label_from_widget (past_hour_radio, _("From:"));
        all_time_radio = new Gtk.RadioButton.with_label_from_widget (past_hour_radio, _("All time"));

        from_datepicker = new Granite.Widgets.DatePicker ();
        var to_label = new Gtk.Label (_("To:"));
        to_datepicker = new Granite.Widgets.DatePicker ();

        var clear_button = new Gtk.Button.with_label (_("Clear Data"));
        clear_button.halign = Gtk.Align.END;
        clear_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        clear_button.clicked.connect (() => {
            on_clear_data ();
        });

        var remove_popover_grid = new Gtk.Grid ();
        remove_popover_grid.margin = 12;
        remove_popover_grid.column_spacing = 12;
        remove_popover_grid.row_spacing = 6;

        remove_popover_grid.attach (clear_label, 0, 0, 4, 1);
        remove_popover_grid.attach (past_hour_radio, 0, 1, 4, 1);
        remove_popover_grid.attach (past_day_radio, 0, 2, 4, 1);
        remove_popover_grid.attach (past_week_radio, 0, 3, 4, 1);
        remove_popover_grid.attach (from_radio, 0, 4, 1, 1);
        remove_popover_grid.attach (from_datepicker, 1, 4, 1, 1);
        remove_popover_grid.attach (to_label, 2, 4, 1, 1);
        remove_popover_grid.attach (to_datepicker, 3, 4, 1, 1);
        remove_popover_grid.attach (all_time_radio, 0, 5, 4, 1);
        remove_popover_grid.attach (clear_button, 0, 6, 4, 1);

        remove_popover = new Gtk.Popover (clear_data);
        remove_popover.add (remove_popover_grid);
        remove_popover.closed.connect (() => {
            clear_data.active = false;
        });

        column_spacing = 12;
        row_spacing = 12;
        margin = 12;
        margin_top = 0;

        create_include_treeview ();
        create_exclude_treeview ();
        attach (record_grid, 0, 1, 1, 1);
        attach (clear_data, 1, 1, 1, 1);

        record_switch.active = blacklist.get_incognito ();
    }

    private async void delete_history (Zeitgeist.TimeRange tr) {
        var events = new GenericArray<Zeitgeist.Event> ();
        events.add (new Zeitgeist.Event ());
        var zg_log = new Zeitgeist.Log ();
        try {
            uint32[] ids = yield zg_log.find_event_ids (tr, events, Zeitgeist.StorageState.ANY, 0, 0, null);
            Array<uint32> del_ids = new Array<uint32> ();
            del_ids.append_vals (ids, ids.length);
            yield zg_log.delete_events (del_ids, null);
        } catch (Error e) {
            critical (e.message);
        }
    }

    private string get_operating_system_name () {
        string system = _("Your system");
        try {
            string contents = null;
            if (FileUtils.get_contents ("/etc/os-release", out contents)) {
                int start = contents.index_of ("NAME=") + "NAME=".length;
                int end = contents.index_of_char ('\n');
                system = contents.substring (start, end - start).replace ("\"", "");
            }
        } catch (FileError e) {
        }
        return system;
    }

    private void create_description_panel () {
        description_frame = new Gtk.Frame (null);
        description_frame.expand = true;
        description_frame.no_show_all = true;

        string system = get_operating_system_name ();

        var icon = "view-private";
        var title = _("%s is in Privacy Mode").printf (system);
        var description = ("%s\n\n%s\n\n%s".printf (
                    _("While in Privacy Mode, this operating system won't retain any further data or statistics about file and application usage."),
                    _("The additional functionality that this data provides will be affected."),
                    _("This will not prevent apps from recording their own usage data like browser history.")));

        var alert = new Granite.Widgets.AlertView (title, description, icon);
        alert.show_all ();

        description_frame.add (alert);

        attach (description_frame, 0, 0, 2, 1);
    }

    private void create_include_treeview () {
        var list_store = new Gtk.ListStore (Columns.N_COLUMNS, typeof (bool),
                typeof (string), typeof (string), typeof (string));

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
        var cellpixbuf = new Gtk.CellRendererPixbuf ();
        cellpixbuf.stock_size = Gtk.IconSize.DND;
        view.insert_column_with_attributes (-1, "", celltoggle, "active", Columns.ACTIVE);
        view.insert_column_with_attributes (-1, "", cellpixbuf, "icon-name", Columns.ICON);
        view.insert_column_with_attributes (-1, "", cell, "markup", Columns.NAME);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.shadow_type = Gtk.ShadowType.IN;
        scrolled.expand = true;
        scrolled.add (view);

        var record_label = new Gtk.Label (_("Data Sources:"));
        record_label.xalign = 0;

        record_grid = new Gtk.Grid ();
        record_grid.row_spacing = 6;
        record_grid.attach (record_label, 0, 0, 1, 1);
        record_grid.attach (scrolled, 0, 1, 1, 1);
        attach (record_grid, 0, 0, 1, 1);

        set_inclue_iter_to_liststore (list_store, _("Chat Logs"), "internet-chat", Zeitgeist.NMO.IMMESSAGE);
        set_inclue_iter_to_liststore (list_store, _("Documents"), "x-office-document", Zeitgeist.NFO.DOCUMENT);
        set_inclue_iter_to_liststore (list_store, _("Music"), "audio-x-generic", Zeitgeist.NFO.AUDIO);
        set_inclue_iter_to_liststore (list_store, _("Pictures"), "image-x-generic", Zeitgeist.NFO.IMAGE);
        set_inclue_iter_to_liststore (list_store, _("Presentations"), "x-office-presentation", Zeitgeist.NFO.PRESENTATION);
        set_inclue_iter_to_liststore (list_store, _("Spreadsheets"), "x-office-spreadsheet", Zeitgeist.NFO.SPREADSHEET);
        set_inclue_iter_to_liststore (list_store, _("Videos"), "video-x-generic", Zeitgeist.NFO.VIDEO);
    }

    private void set_inclue_iter_to_liststore (Gtk.ListStore list_store, string name, string icon, string file_type) {
        Gtk.TreeIter iter;
        list_store.append (out iter);
        bool active = (filetype_blacklist.all_filetypes.contains (file_type) == false);
        list_store.set (iter, Columns.ACTIVE, active, Columns.NAME, name,
                        Columns.ICON, icon, Columns.FILE_TYPE, file_type);
    }

    private void create_exclude_treeview () {
        var list_store = new Gtk.ListStore (NotColumns.N_COLUMNS, typeof (string),
                typeof (Icon), typeof (string), typeof (bool));

        var view = new Gtk.TreeView.with_model (list_store);
        view.vexpand = true;
        view.headers_visible = false;

        var cell = new Gtk.CellRendererText ();
        var cellpixbuf = new Gtk.CellRendererPixbuf ();
        cellpixbuf.stock_size = Gtk.IconSize.DND;
        view.insert_column_with_attributes (-1, "", cellpixbuf, "gicon", NotColumns.ICON);
        view.insert_column_with_attributes (-1, "", cell, "markup", NotColumns.NAME);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.shadow_type = Gtk.ShadowType.IN;
        scrolled.expand = true;
        scrolled.add (view);

        var add_app_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("application-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        add_app_button.tooltip_text = _("Add Application…");
        add_app_button.clicked.connect (() => {
            if (app_chooser.visible == false) {
                app_chooser.show_all ();
            }
        });

        app_chooser = new Dialogs.AppChooser (add_app_button);
        app_chooser.modal = true;
        app_chooser.app_chosen.connect ((info) => {
            var file = File.new_for_path (info.filename);
            app_blacklist.block (file.get_basename ());
        });

        var add_folder_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("folder-new-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        add_folder_button.tooltip_text = _("Add Folder…");
        add_folder_button.clicked.connect (() => {
            var chooser = new Gtk.FileChooserDialog (_("Select a folder to blacklist"), null, Gtk.FileChooserAction.SELECT_FOLDER);
            chooser.add_buttons (_("Cancel"), Gtk.ResponseType.CANCEL, _("Add"), Gtk.ResponseType.OK);
            int res = chooser.run ();
            chooser.hide ();
            if (res == Gtk.ResponseType.OK) {
                string folder = chooser.get_filename ();
                if (this.path_blacklist.is_duplicate (folder) == false) {
                    path_blacklist.block (folder);
                }
            }
        });

        var remove_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        remove_button.tooltip_text = _("Delete");
        remove_button.sensitive = false;
        remove_button.clicked.connect (() => {
            Gtk.TreePath path;
            Gtk.TreeViewColumn column;
            view.get_cursor (out path, out column);
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

            list_store.remove (iter);
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

        var record_label = new Gtk.Label (_("Do not collect data from the following:"));
        record_label.xalign = 0;

        exclude_grid = new Gtk.Grid ();
        exclude_grid.row_spacing = 6;
        exclude_grid.orientation = Gtk.Orientation.VERTICAL;
        exclude_grid.add (record_label);
        exclude_grid.add (frame_grid);
        attach (exclude_grid, 1, 0, 1, 1);

        view.cursor_changed.connect (() => {
            remove_button.sensitive = true;
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

    private void on_clear_data () {
        Zeitgeist.TimeRange tr;

        if (past_hour_radio.active == true) {
            int range = 360000;//60*60*1000;
            int64 end = Zeitgeist.Timestamp.from_now ();
            int64 start = end - range;
            tr = new Zeitgeist.TimeRange (start, end);
            delete_history.begin (tr);

            //  Deletes files added in the last hour
            if (recent.size > 0) {
                items = recent.get_items ();

                try {
                    foreach (var item in items) {
                        if (item.get_added () >= start/1000)
                            recent.remove_item (item.get_uri ());
                    }
                } catch (Error err) {
                    critical (err.message);
                }
            }
        } else if (past_day_radio.active == true) {
            int range = 8640000;//24*60*60*1000;
            int64 end = Zeitgeist.Timestamp.from_now ();
            int64 start = end - range;
            tr = new Zeitgeist.TimeRange (start, end);
            delete_history.begin (tr);

            //  Deletes files added in the last day
            if (recent.size > 0) {
                items = recent.get_items ();

                try {
                    foreach (var item in items) {
                        if (item.get_age () <= 1)
                            recent.remove_item (item.get_uri ());
                    }
                } catch (Error err) {
                    critical (err.message);
                }
            }
        } else if (past_week_radio.active == true) {
            int range = 60480000;//7*24*60*60*1000;
            int64 end = Zeitgeist.Timestamp.from_now ();
            int64 start = end - range;
            tr = new Zeitgeist.TimeRange (start, end);
            delete_history.begin (tr);

            //  Deletes files added in the last week
            if (recent.size > 0) {
                items = recent.get_items ();

                try {
                    foreach (var item in items) {
                        if (item.get_age () <= 7)
                            recent.remove_item (item.get_uri ());
                    }
                } catch (Error err) {
                    critical (err.message);
                }
            }
        } else if (from_radio.active == true) {
            int64 start = from_datepicker.date.to_unix ()*1000;
            int64 end = to_datepicker.date.to_unix ()*1000;
            tr = new Zeitgeist.TimeRange (start, end);
            delete_history.begin (tr);

            //  Deletes files added during the given period
            if (recent.size > 0) {
                items = recent.get_items ();

                try {
                    foreach (var item in items) {
                        if (item.get_added () >= start/1000 && item.get_added () <= end/1000)
                            recent.remove_item (item.get_uri ());
                    }
                } catch (Error err) {
                    critical (err.message);
                }
            }
        } else if (all_time_radio.active == true) {
            tr = new Zeitgeist.TimeRange.anytime ();
            delete_history.begin (tr);

            //  Deletes all recent files
            if (recent.size > 0) {
                try {
                    recent.purge_items ();
                } catch (Error err) {
                    critical (err.message);
                }
            }
        }
        remove_popover.hide ();
    }
}
