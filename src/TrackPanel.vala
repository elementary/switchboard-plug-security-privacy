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
    public TrackPanel () {
        column_spacing = 12;
        row_spacing = 6;
        margin = 12;
        margin_top = 0;
        
        var explain_label = new Gtk.Label (_("This operation system track of Files and Applications you've used to provide extra functionality. If other proples can see or access your account, you may wish to limit which items are recorded"));
        explain_label.wrap = true;
        explain_label.xalign = 0;

        var record_label = new Gtk.Label (_("Record file and application usage"));
        var record_switch = new Gtk.Switch ();
        record_switch.active = true;
        var switch_grid = new Gtk.Grid ();
        switch_grid.valign = Gtk.Align.CENTER;
        switch_grid.add (record_switch);

        var record_grid = new Gtk.Grid ();
        record_grid.column_spacing = 12;
        record_grid.attach (record_label, 0, 0, 1, 1); 
        record_grid.attach (switch_grid, 1, 0, 1, 1);

        var clear_togglebutton = new Gtk.ToggleButton.with_label (_("Clear Private Data…"));

        attach (explain_label, 0, 0, 1, 1);
        attach (record_grid, 0, 1, 1, 1);
    }
}