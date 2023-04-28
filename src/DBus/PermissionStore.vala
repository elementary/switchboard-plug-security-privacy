/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.freedesktop.impl.portal.PermissionStore", timeout = 120000)]
public interface SecurityPrivacy.PermissionStore : GLib.Object {
    public signal void changed (string table, string id, bool deleted, GLib.Variant data, [DBus (signature = "a{sas}")] GLib.Variant permissions);
    public abstract uint version {  get; }
    public abstract void lookup (string table, string id, [DBus (signature = "a{sas}")] out GLib.Variant permissions, out GLib.Variant data) throws DBusError, IOError;
    public abstract void set (string table, bool create, string id, [DBus (signature = "a{sas}")] GLib.Variant app_permissions, GLib.Variant data) throws DBusError, IOError;
    public abstract void delete (string table, string id) throws DBusError, IOError;
    public abstract void set_value (string table, bool create, string id, GLib.Variant data) throws DBusError, IOError;
    public abstract void set_permission (string table, bool create, string id, string app, string[] permissions) throws DBusError, IOError;
    public abstract void delete_permission (string table, string id, string app) throws DBusError, IOError;
    public abstract string[] get_permission (string table, string id, string app) throws DBusError, IOError;
    public abstract string[] list(string table) throws DBusError, IOError;
}
