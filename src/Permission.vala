/*
 * Copyright (c) 2011-2016 elementary LLC. (https://launchpad.net/switchboard-plug-power)
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

 namespace SecurityPrivacy {
    public static Polkit.Permission? permission_fingerprint = null;

    public static Polkit.Permission? get_permission () {
        if (permission_fingerprint != null) {
            return permission_fingerprint;
        }

        try {
            permission_fingerprint = new Polkit.Permission.sync ("io.elementary.switchboard.security-privacy.administrator", new Polkit.UnixProcess (Posix.getpid ()));
            return permission_fingerprint;
        } catch (Error e) {
            critical (e.message);
            return null;
        }
    }
}
