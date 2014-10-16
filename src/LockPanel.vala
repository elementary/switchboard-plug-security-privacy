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

    public LockPanel () {
        column_spacing = 12;
        row_spacing = 6;

        locker = new Settings ("apps.light-locker");

/* TODO: figure out how to do inactivity timeouts on the light-locker side of things
         (see https://github.com/the-cavalry/light-locker/issues/41)

        var screen_lock_combobox = new Gtk.ComboBoxText ();
        screen_lock_combobox.append_text (_("After display turns off"));
        screen_lock_combobox.append_text (_("30 seconds"));
        screen_lock_combobox.append_text (_("1 minute"));
        screen_lock_combobox.append_text (_("2 minutes"));
        screen_lock_combobox.append_text (_("3 minutes"));
        screen_lock_combobox.append_text (_("5 minutes"));
        screen_lock_combobox.append_text (_("10 minutes"));
        screen_lock_combobox.append_text (_("30 minutes"));
        screen_lock_combobox.append_text (_("1 hour"));
        var delay = screensaver.get_uint ("lock-delay");
        if (delay >= 3600) {
            screen_lock_combobox.active = 8;
        } else if (delay >= 1800) {
            screen_lock_combobox.active = 7;
        } else if (delay >= 600) {
            screen_lock_combobox.active = 6;
        } else if (delay >= 300) {
            screen_lock_combobox.active = 5;
        } else if (delay >= 180) {
            screen_lock_combobox.active = 4;
        } else if (delay >= 120) {
            screen_lock_combobox.active = 3;
        } else if (delay >= 60) {
            screen_lock_combobox.active = 2;
        } else if (delay > 0) {
            screen_lock_combobox.active = 1;
        } else {
            screen_lock_combobox.active = 0;
        }
        screen_lock_combobox.notify["active"].connect (() => {
            switch (screen_lock_combobox.active) {
                case 8:
                    screensaver.set_uint ("lock-delay", 3600);
                    break;
                case 7:
                    screensaver.set_uint ("lock-delay", 1800);
                    break;
                case 6:
                    screensaver.set_uint ("lock-delay", 600);
                    break;
                case 5:
                    screensaver.set_uint ("lock-delay", 300);
                    break;
                case 4:
                    screensaver.set_uint ("lock-delay", 180);
                    break;
                case 3:
                    screensaver.set_uint ("lock-delay", 120);
                    break;
                case 2:
                    screensaver.set_uint ("lock-delay", 60);
                    break;
                case 1:
                    screensaver.set_uint ("lock-delay", 30);
                    break;
                default:
                    screensaver.set_uint ("lock-delay", 0);
                    break;
            }
        });
*/

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
        //attach (screen_lock_combobox, 3, 0, 1, 1);
        attach (lock_suspend_label, 1, 1, 1, 1);
        attach (lock_suspend_grid, 2, 1, 3, 1);
        attach (fake_grid_right, 4, 0, 1, 1);
    }
}
