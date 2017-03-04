// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014 elementary LLC. ((http://launchpad.net/switchboard-plug-security-privacy)
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

public class SecurityPrivacy.FirewallPanel : Gtk.Grid {
    private Gtk.ListStore list_store;
    private Gtk.TreeView view;
    private Gtk.Toolbar list_toolbar;
    private bool loading = false;
    private Gtk.Popover add_popover;
    private Gtk.ToolButton remove_button;
    public Gtk.Switch status_switch;

    private enum Columns {
        ACTION,
        PROTOCOL,
        DIRECTION,
        PORTS,
        V6,
        ENABLED,
        RULE,
        N_COLUMNS
    }

    public FirewallPanel () {
        Object (column_spacing: 12,
                margin: 12,
                row_spacing: 6);
    }

    construct {
        var status_icon = new Gtk.Image.from_icon_name ("network-firewall", Gtk.IconSize.DIALOG);

        var status_label = new Gtk.Label (_("Firewall"));
        status_label.get_style_context ().add_class ("h2");
        status_label.hexpand = true;
        status_label.xalign = 0;

        status_switch = new Gtk.Switch ();
        status_switch.valign = Gtk.Align.CENTER;

        status_switch.notify["active"].connect (() => {
            if (loading == false) {
                view.sensitive = status_switch.active;
                UFWHelpers.set_status (status_switch.active);
            }
            show_rules ();
        });

        attach (status_icon, 0, 0, 1, 1);
        attach (status_label, 1, 0, 1, 1);
        attach (status_switch, 2, 0, 1, 1);

        create_treeview ();

        sensitive = false;

        lock_button.get_permission ().notify["allowed"].connect (() => {
            loading = true;
            sensitive = lock_button.get_permission ().allowed;
            status_switch.active = UFWHelpers.get_status ();
            list_store.clear ();
            remove_button.sensitive = false;
            if (status_switch.active == true) {
                view.sensitive = true;
                foreach (var rule in UFWHelpers.get_rules ()) {
                    add_rule (rule);
                }
            } else {
                view.sensitive = false;
            }
            loading = false;
        });
    }

    private void show_rules () {
        list_store.clear ();
        remove_button.sensitive = false;
        foreach (var rule in UFWHelpers.get_rules ()) {
            add_rule (rule);
        }
    }

    public void add_rule (UFWHelpers.Rule rule) {
        Gtk.TreeIter iter;
        string action = _("Unknown");
        if (rule.action == UFWHelpers.Rule.Action.ALLOW) {
            action = _("Allow");
        } else if (rule.action == UFWHelpers.Rule.Action.DENY) {
            action = _("Deny");
        } else if (rule.action == UFWHelpers.Rule.Action.REJECT) {
            action = _("Reject");
        } else if (rule.action == UFWHelpers.Rule.Action.LIMIT) {
            action = _("Limit");
        }
        string protocol = _("Unknown");
        if (rule.protocol == UFWHelpers.Rule.Protocol.UDP) {
            protocol = "UDP";
        } else if (rule.protocol == UFWHelpers.Rule.Protocol.TCP) {
            protocol = "TCP";
        }
        string direction = _("Unknown");
        if (rule.direction == UFWHelpers.Rule.Direction.IN) {
            direction = _("In");
        } else if (rule.direction == UFWHelpers.Rule.Direction.OUT) {
            direction = _("Out");
        }
        list_store.append (out iter);
        list_store.set (iter, Columns.ACTION, action, Columns.PROTOCOL, protocol,
                Columns.DIRECTION, direction, Columns.PORTS, rule.ports.replace (":", "-"),
                Columns.V6, rule.is_v6 ? "IPv6" : "IPv4", Columns.ENABLED, true, Columns.RULE, rule);
    }

    private void create_treeview () {
        list_store = new Gtk.ListStore (Columns.N_COLUMNS, typeof (string),
                typeof (string), typeof (string), typeof (string), typeof (string), typeof(bool), typeof (UFWHelpers.Rule));

        // The View:
        view = new Gtk.TreeView.with_model (list_store);
        view.vexpand = true;

        var celltoggle = new Gtk.CellRendererToggle ();
        var cell = new Gtk.CellRendererText ();
        view.insert_column_with_attributes (-1, _("Enabled"), celltoggle, "active", Columns.ENABLED);
        view.insert_column_with_attributes (-1, _("Type"), cell, "text", Columns.V6);
        view.insert_column_with_attributes (-1, _("Action"), cell, "text", Columns.ACTION);
        view.insert_column_with_attributes (-1, _("Protocol"), cell, "text", Columns.PROTOCOL);
        view.insert_column_with_attributes (-1, _("Direction"), cell, "text", Columns.DIRECTION);
        view.insert_column_with_attributes (-1, _("Ports"), cell, "text", Columns.PORTS);

        list_toolbar = new Gtk.Toolbar ();
        list_toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        list_toolbar.set_icon_size (Gtk.IconSize.SMALL_TOOLBAR);
        var add_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        add_button.clicked.connect (() => {
            var popover_grid = new Gtk.Grid ();
            popover_grid.margin = 6;
            popover_grid.margin_top = 12;
            popover_grid.margin_start = 12;
            popover_grid.margin_bottom = 9;
            popover_grid.column_spacing = 12;
            popover_grid.row_spacing = 6;
            add_popover = new Gtk.Popover (add_button);
            add_popover.add (popover_grid);

            var policy_label = new Gtk.Label (_("Action:"));
            policy_label.xalign = 1;
            var policy_combobox = new Gtk.ComboBoxText ();
            policy_combobox.append_text (_("Allow"));
            policy_combobox.append_text (_("Deny"));
            policy_combobox.append_text (_("Reject"));
            policy_combobox.append_text (_("Limit"));
            policy_combobox.active = 0;

            var protocol_label = new Gtk.Label (_("Protocol:"));
            protocol_label.xalign = 1;
            var protocol_combobox = new Gtk.ComboBoxText ();
            protocol_combobox.append_text ("TCP");
            protocol_combobox.append_text ("UDP");
            protocol_combobox.active = 0;

            var direction_label = new Gtk.Label (_("Direction:"));
            direction_label.xalign = 1;
            var direction_combobox = new Gtk.ComboBoxText ();
            direction_combobox.append_text (_("In"));
            direction_combobox.append_text (_("Out"));
            direction_combobox.active = 0;

            var ports_label = new Gtk.Label (_("Ports:"));
            ports_label.xalign = 1;
            var ports_entry = new Gtk.Entry ();
            ports_entry.input_purpose = Gtk.InputPurpose.NUMBER;
            ports_entry.placeholder_text = _("%d or %d-%d").printf (80, 80, 85);

            var do_add_button = new Gtk.Button.with_label (_("Add Rule"));
            do_add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            do_add_button.clicked.connect (() => {
                var rule = new UFWHelpers.Rule ();
                if (direction_combobox.active == 0)
                    rule.direction = UFWHelpers.Rule.Direction.IN;
                else
                    rule.direction = UFWHelpers.Rule.Direction.OUT;

                if (protocol_combobox.active == 0)
                    rule.protocol = UFWHelpers.Rule.Protocol.TCP;
                else
                    rule.protocol = UFWHelpers.Rule.Protocol.UDP;

                if (policy_combobox.active == 0)
                    rule.action = UFWHelpers.Rule.Action.ALLOW;
                else if (policy_combobox.active == 1)
                    rule.action = UFWHelpers.Rule.Action.DENY;
                else if (policy_combobox.active == 2)
                    rule.action = UFWHelpers.Rule.Action.REJECT;
                else
                    rule.action = UFWHelpers.Rule.Action.LIMIT;

                rule.ports = ports_entry.text.replace ("-", ":");
                UFWHelpers.add_rule (rule);
                add_popover.hide ();
                show_rules ();
            });

            var add_button_grid = new Gtk.Grid ();
            add_button_grid.add (do_add_button);
            add_button_grid.halign = Gtk.Align.END;

            popover_grid.attach (policy_label, 0, 0, 1, 1);
            popover_grid.attach (policy_combobox, 1, 0, 1, 1);
            popover_grid.attach (protocol_label, 0, 1, 1, 1);
            popover_grid.attach (protocol_combobox, 1, 1, 1, 1);
            popover_grid.attach (direction_label, 0, 2, 1, 1);
            popover_grid.attach (direction_combobox, 1, 2, 1, 1);
            popover_grid.attach (ports_label, 0, 3, 1, 1);
            popover_grid.attach (ports_entry, 1, 3, 1, 1);
            popover_grid.attach (add_button_grid, 0, 4, 2, 1);

            add_popover.show_all ();
        });

        list_toolbar.insert (add_button, -1);
        remove_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        remove_button.sensitive = false;
        remove_button.clicked.connect (() => {
            Gtk.TreePath path;
            Gtk.TreeViewColumn column;
            view.get_cursor (out path, out column);
            Gtk.TreeIter iter;
            list_store.get_iter (out iter, path);
            Value val;
            list_store.get_value (iter, Columns.RULE, out val);
            UFWHelpers.remove_rule ((UFWHelpers.Rule) val.get_object ());
            show_rules ();
        });
        list_toolbar.insert (remove_button, -1);

        view.cursor_changed.connect (() => {
            remove_button.sensitive = true;
        });

        var view_grid = new Gtk.Grid ();

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (view);

        view_grid.attach (scrolled, 0, 0, 1, 1);
        view_grid.attach (list_toolbar, 0, 1, 1, 1);

        var frame = new Gtk.Frame (null);
        frame.margin_top = 12;
        frame.add (view_grid);

        attach (frame, 0, 1, 3, 1);
    }
}
