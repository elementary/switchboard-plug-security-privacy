// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014-2015 elementary LLC. (https://launchpad.net/switchboard-plug-security-privacy)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class SecurityPrivacy.LockPanel : ServicePanel {

    Settings locker;

    public LockPanel () {
        Object (icon_name: "system-lock-screen",
                title: _("Locking"));
    }

    construct {
        locker = new Settings ("apps.light-locker");

        var lock_suspend_label = new Gtk.Label (_("Lock on sleep:"));
        var lock_suspend_switch = new Gtk.Switch ();
        var lock_sleep_label = new Gtk.Label (_("Lock after screen turns off:"));
        var lock_sleep_switch = new Gtk.Switch ();

        /* Synchronize lock_suspend_switch and GSettings value */
        lock_suspend_switch.active = locker.get_boolean ("lock-on-suspend");
        locker.bind ("lock-on-suspend", lock_suspend_switch, "active", SettingsBindFlags.DEFAULT);

        if (locker.get_uint ("lock-after-screensaver") > 0)
            lock_sleep_switch.active = true;
        else
            lock_sleep_switch.active = false;

        locker.changed["lock-after-screensaver"].connect (() => {
            if (locker.get_uint ("lock-after-screensaver") > 0)
                lock_sleep_switch.active = true;
            else
                lock_sleep_switch.active = false;
        });

        lock_sleep_switch.notify["active"].connect (() => {
            if (lock_sleep_switch.active)
                locker.set_uint ("lock-after-screensaver", 1);
            else
                locker.set_uint ("lock-after-screensaver", 0);
        });

        lock_suspend_label.halign = Gtk.Align.END;
        lock_sleep_label.halign = Gtk.Align.END;
        lock_suspend_label.valign = Gtk.Align.CENTER;
        lock_sleep_label.valign = Gtk.Align.CENTER;
        lock_suspend_switch.halign = Gtk.Align.START;
        lock_sleep_switch.halign = Gtk.Align.START;

        content_area.hexpand = true;
        content_area.halign = Gtk.Align.CENTER;
        content_area.attach (lock_suspend_label, 0, 0, 1, 1);
        content_area.attach (lock_sleep_label, 0, 1, 1, 1);
        content_area.attach (lock_suspend_switch, 1, 0, 1, 1);
        content_area.attach (lock_sleep_switch, 1, 1, 1, 1);
    }
}
