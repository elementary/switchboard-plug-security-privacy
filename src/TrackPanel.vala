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
    private Gtk.Popover info_popover;
    private Gtk.Popover remove_popover;
    private AppsDialog appsdialog;
    private ApplicationBlacklist app_blacklist;
    private PathBlacklist path_blacklist;
    private Gtk.Grid record_grid;
    private Gtk.Grid exclude_grid;

    private enum Columns {
        ACTIVE,
        NAME,
        ICON,
        N_COLUMNS
    }

    private enum NotColumns {
        NAME,
        ICON,
        N_COLUMNS
    }

    public TrackPanel () {
        app_blacklist = new ApplicationBlacklist (blacklist);
        path_blacklist = new PathBlacklist (blacklist);

        var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");

        column_spacing = 12;
        row_spacing = 6;
        margin = 12;
        margin_top = 0;

        var record_label = new Gtk.Label ("");
        record_label.set_markup ("<b>%s</b>".printf (_("Record file and application usage:")));

        var record_switch = new Gtk.Switch ();
        record_switch.active = true;
        record_switch.notify["active"].connect (() => {
            record_grid.sensitive = record_switch.active;
            exclude_grid.sensitive = record_switch.active;
            var recording = !blacklist.get_incognito ();
            if (record_switch.active != recording) {
                blacklist.set_incognito (recording);
                privacy_settings.set_boolean ("remember-recent-files", record_switch.active);
                privacy_settings.set_boolean ("remember-app-usage", record_switch.active);
            }
        });

        var switch_grid = new Gtk.Grid ();
        switch_grid.valign = Gtk.Align.CENTER;
        switch_grid.add (record_switch);

        var info_button = new Gtk.ToggleButton ();
        info_button.image = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.MENU);
        info_button.relief = Gtk.ReliefStyle.NONE;
        info_button.notify["active"].connect (() => {
            if (info_button.active == false) {
                info_popover.hide ();
            }
            if (info_button.active == true) {
                info_popover.show_all ();
            }
        });

        /* Info Popover */

        var explain_label = new Gtk.Label (_("This operation system track of Files and Applications you've used to provide extra functionality. If other proples can see or access your account, you may wish to limit which items are recorded"));
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

        var remove_button = new Gtk.ToggleButton ();
        remove_button.image = new Gtk.Image.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.MENU);
        remove_button.relief = Gtk.ReliefStyle.NONE;
        remove_button.notify["active"].connect (() => {
            if (remove_button.active == false) {
                remove_popover.hide ();
            }
            if (remove_button.active == true) {
                remove_popover.show_all ();
            }
        });

        var remove_popover_grid = new Gtk.Grid ();
        remove_popover_grid.orientation = Gtk.Orientation.VERTICAL;
        remove_popover_grid.margin = 6;
        remove_popover_grid.column_spacing = 12;
        remove_popover_grid.row_spacing = 6;

        remove_popover = new Gtk.Popover (remove_button);
        remove_popover.add (remove_popover_grid);
        remove_popover.closed.connect (() => {
            remove_button.active = false;
        });

        var clear_label = new Gtk.Label (_("Delete records of which files and applications were used:"));

        var clear_button = new Gtk.Button.with_label (_("Clear Data"));
        clear_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        clear_button.clicked.connect (() => {
            remove_popover.hide ();
        });
        var clear_button_grid = new Gtk.Grid ();
        clear_button_grid.halign = Gtk.Align.END;
        clear_button_grid.add (clear_button);

        var past_hour_radio = new Gtk.RadioButton.with_label (null, _("In the past hour"));
        var past_day_radio = new Gtk.RadioButton.with_label_from_widget (past_hour_radio, _("In the past day"));
        var past_week_radio = new Gtk.RadioButton.with_label_from_widget (past_hour_radio, _("In the past week"));
        var from_radio = new Gtk.RadioButton.with_label_from_widget (past_hour_radio, _("From:"));
        var all_time_radio = new Gtk.RadioButton.with_label_from_widget (past_hour_radio, _("From all time"));

        var from_datepicker = new Granite.Widgets.DatePicker ();
        var to_label = new Gtk.Label (_("To:"));
        var to_datepicker = new Granite.Widgets.DatePicker ();

        var interval_grid = new Gtk.Grid ();
        interval_grid.column_spacing = 12;
        interval_grid.orientation = Gtk.Orientation.HORIZONTAL;
        interval_grid.add (from_radio);
        interval_grid.add (from_datepicker);
        interval_grid.add (to_label);
        interval_grid.add (to_datepicker);

        remove_popover_grid.add (clear_label);
        remove_popover_grid.add (past_hour_radio);
        remove_popover_grid.add (past_day_radio);
        remove_popover_grid.add (past_week_radio);
        remove_popover_grid.add (interval_grid);
        remove_popover_grid.add (all_time_radio);
        remove_popover_grid.add (clear_button_grid);

        var record_grid = new Gtk.Grid ();
        record_grid.column_spacing = 12;
        record_grid.halign = Gtk.Align.CENTER;
        record_grid.attach (record_label, 0, 0, 1, 1); 
        record_grid.attach (switch_grid, 1, 0, 1, 1);
        record_grid.attach (info_button, 2, 0, 1, 1);
        record_grid.attach (remove_button, 3, 0, 1, 1);

        var fake_grid_left = new Gtk.Grid ();
        fake_grid_left.hexpand = true;
        var fake_grid_right = new Gtk.Grid ();
        fake_grid_right.hexpand = true;

        attach (fake_grid_left, 0, 0, 1, 1);
        attach (record_grid, 1, 0, 2, 1);
        attach (fake_grid_right, 3, 0, 1, 1);
        create_include_treeview ();
        create_exclude_treeview ();

        record_switch.active = !blacklist.get_incognito ();
    }

    private void create_include_treeview () {
        var list_store = new Gtk.ListStore (Columns.N_COLUMNS, typeof (bool),
                typeof (string), typeof (string), typeof (string));

        var view = new Gtk.TreeView.with_model (list_store);
        view.vexpand = true;
        view.headers_visible = false;

        var celltoggle = new Gtk.CellRendererToggle ();
        celltoggle.activatable = true;
        var cell = new Gtk.CellRendererText ();
        var cellpixbuf = new Gtk.CellRendererPixbuf ();
        view.insert_column_with_attributes (-1, "", celltoggle, "active", Columns.ACTIVE, "activatable", true);
        view.insert_column_with_attributes (-1, "", cellpixbuf, "icon-name", Columns.ICON);
        view.insert_column_with_attributes (-1, "", cell, "markup", Columns.NAME);

        var frame = new Gtk.Frame (null);
        frame.expand = true;
        frame.add (view);

        var record_label = new Gtk.Label (_("Record:"));
        record_label.xalign = 0;

        record_grid = new Gtk.Grid ();
        record_grid.row_spacing = 6;
        record_grid.attach (record_label, 0, 0, 1, 1);
        record_grid.attach (frame, 0, 1, 1, 1);
        attach (record_grid, 1, 1, 1, 1);

        Gtk.TreeIter iter;
        list_store.append (out iter);
        list_store.set (iter, Columns.ACTIVE, true,
                Columns.NAME, _("Documents"),
                Columns.ICON, "x-office-document");
        list_store.append (out iter);
        list_store.set (iter, Columns.ACTIVE, true,
                Columns.NAME, _("Music"),
                Columns.ICON, "audio-x-generic");
        list_store.append (out iter);
        list_store.set (iter, Columns.ACTIVE, true,
                Columns.NAME, _("Pictures"),
                Columns.ICON, "image-x-generic");
        list_store.append (out iter);
        list_store.set (iter, Columns.ACTIVE, true,
                Columns.NAME, _("Presentations"),
                Columns.ICON, "x-office-presentation");
        list_store.append (out iter);
        list_store.set (iter, Columns.ACTIVE, true,
                Columns.NAME, _("Spreadsheets"),
                Columns.ICON, "x-office-spreadsheet");
        list_store.append (out iter);
        list_store.set (iter, Columns.ACTIVE, true,
                Columns.NAME, _("Videos"),
                Columns.ICON, "video-x-generic");
        list_store.append (out iter);
        list_store.set (iter, Columns.ACTIVE, true,
                Columns.NAME, _("Chat Logs"),
                Columns.ICON, "internet-chat");
    }

    private void create_exclude_treeview () {
        var list_store = new Gtk.ListStore (NotColumns.N_COLUMNS, typeof (string),
                typeof (Icon), typeof (string));

        var view = new Gtk.TreeView.with_model (list_store);
        view.vexpand = true;
        view.headers_visible = false;

        var cell = new Gtk.CellRendererText ();
        var cellpixbuf = new Gtk.CellRendererPixbuf ();
        view.insert_column_with_attributes (-1, "", cellpixbuf, "gicon", NotColumns.ICON);
        view.insert_column_with_attributes (-1, "", cell, "markup", NotColumns.NAME);

        var frame = new Gtk.Frame (null);
        frame.expand = true;
        frame.add (view);

        var add_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        add_button.clicked.connect (() => {
            var popover_grid = new Gtk.Grid ();
            popover_grid.margin = 6;
            popover_grid.column_spacing = 12;
            popover_grid.row_spacing = 6;
            popover_grid.orientation = Gtk.Orientation.VERTICAL;
            var add_popover = new Gtk.Popover (add_button);
            var application_button = new Gtk.Button.with_label (_("Add Application…"));
            application_button.clicked.connect (() => {
                if (appsdialog == null || appsdialog.visible == false) {
                    appsdialog = new AppsDialog (app_blacklist);
                    appsdialog.show_all ();
                    add_popover.hide ();
                }
            });
            var folder_button = new Gtk.Button.with_label (_("Add Folder…"));
            folder_button.clicked.connect (() => {
                var chooser = new Gtk.FileChooserDialog (_("Select a folder to blacklist"), null, Gtk.FileChooserAction.SELECT_FOLDER);
                chooser.add_buttons (_("Add"), Gtk.ResponseType.OK, _("Cancel"), Gtk.ResponseType.CANCEL);
                int res = chooser.run ();
                chooser.hide ();
                if (res == Gtk.ResponseType.OK) {
                    string folder = chooser.get_filename ();
                    if(this.path_blacklist.is_duplicate(folder) == false) {
                        path_blacklist.block (folder);
                    }
                }
            });

            popover_grid.add (application_button);
            popover_grid.add (folder_button);
            add_popover.add (popover_grid);
            add_popover.show_all ();
        });

        var remove_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        remove_button.sensitive = false;
        remove_button.clicked.connect (() => {
            Gtk.TreePath path;
            Gtk.TreeViewColumn column;
            view.get_cursor (out path, out column);
            
        });

        var list_toolbar = new Gtk.Toolbar ();
        list_toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        list_toolbar.set_icon_size (Gtk.IconSize.SMALL_TOOLBAR);
        list_toolbar.insert (add_button, -1);
        list_toolbar.insert (remove_button, -1);

        var frame_grid = new Gtk.Grid ();
        frame_grid.orientation = Gtk.Orientation.VERTICAL;
        frame_grid.add (frame);
        frame_grid.add (list_toolbar);

        var record_label = new Gtk.Label (_("Do not record:"));
        record_label.xalign = 0;

        exclude_grid = new Gtk.Grid ();
        exclude_grid.row_spacing = 6;
        exclude_grid.orientation = Gtk.Orientation.VERTICAL;
        exclude_grid.add (record_label);
        exclude_grid.add (frame_grid);
        attach (exclude_grid, 2, 1, 1, 1);

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
                            NotColumns.ICON, app_info.get_icon ());
                }
            }
        }

        app_blacklist.application_added.connect ((name, ev) => {
            Gtk.TreeIter it;
            foreach (var app_info in AppInfo.get_all ()) {
                if (app_info is DesktopAppInfo) {
                    var file = File.new_for_path (((DesktopAppInfo)app_info).filename);
                    if (app_blacklist.all_apps.contains (file.get_basename ())) {
                        list_store.append (out it);
                        list_store.set (it, NotColumns.NAME, Markup.escape_text (app_info.get_display_name ()),
                                NotColumns.ICON, app_info.get_icon ());
                        break;
                    }
                }
            }
        });

        path_blacklist.folder_added.connect ((path) => {
            Gtk.TreeIter it;
            list_store.append (out it);
            var file = File.new_for_path (path);
            var icon
            list_store.set (it, NotColumns.NAME, Markup.escape_text (file.get_basename ()),
                    NotColumns.ICON, app_info.get_icon ());
        });
    }
}