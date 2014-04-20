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
    Gtk.Popover info_popover;
    Gtk.Popover remove_popover;

    public TrackPanel () {
        column_spacing = 12;
        row_spacing = 6;
        margin = 12;
        margin_top = 0;

        var record_label = new Gtk.Label ("");
        record_label.set_markup ("<b>%s</b>".printf (_("Record file and application usage:")));

        var record_switch = new Gtk.Switch ();
        record_switch.active = true;
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
        record_grid.attach (record_label, 0, 0, 1, 1); 
        record_grid.attach (switch_grid, 1, 0, 1, 1);
        record_grid.attach (info_button, 2, 0, 1, 1);
        record_grid.attach (remove_button, 3, 0, 1, 1);

        var fake_grid_left = new Gtk.Grid ();
        fake_grid_left.hexpand = true;
        var fake_grid_right = new Gtk.Grid ();
        fake_grid_right.hexpand = true;

        attach (fake_grid_left, 0, 0, 1, 1);
        attach (record_grid, 1, 1, 1, 1);
        attach (fake_grid_right, 2, 0, 1, 1);
    }
}