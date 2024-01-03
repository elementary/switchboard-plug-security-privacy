/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2014-2023 elementary, Inc. (https://elementary.io)
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public class SecurityPrivacy.Plug : Switchboard.Plug {
    private Polkit.Permission permission;
    private Gtk.Paned paned;
    private Gtk.Stack stack;

    private const string FIREWALL = "firewall";
    private const string HOUSEKEEPING = "housekeeping";
    private const string HISTORY = "tracking";
    private const string LOCKING = "locking";
    private const string LOCATION = "location";

    public Plug () {
        GLib.Intl.bindtextdomain (Build.GETTEXT_PACKAGE, Build.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");

        Object (category: Category.PERSONAL,
                code_name: "io.elementary.switchboard.security-privacy",
                display_name: _("Security & Privacy"),
                description: _("Configure firewall, screen lock, and activity information"),
                icon: "preferences-system-privacy",
                supported_settings: new Gee.TreeMap<string, string?> (null, null));

        supported_settings.set ("privacy", HISTORY);
        supported_settings.set ("privacy/location", LOCATION);
        supported_settings.set ("privacy/trash", HOUSEKEEPING);
        supported_settings.set ("security/firewall", FIREWALL);
        supported_settings.set ("security/locking", LOCKING);
        supported_settings.set ("security", null);

        // DEPRECATED
        supported_settings.set ("security/housekeeping", HOUSEKEEPING);
        supported_settings.set ("security/privacy", HISTORY);
        supported_settings.set ("security/privacy/location", LOCATION);
        supported_settings.set ("security/screensaver", LOCKING);
    }

    public override Gtk.Widget get_widget () {
        if (paned == null) {
            try {
                permission = new Polkit.Permission.sync (
                    "io.elementary.switchboard.security-privacy",
                    new Polkit.UnixProcess (Posix.getpid ())
                );
            } catch (Error e) {
                critical (e.message);
            }

            var label = new Gtk.Label (_("Some settings require administrator rights to be changed"));

            var lock_button = new Gtk.LockButton (permission);

            var infobar = new Gtk.InfoBar () {
                message_type = INFO,
                revealed = false
            };
            infobar.get_content_area ().add (label);
            infobar.get_action_area ().add (lock_button);

            var tracking = new TrackPanel ();
            var locking = new LockPanel ();
            var firewall = new FirewallPanel (permission);
            var housekeeping = new HouseKeepingPanel ();
            var location = new LocationPanel ();

            stack = new Gtk.Stack ();
            stack.add_titled (tracking, HISTORY, _("Privacy"));
            stack.add_titled (locking, LOCKING, _("Locking"));
            stack.add_titled (firewall, FIREWALL, _("Firewall"));
            stack.add_titled (housekeeping, HOUSEKEEPING, _("Housekeeping"));
            stack.add_titled (location, LOCATION, _("Location Services"));

            var box = new Gtk.Box (VERTICAL, 0);
            box.add (infobar);
            box.add (stack);

            var settings_sidebar = new Granite.SettingsSidebar (stack);

            paned = new Gtk.Paned (HORIZONTAL);
            paned.add1 (settings_sidebar);
            paned.add2 (box);
            paned.show_all ();

            stack.notify["visible-child"].connect (() => {
                infobar.revealed = !permission.allowed && stack.visible_child == firewall;
            });

            permission.notify["allowed"].connect (() => {
                infobar.revealed = !permission.allowed && stack.visible_child == firewall;
            });
        }

        return paned;
    }

    public override void shown () { }

    public override void hidden () { }

    public override void search_callback (string location) {
        stack.set_visible_child_name (location);
    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        var map = new Gee.TreeMap<string, string> (null, null);
        map.set ("%s → %s".printf (display_name, _("History")), HISTORY);
        map.set ("%s → %s → %s".printf (display_name, _("History"), _("Clear History")), HISTORY);
        map.set ("%s → %s".printf (display_name, _("Locking")), LOCKING);
        map.set ("%s → %s → %s".printf (display_name, _("Locking"), _("Lock on sleep")), HISTORY);
        map.set ("%s → %s → %s".printf (display_name, _("Locking"), _("Lock after sceen turns off")), HISTORY);
        map.set ("%s → %s".printf (display_name, _("Firewall")), FIREWALL);
        map.set ("%s → %s".printf (display_name, _("Housekeeping")), HOUSEKEEPING);
        map.set ("%s → %s → %s".printf (
            display_name,
            _("Housekeeping"),
            _("Automatically delete old temporary files")
        ), HOUSEKEEPING);
        map.set ("%s → %s → %s".printf (
            display_name,
            _("Housekeeping"),
            _("Automatically delete old screenshot files")
        ), HOUSEKEEPING);
        map.set ("%s → %s → %s".printf (
            display_name,
            _("Housekeeping"),
            _("Automatically delete old trashed files")
        ), HOUSEKEEPING);
        map.set ("%s → %s → %s".printf (
            display_name,
            _("Housekeeping"),
            _("Number of days to keep trashed and temporary files")
        ), HOUSEKEEPING);
        map.set ("%s → %s".printf (display_name, _("Location Services")), LOCATION);
        return map;
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Security & Privacy plug");
    var plug = new SecurityPrivacy.Plug ();
    return plug;
}
