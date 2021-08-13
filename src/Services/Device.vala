/*
 * Copyright 2011–2021 elementary, Inc. (https://launchpad.net/switchboard-plug-power)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 */

public class SecurityPrivacy.Device : Object {
    private Fprint? fprint;
    private FprintDevice? fprint_device;

    private string device_path = "/net/reactivated/Fprint/Device/0";

    public Device () {
        connect_to_bus ();
    }
    private bool connect_to_bus () {
        try {
            fprint_device = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_FPRINT_PATH, device_path, DBusProxyFlags.NONE);
            debug (("Connection to UPower device %s established").printf (device_path));
        } catch (Error e) {
            critical ("Connecting to UPower device failed: %s", e.message);
        }

        return fprint_device != null;
    }
}
