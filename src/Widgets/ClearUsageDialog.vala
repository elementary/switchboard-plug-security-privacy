/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2014-2023 elementary, Inc. (https://elementary.io)
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class SecurityPrivacy.Widgets.ClearUsageDialog : Granite.MessageDialog {
    private Granite.DatePicker to_datepicker;
    private Granite.DatePicker from_datepicker;
    private Gtk.CheckButton all_time_radio;
    private Gtk.CheckButton from_radio;
    private Gtk.CheckButton past_hour_radio;
    private Gtk.CheckButton past_day_radio;
    private Gtk.CheckButton past_week_radio;
    private Gtk.RecentManager recent;

    private List<Gtk.RecentInfo> items;

    public ClearUsageDialog () {
        Object (
            buttons: Gtk.ButtonsType.CANCEL,
            image_icon: new ThemedIcon ("document-open-recent"),
            badge_icon: new ThemedIcon ("edit-delete"),
            primary_text: _("Clear system-collected file and app usage history"),
            secondary_text: _("The data from the selected time frame will be permanently deleted and cannot be restored")
        );
    }

    construct {
        recent = new Gtk.RecentManager ();

        past_hour_radio = new Gtk.CheckButton.with_label (_("The past hour"));

        past_day_radio = new Gtk.CheckButton.with_label (_("The past day")) {
            group = past_hour_radio
        };

        past_week_radio = new Gtk.CheckButton.with_label (_("The past week")) {
            group = past_hour_radio
        };

        from_radio = new Gtk.CheckButton.with_label (_("From:")) {
            group = past_hour_radio
        };

        all_time_radio = new Gtk.CheckButton.with_label (_("All time")) {
            group = past_hour_radio
        };

        from_datepicker = new Granite.DatePicker ();
        var to_label = new Gtk.Label (_("To:"));
        to_datepicker = new Granite.DatePicker ();

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6
        };
        grid.attach (past_hour_radio, 0, 1, 4);
        grid.attach (past_day_radio, 0, 2, 4);
        grid.attach (past_week_radio, 0, 3, 4);
        grid.attach (from_radio, 0, 4);
        grid.attach (from_datepicker, 1, 4);
        grid.attach (to_label, 2, 4);
        grid.attach (to_datepicker, 3, 4);
        grid.attach (all_time_radio, 0, 5, 4);

        custom_bin.append (grid);

        var clear_button = add_button (_("Clear History"), Gtk.ResponseType.APPLY);
        clear_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);

        response.connect ((response) => {
            if (response == Gtk.ResponseType.APPLY) {
                on_clear_data ();
            }

            close ();
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
                        // if (item.get_added () >= start / 1000) {
                        //     recent.remove_item (item.get_uri ());
                        // }
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
                        if (item.get_age () <= 1) {
                            recent.remove_item (item.get_uri ());
                        }
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
                        if (item.get_age () <= 7) {
                            recent.remove_item (item.get_uri ());
                        }
                    }
                } catch (Error err) {
                    critical (err.message);
                }
            }
        } else if (from_radio.active == true) {
            int64 start = from_datepicker.date.to_unix () * 1000;
            int64 end = to_datepicker.date.to_unix () * 1000;
            tr = new Zeitgeist.TimeRange (start, end);
            delete_history.begin (tr);

            //  Deletes files added during the given period
            if (recent.size > 0) {
                items = recent.get_items ();

                try {
                    foreach (var item in items) {
                        // if (item.get_added () >= start / 1000 && item.get_added () <= end / 1000) {
                        //     recent.remove_item (item.get_uri ());
                        // }
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
