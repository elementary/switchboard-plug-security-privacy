/*-
 * Copyright (c) 2014-2017 elementary LLC. (http://launchpad.net/switchboard-plug-security-privacy)
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
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class SecurityPrivacy.Widgets.ClearUsagePopover : Gtk.Popover {
    private Granite.Widgets.DatePicker to_datepicker;
    private Granite.Widgets.DatePicker from_datepicker;
    private Gtk.RadioButton all_time_radio;
    private Gtk.RadioButton from_radio;
    private Gtk.RadioButton past_hour_radio;
    private Gtk.RadioButton past_day_radio;
    private Gtk.RadioButton past_week_radio;
    private Gtk.RecentManager recent;

    private List<Gtk.RecentInfo> items;

    public ClearUsagePopover (Gtk.Widget? relative_to) {
        Object (relative_to: relative_to);
    }

    construct {
        recent = new Gtk.RecentManager ();

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
        clear_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        clear_button.halign = Gtk.Align.END;

        var grid = new Gtk.Grid ();
        grid.margin = 12;
        grid.column_spacing = 12;
        grid.row_spacing = 6;
        grid.attach (clear_label, 0, 0, 4, 1);
        grid.attach (past_hour_radio, 0, 1, 4, 1);
        grid.attach (past_day_radio, 0, 2, 4, 1);
        grid.attach (past_week_radio, 0, 3, 4, 1);
        grid.attach (from_radio, 0, 4, 1, 1);
        grid.attach (from_datepicker, 1, 4, 1, 1);
        grid.attach (to_label, 2, 4, 1, 1);
        grid.attach (to_datepicker, 3, 4, 1, 1);
        grid.attach (all_time_radio, 0, 5, 4, 1);
        grid.attach (clear_button, 0, 6, 4, 1);

        add (grid);

        clear_button.clicked.connect (() => {
            on_clear_data ();
        });
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

        hide ();
    }
}
