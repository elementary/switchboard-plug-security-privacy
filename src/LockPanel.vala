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

public class SecurityPrivacy.LockPanel : Gtk.Grid {

    Settings locker;
    Settings autolock;

    public LockPanel () {
        column_spacing = 12;
        row_spacing = 6;

        locker = new Settings ("apps.light-locker");
        autolock = new Settings ("org.pantheon.autolock");

        var screen_lock_combobox = new Gtk.ComboBoxText ();
        screen_lock_combobox.append_text (_("Never"));
        screen_lock_combobox.append_text (_("1 minute"));
        screen_lock_combobox.append_text (_("2 minutes"));
        screen_lock_combobox.append_text (_("3 minutes"));
        screen_lock_combobox.append_text (_("5 minutes"));
        screen_lock_combobox.append_text (_("10 minutes"));
        screen_lock_combobox.append_text (_("30 minutes"));
        screen_lock_combobox.append_text (_("1 hour"));
        var delay = autolock.get_uint ("timeout");
        if (delay >= 60) {
            screen_lock_combobox.active = 7;
        } else if (delay >= 30) {
            screen_lock_combobox.active = 6;
        } else if (delay >= 10) {
            screen_lock_combobox.active = 5;
        } else if (delay >= 5) {
            screen_lock_combobox.active = 4;
        } else if (delay >= 3) {
            screen_lock_combobox.active = 3;
        } else if (delay >= 2) {
            screen_lock_combobox.active = 2;
        } else if (delay > 0) {
            screen_lock_combobox.active = 1;
        } else {
            screen_lock_combobox.active = 0;
        }
        screen_lock_combobox.notify["active"].connect (() => {
            switch (screen_lock_combobox.active) {
                case 7:
                    autolock.set_uint ("timeout", 60);
                    break;
                case 6:
                    autolock.set_uint ("timeout", 30);
                    break;
                case 5:
                    autolock.set_uint ("timeout", 10);
                    break;
                case 4:
                    autolock.set_uint ("timeout", 5);
                    break;
                case 3:
                    autolock.set_uint ("timeout", 3);
                    break;
                case 2:
                    autolock.set_uint ("timeout", 2);
                    break;
                case 1:
                    autolock.set_uint ("timeout", 1);
                    break;
                default:
                    autolock.set_uint ("timeout", 0);
                    break;
            }

            /* the set above races with the get in autolock-elementary */
            Settings.sync ();

            try {
                Process.spawn_async (null, { "autolock-elementary" },
                                     Environ.get (), SpawnFlags.SEARCH_PATH, null, null);
            } catch (SpawnError e) {
                warning ("Failed to reset autolock timeout: %s", e.message);
            }
        });

        var timeout_label = new Gtk.Label (_("Lock screen after:"));

        var lock_suspend_label = new Gtk.Label (_("Lock on sleep:"));
        var lock_suspend_switch = new Gtk.Switch ();

        /* Synchronize lock_suspend_switch and GSettings value */
        lock_suspend_switch.active = locker.get_boolean ("lock-on-suspend");
        locker.bind ("lock-on-suspend", lock_suspend_switch, "active", SettingsBindFlags.DEFAULT);

        timeout_label.margin_top = 15;
        lock_suspend_label.margin_bottom = 15;
        screen_lock_combobox.margin_top = 10;
        lock_suspend_switch.margin_bottom = 10;

        lock_suspend_label.halign = Gtk.Align.END;
        timeout_label.halign = Gtk.Align.END;
        lock_suspend_switch.halign = Gtk.Align.START;
        screen_lock_combobox.halign = Gtk.Align.START;

        var grid_left = new Gtk.Grid ();
        grid_left.expand = true;
        grid_left.halign = Gtk.Align.END;
        grid_left.valign = Gtk.Align.CENTER;
        var grid_right = new Gtk.Grid ();
        grid_right.expand = true;
        grid_right.halign = Gtk.Align.START;
        grid_right.valign = Gtk.Align.CENTER;

        grid_left.attach (lock_suspend_label, 0, 0, 1, 1);
        grid_left.attach (timeout_label, 0, 1, 1, 1);
        grid_right.attach (lock_suspend_switch, 0, 0, 1, 1);
        grid_right.attach (screen_lock_combobox, 0, 1, 1, 1);

        attach (grid_left, 0, 0, 1, 1);
        attach (grid_right, 1, 0, 1, 1);
    }
}
