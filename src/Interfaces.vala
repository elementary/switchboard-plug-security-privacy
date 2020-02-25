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

public struct UnitChange {
    string type;
    string filename;
    string dest;
}

public struct EnableUnitFilesResult {
    bool carries_install_info;
    UnitChange[] changes;
}

[DBus (name = "org.freedesktop.systemd1.Manager")]
public interface SecurityPrivacy.ISystemdManager : Object {
    public abstract GLib.Variant? enable_unit_files (string[] files, bool runtime, bool force) throws Error;
    public abstract UnitChange[] disable_unit_files (string[] files, bool runtime) throws Error;
    public abstract string start_unit (string name, string mode) throws Error;
    public abstract string stop_unit (string name, string mode) throws Error;
    public abstract string get_unit_file_state (string file) throws Error;
}

[DBus (name = "org.fedoraproject.FirewallD1")]
public interface SecurityPrivacy.IFirewalld : Object {
    public abstract void add_rich_rule (string rule) throws Error;
    public abstract string get_default_zone () throws Error;
}