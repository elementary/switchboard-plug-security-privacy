/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */
[DBus (name = "org.freedesktop.impl.portal.PermissionStore", timeout = 120000)]
public interface SecurityPrivacy.PermissionStore : GLib.Object {
    public signal void changed (string table, string id, bool deleted, GLib.Variant data, GLib.HashTable<string, string[]> permissions);
    public abstract void lookup (string table, string id, out GLib.HashTable<string, string[]> permissions, out GLib.Variant data) throws DBusError, IOError;
    public abstract void set (string table, bool create, string id, GLib.HashTable<string, string[]> app_permissions, GLib.Variant data) throws DBusError, IOError;
    public abstract void set_permission (string table, bool create, string id, string app, string[] permissions) throws DBusError, IOError;
}
