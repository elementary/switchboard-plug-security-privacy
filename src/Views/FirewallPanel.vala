/*-
 * Copyright (c) 2014-2025 elementary, Inc. (https://elementary.io)
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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public class SecurityPrivacy.FirewallPanel : Switchboard.SettingsPage {
    private Gtk.Frame frame;
    private Gtk.Button unlock_button;
    private SecurityPrivacy.AbstractFirewallBackend backend;
    private Gtk.ListStore list_store;
    private Gtk.TreeView view;
    private bool loading = false;
    private Gtk.Button remove_button;
    private Polkit.Permission? permission;

    private enum Columns {
        ACTION,
        PROTOCOL,
        DIRECTION,
        TO,
        FROM,
        V6,
        ENABLED,
        RULE,
        N_COLUMNS
    }

    public FirewallPanel () {
        Object (
            activatable: true,
            icon: new ThemedIcon ("network-firewall"),
            title: _("Firewall")
        );
    }

    construct {
        backend = new SecurityPrivacy.UFWBackend ();

        status_switch.sensitive = false;
        status_switch.notify["active"].connect (() => {
            if (!loading) {
                if (status_switch.active) {
                    backend.enable_firewall ();
                } else {
                    backend.disable_firewall ();
                }
            }
            update_status ();
        });

        create_treeview ();

        unlock_button = add_button (_("Unlock"));
        unlock_button.clicked.connect (on_unlock_button_clicked);
    }

    private async void on_unlock_button_clicked () {
        var has_permission = yield get_permission ();
        if (!has_permission) {
            critical ("Couldn't unlock firewall panel: no permission");
            return;
        }

        unlock_button.sensitive = false;
        loading = true;
        status_switch.active = backend.is_firewall_enabled ();
        remove_button.sensitive = false;
        loading = false;
        status_switch.sensitive = true;
    }

    private async bool get_permission () {
        if (permission == null) {
            try {
                permission = yield new Polkit.Permission (
                    "io.elementary.settings.security-privacy",
                    new Polkit.UnixProcess (Posix.getpid ())
                );
            } catch (Error e) {
                critical (e.message);
                return false;
            }
        }

        if (!permission.allowed) {
            try {
                yield permission.acquire_async ();
            } catch (Error e) {
                critical (e.message);
                return false;
            }
        }

        return true;
    }

    private void reload_rule_ids () {
        foreach (unowned var rule in backend.list_rules ()) {
            string key = rule.to_hash ();
            Gtk.TreeModelForeachFunc update_row = (model, path, iter) => {
                Value val;

                list_store.get_value (iter, Columns.RULE, out val);
                var tree_rule = val as Rule;
                string tree_hash = tree_rule.to_hash ();
                if (key == tree_hash) {
                    tree_rule.id = rule.id;
                    list_store.set_value (iter, Columns.RULE, tree_rule);
                    return true;
                }

                return false;
            };
            list_store.foreach (update_row);
        }
    }

    private void show_rules () {
        list_store.clear ();
        remove_button.sensitive = false;

        var rules = backend.list_rules ();

        foreach (var rule in rules) {
            if (rule.enabled) {
                add_rule (rule, true, rule.to_hash ());
            } else {
                add_rule (rule, false, rule.to_hash ());
            }
        }
    }

    public void add_rule (Rule rule, bool enabled = true, string hash = "") {
        // prints all rule information to the console for debugging
        debug ("Rule: %s, Action: %s, Protocol: %s, Direction: %s, From: %s, To: %s, Version: %s",
               rule.id, rule.action.to_string (), rule.protocol.to_string (),
               rule.direction.to_string (), rule.from, rule.to, rule.version.to_string ());
        string action = _("Unknown");
        switch (rule.action) {
            case ALLOW:
                action = _("Allow");
                break;
            case DENY:
                action = _("Deny");
                break;
            case REJECT:
                action = _("Reject");
                break;
            case LIMIT:
                action = _("Limit");
                break;
        }

        string protocol = _("Unknown");
        switch (rule.protocol) {
            case UDP:
                protocol = "UDP";
                break;
            case TCP:
                protocol = "TCP";
                break;
            case BOTH:
                protocol = "TCP/UDP";
                break;
        }

        string direction = _("Unknown");
        if (rule.direction == IN) {
            direction = _("In");
        } else if (rule.direction == OUT) {
            direction = _("Out");
        }

        string version = _("Unknown");
        if (rule.version == IPV6) {
            version = "IPv6";
        } else if (rule.version == IPV4) {
            version = "IPv4";
        }

        string from = "";
        string to = "";
        if (rule.from_ports != "") {
            if (rule.from_ports.contains (":") || rule.from_ports.contains (",")) {
                from = _("%s Ports %s").printf (rule.from, rule.from_ports.replace (":", "-"));
            } else {
                from = _("%s Port %s").printf (rule.from, rule.from_ports.replace (":", "-"));
            }
        } else {
            from = rule.from;
        }

        if (rule.to_ports != "") {
            if (rule.to_ports.contains (":") || rule.to_ports.contains (",")) {
                to = _("%s Ports %s").printf (rule.to, rule.to_ports.replace (":", "-"));
            } else {
                to = _("%s Port %s").printf (rule.to, rule.to_ports.replace (":", "-"));
            }
        } else {
            to = rule.to;
        }

        Gtk.TreeIter iter;
        list_store.append (out iter);
        list_store.set (iter, Columns.ACTION, action, Columns.PROTOCOL, protocol,
                Columns.DIRECTION, direction, Columns.V6, version, Columns.ENABLED, enabled,
                Columns.RULE, rule, Columns.TO, to.strip (), Columns.FROM, from.strip ());
    }

    private void create_treeview () {
        list_store = new Gtk.ListStore (Columns.N_COLUMNS, typeof (string),
                                                           typeof (string),
                                                           typeof (string),
                                                           typeof (string),
                                                           typeof (string),
                                                           typeof (string),
                                                           typeof (bool),
                                                           typeof (Rule));

        // The View:
        view = new Gtk.TreeView.with_model (list_store) {
            activate_on_single_click = true,
            hexpand = true,
            vexpand = true
        };

        var celltoggle = new Gtk.CellRendererToggle ();
        var cell = new Gtk.CellRendererText ();
        view.insert_column_with_attributes (-1, _("Enabled"), celltoggle, "active", Columns.ENABLED);
        view.insert_column_with_attributes (-1, _("Version"), cell, "text", Columns.V6);
        view.insert_column_with_attributes (-1, _("Action"), cell, "text", Columns.ACTION);
        view.insert_column_with_attributes (-1, _("Protocol"), cell, "text", Columns.PROTOCOL);
        view.insert_column_with_attributes (-1, _("Direction"), cell, "text", Columns.DIRECTION);
        view.insert_column_with_attributes (-1, _("To"), cell, "text", Columns.TO);
        view.insert_column_with_attributes (-1, _("From"), cell, "text", Columns.FROM);

        celltoggle.toggled.connect ((path) => {
            Value active;
            Gtk.TreeIter iter;
            list_store.get_iter (out iter, new Gtk.TreePath.from_string (path));
            list_store.get_value (iter, Columns.ENABLED, out active);
            var is_active = active.get_boolean ();

            Value rule_value;
            list_store.get_value (iter, Columns.RULE, out rule_value);
            Rule rule = (Rule)rule_value.get_object ();
            if (is_active) {
                backend.disable_rule (rule);
                list_store.set (iter, Columns.ENABLED, false);
            } else {
                backend.enable_rule (rule);
                list_store.set (iter, Columns.ENABLED, true);
            }

            reload_rule_ids ();
        });

        var add_button = new Gtk.Button.from_icon_name ("list-add-symbolic");

        remove_button = new Gtk.Button.from_icon_name ("list-remove-symbolic") {
            sensitive = false
        };

        var actionbar = new Gtk.ActionBar ();
        actionbar.add_css_class (Granite.STYLE_CLASS_FLAT);
        actionbar.pack_start (add_button);
        actionbar.pack_start (remove_button);

        var scrolled = new Gtk.ScrolledWindow () {
            child = view
        };

        var view_box = new Gtk.Box (VERTICAL, 0);
        view_box.append (scrolled);
        view_box.append (actionbar);

        frame = new Gtk.Frame (null) {
            child = view_box,
            sensitive = false
        };

        child = frame;
        show_end_title_buttons = true;

        view.cursor_changed.connect (() => {
            remove_button.sensitive = true;
        });

        add_button.clicked.connect (() => {
            var policy_combobox = new Gtk.ComboBoxText ();
            policy_combobox.append_text (_("Allow"));
            policy_combobox.append_text (_("Deny"));
            policy_combobox.append_text (_("Reject"));
            policy_combobox.append_text (_("Limit"));
            policy_combobox.active = 0;

            var policy_label = new Gtk.Label (_("Action:")) {
                mnemonic_widget = policy_combobox,
                xalign = 1
            };

            var protocol_combobox = new Gtk.ComboBoxText ();
            protocol_combobox.append_text ("TCP");
            protocol_combobox.append_text ("UDP");
            protocol_combobox.active = 0;

            var protocol_label = new Gtk.Label (_("Protocol:")) {
                mnemonic_widget = protocol_combobox,
                xalign = 1
            };

            var version_combobox = new Gtk.ComboBoxText ();
            version_combobox.append_text ("IPv4");
            version_combobox.append_text ("IPv6");
            version_combobox.append_text (_("Both"));
            version_combobox.active = 0;

            var version_label = new Gtk.Label (_("Version:")) {
                mnemonic_widget = version_combobox,
                xalign = 1
            };

            var direction_combobox = new Gtk.ComboBoxText ();
            direction_combobox.append_text (_("In"));
            direction_combobox.append_text (_("Out"));
            direction_combobox.active = 0;

            var direction_label = new Gtk.Label (_("Direction:")) {
                mnemonic_widget = direction_combobox,
                xalign = 1
            };

            var ports_entry = new Gtk.Entry () {
                input_purpose = NUMBER,
                placeholder_text = _("%d or %d-%d").printf (80, 80, 85)
            };

            var ports_label = new Gtk.Label (_("Ports:")) {
                mnemonic_widget = ports_entry,
                xalign = 1
            };

            var do_add_button = new Gtk.Button.with_label (_("Add Rule")) {
                halign = END,
                hexpand = true,
                margin_top = 6
            };
            do_add_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

            var popover_grid = new Gtk.Grid () {
                margin_top = 12,
                margin_end = 12,
                margin_start = 12,
                margin_bottom = 12,
                column_spacing = 12,
                row_spacing = 6
            };
            popover_grid.attach (policy_label, 0, 0);
            popover_grid.attach (policy_combobox, 1, 0);
            popover_grid.attach (protocol_label, 0, 1);
            popover_grid.attach (protocol_combobox, 1, 1);
            popover_grid.attach (version_label, 0, 2);
            popover_grid.attach (version_combobox, 1, 2);
            popover_grid.attach (direction_label, 0, 3);
            popover_grid.attach (direction_combobox, 1, 3);
            popover_grid.attach (ports_label, 0, 4);
            popover_grid.attach (ports_entry, 1, 4);
            popover_grid.attach (do_add_button, 0, 5, 2);

            var add_popover = new Gtk.Popover () {
                child = popover_grid
            };
            add_popover.set_parent (add_button);
            add_popover.popup ();

            do_add_button.clicked.connect (() => {
                var rule = new Rule ();

                if (direction_combobox.active == 0) {
                    rule.direction = IN;
                } else {
                    rule.direction = OUT;
                }

                if (protocol_combobox.active == 0) {
                    rule.protocol = TCP;
                } else {
                    rule.protocol = UDP;
                }

                switch (policy_combobox.active) {
                    case 0:
                        rule.action = ALLOW;
                        break;
                    case 1:
                        rule.action = DENY;
                        break;
                    case 2:
                        rule.action = REJECT;
                        break;
                    case 3:
                        rule.action = LIMIT;
                        break;
                }

                switch (version_combobox.active) {
                    case 0:
                        rule.version = IPV4;
                        break;
                    case 1:
                        rule.version = IPV6;
                        break;
                    case 2:
                        rule.version = BOTH;
                        break;
                }

                rule.to_ports = ports_entry.text.replace ("-", ":");
                backend.add_rule (rule);
                add_popover.popdown ();
                show_rules ();
            });
        });

        remove_button.clicked.connect (() => {
            Gtk.TreePath path;
            Gtk.TreeViewColumn column;
            view.get_cursor (out path, out column);
            Gtk.TreeIter iter;
            list_store.get_iter (out iter, path);
            Value val;
            list_store.get_value (iter, Columns.RULE, out val);
            var rule = val.get_object () as Rule;
            backend.remove_rule (rule);
            show_rules ();
        });
    }

    private void update_status () {
        frame.sensitive = status_switch.active;

        if (status_switch.active) {
            status_type = SUCCESS;
            status = _("Enabled");
            show_rules ();
        } else {
            status_type = OFFLINE;
            status = _("Disabled");
        }
    }
}
