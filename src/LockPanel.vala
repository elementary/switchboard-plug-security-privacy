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
    Settings xautolock;

    public LockPanel () {
        column_spacing = 12;
        row_spacing = 6;

        locker = new Settings ("apps.light-locker");
        xautolock = new Settings ("org.pantheon.xautolock");

        var screen_lock_combobox = new Gtk.ComboBoxText ();
        screen_lock_combobox.append_text (_("Never"));
        screen_lock_combobox.append_text (_("1 minute"));
        screen_lock_combobox.append_text (_("2 minutes"));
        screen_lock_combobox.append_text (_("3 minutes"));
        screen_lock_combobox.append_text (_("5 minutes"));
        screen_lock_combobox.append_text (_("10 minutes"));
        screen_lock_combobox.append_text (_("30 minutes"));
        screen_lock_combobox.append_text (_("1 hour"));
        var delay = xautolock.get_uint ("timeout");
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
            debug ("Combo box active: %i", screen_lock_combobox.active);
            switch (screen_lock_combobox.active) {
                case 7:
                    xautolock.set_uint ("timeout", 60);
                    break;
                case 6:
                    xautolock.set_uint ("timeout", 30);
                    break;
                case 5:
                    xautolock.set_uint ("timeout", 10);
                    break;
                case 4:
                    xautolock.set_uint ("timeout", 5);
                    break;
                case 3:
                    xautolock.set_uint ("timeout", 3);
                    break;
                case 2:
                    xautolock.set_uint ("timeout", 2);
                    break;
                case 1:
                    xautolock.set_uint ("timeout", 1);
                    break;
                default:
                    xautolock.set_uint ("timeout", 0);
                    break;
            }

            /* the set above races with the get in xautolock-elementary */
            xautolock.sync ();

            /* Kill running xautolock processes, since it can not reload its configuration */
            Process.spawn_sync (null, { "pkill", "xautolock*" },
                                Environ.get (), SpawnFlags.SEARCH_PATH, null);
            /* Launch a new one using the new timeout setting */
            Process.spawn_async (null, { "xautolock-elementary" },
                                 Environ.get (), SpawnFlags.SEARCH_PATH, null, null);
        });

        var lock_suspend_switch = new Gtk.Switch ();
        var lock_suspend_grid = new Gtk.Grid ();
        lock_suspend_grid.valign = Gtk.Align.CENTER;
        lock_suspend_grid.add (lock_suspend_switch);
        var lock_suspend_label = new Gtk.Label ("Ask for my password to unlock:");

        /* Synchronize lock_suspend_switch and GSettings value */
        lock_suspend_switch.active = locker.get_boolean ("lock-on-suspend");
        locker.bind ("lock-on-suspend", lock_suspend_switch, "active", SettingsBindFlags.DEFAULT);

        var fake_grid_left = new Gtk.Grid ();
        fake_grid_left.hexpand = true;
        var fake_grid_right = new Gtk.Grid ();
        fake_grid_right.hexpand = true;

        attach (fake_grid_left, 0, 0, 1, 1);
        attach (screen_lock_combobox, 3, 0, 1, 1);
        attach (lock_suspend_label, 1, 1, 1, 1);
        attach (lock_suspend_grid, 2, 1, 3, 1);
        attach (fake_grid_right, 4, 0, 1, 1);
    }
}
