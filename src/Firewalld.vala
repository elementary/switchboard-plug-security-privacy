/*-
 * Copyright (c) 2020 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

public class SecurityPrivacy.Firewalld {
    private const string FWD_SERVICE = "firewalld.service";

    private ISystemdManager? systemd_manager = null;

    private static GLib.Once<Firewalld> instance;
    public static unowned Firewalld get_default () {
        return instance.once (() => { return new Firewalld (); });
    }

    public bool get_status () throws Error {
        try {
            unowned ISystemdManager manager = get_systemd_manager ();
            if (manager == null) {
                return false;
            }

            return manager.get_unit_file_state (FWD_SERVICE) == "enabled";
        } catch (Error e) {
            throw e;
        }
    }

    public void set_status (bool status) throws Error {
        try {
            unowned ISystemdManager manager = get_systemd_manager ();
            if (manager == null) {
                return;
            }            

            if (status) {
                manager.enable_unit_files ({ FWD_SERVICE }, false, false);
                manager.start_unit (FWD_SERVICE, "replace");
            } else {
                manager.stop_unit (FWD_SERVICE, "replace");
                manager.disable_unit_files ({ FWD_SERVICE }, false);
            }
        } catch (Error e) {
            throw e;
        }
    }

    private unowned ISystemdManager get_systemd_manager () throws Error {
        if (systemd_manager == null) {
            try {
                systemd_manager = Bus.get_proxy_sync (GLib.BusType.SYSTEM, "org.freedesktop.systemd1", "/org/freedesktop/systemd1");
            } catch (IOError e) {
                throw e;
            }
        }

        return systemd_manager;
    }
}