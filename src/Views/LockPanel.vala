/*-
 * Copyright 2014-2020 elementary, Inc. (https://elementary.io)
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

public class SecurityPrivacy.LockPanel : Granite.SimpleSettingsPage {
    private Fprint? fprint;
    private FprintDevice? fprint_device;

    private string device_path = "/net/reactivated/Fprint/Device/0";

    public LockPanel () {
        Object (
            icon_name: "system-lock-screen",
            title: _("Locking")
        );
    }

    construct {
        var permission = get_permission ();
        print (permission.allowed.to_string ());
        try {
            fprint = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_FPRINT_NAME, DBUS_FPRINT_PATH, DBusProxyFlags.NONE);

            print (("Connection to Fprint device %s established").printf (device_path));
        } catch (Error e) {
            critical ("Connecting to UPower device failed: %s", e.message);
        }

        //  try {
        //      var fp_path = fprint.GetDefaultDevice ();
        //      print (fp_path);
        //  } catch (Error e) {
        //      print ("error" + e.message);
        //  }

        //  foreach (var device_path in fprint.GetDevices ()) {
        //      print (device_path.to_string ());
        //  };
        var lock_suspend_label = new Gtk.Label (_("Lock on suspend:"));
        lock_suspend_label.halign = Gtk.Align.END;

        var lock_suspend_switch = new Gtk.Switch ();
        lock_suspend_switch.halign = Gtk.Align.START;

        var lock_sleep_label = new Gtk.Label (_("Lock after screen turns off:"));
        lock_sleep_label.halign = Gtk.Align.END;

        var lock_sleep_switch = new Gtk.Switch ();
        lock_sleep_switch.halign = Gtk.Align.START;

        content_area.hexpand = true;
        content_area.halign = Gtk.Align.CENTER;
        content_area.attach (lock_suspend_label, 0, 0);
        content_area.attach (lock_suspend_switch, 1, 0);
        content_area.attach (lock_sleep_label, 0, 1);
        content_area.attach (lock_sleep_switch, 1, 1);

        var gnome_screensaver_settings = new GLib.Settings ("org.gnome.desktop.screensaver");
        var screensaver_settings = new GLib.Settings ("io.elementary.desktop.screensaver");
        gnome_screensaver_settings.bind ("lock-enabled", lock_sleep_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        screensaver_settings.bind ("lock-on-suspend", lock_suspend_switch, "active", GLib.SettingsBindFlags.DEFAULT);
    }
}
