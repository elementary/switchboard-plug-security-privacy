/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.freedesktop.impl.portal.PermissionStore")]
interface SecurityPrivacy.PermissionStore : Object {
    public abstract void delete_permission (string table, string id, string app) throws Error;
    public abstract void delete (string table, string id) throws Error;
    public abstract void list (string table, out string[] ids) throws Error;
    public abstract void set_permission (string table, bool create, string id, string app, string[] permissions) throws Error;
    public abstract void set_value (string table, bool create, string id, Variant data) throws Error;
    public abstract void lookup (string table, string id, out HashTable<string, Variant> permissions, out Variant data) throws Error;
}

// Set              (IN  s      table,
//                   IN  b      create,
//                   IN  s      id,
//                   IN  a{sas} app_permissions,
//                   IN  v      data);
