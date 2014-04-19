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

    Settings notification;
    Settings screensaver;

    public LockPanel () {
        column_spacing = 12;
        row_spacing = 6;

        notification = new Settings ("org.gnome.desktop.notifications");
        screensaver = new Settings ("org.gnome.desktop.screensaver");

        var screen_lock_label = new Gtk.Label ("");
        screen_lock_label.set_markup ("<b>%s</b>".printf (_("Screen lock:")));

        var screen_lock_switch = new Gtk.Switch ();
        screen_lock_switch.active = true;
        var switch_grid = new Gtk.Grid ();
        switch_grid.valign = Gtk.Align.CENTER;
        switch_grid.add (screen_lock_switch);

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

        var ask_checkbutton = new Gtk.CheckButton.with_label (_("Ask for my password to unlock"));
        ask_checkbutton.notify["active"].connect (() => {
            screensaver.set_boolean ("ubuntu-lock-on-suspend", ask_checkbutton.active);
        });
        ask_checkbutton.active = screensaver.get_boolean ("ubuntu-lock-on-suspend");
        var notification_checkbutton = new Gtk.CheckButton.with_label (_("Show notifications on lockscreen"));
        notification_checkbutton.active = notification.get_boolean ("show-in-lock-screen");
        notification_checkbutton.notify["active"].connect (() => {
            notification.set_boolean ("show-in-lock-screen", notification_checkbutton.active);
        });

        screen_lock_switch.notify["active"].connect (() => {
            screen_lock_combobox.sensitive = screen_lock_switch.active;
            ask_checkbutton.sensitive = screen_lock_switch.active;
            notification_checkbutton.sensitive = screen_lock_switch.active;
            screensaver.set_boolean ("lock-enabled", screen_lock_switch.active);
        });
        screen_lock_switch.active = screensaver.get_boolean ("lock-enabled");

        var fake_grid_left = new Gtk.Grid ();
        fake_grid_left.hexpand = true;
        var fake_grid_right = new Gtk.Grid ();
        fake_grid_right.hexpand = true;

        attach (fake_grid_left, 0, 0, 1, 1);
        attach (screen_lock_label, 1, 0, 1, 1);
        attach (switch_grid, 2, 0, 1, 1);
        attach (screen_lock_combobox, 3, 0, 1, 1);
        attach (ask_checkbutton, 2, 1, 2, 1);
        attach (notification_checkbutton, 2, 2, 2, 1);
        attach (fake_grid_right, 4, 0, 1, 1);
    }
}