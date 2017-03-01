// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014 elementary LLC. (http://launchpad.net/switchboard-plug-security-privacy)
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

#if TRANSLATION
    _("Authentication is required to run the Firewall Configuration")
#endif

namespace SecurityPrivacy.UFWHelpers {

    private string get_helper_path () {
        return "%s/security-privacy-plug-helper".printf (Build.PKGDATADIR);
    }

    public bool get_status () {
        try {
            string standard_output;
            Process.spawn_command_line_sync ("pkexec %s -4".printf (get_helper_path ()), out standard_output);
            return (standard_output.contains ("inactive") == false);
        } catch (Error e) {
            warning (e.message);
            return false;
        }
    }

    public void set_status (bool status) {
        try {
            if (status == true)
                Process.spawn_command_line_sync ("pkexec %s -2".printf (get_helper_path ()));
            else
                Process.spawn_command_line_sync ("pkexec %s -3".printf (get_helper_path ()));
        } catch (Error e) {
            warning (e.message);
        }
    }

    public Gee.LinkedList<Rule> get_rules () {
        var rules = new Gee.LinkedList<Rule> ();
        try {
            string standard_output;
            Process.spawn_command_line_sync ("pkexec %s -4".printf (get_helper_path ()), out standard_output);
            var lines = standard_output.split("\n");
            foreach (var line in lines) {
                if ("ALLOW" in line || "DENY" in line || "LIMIT" in line || "REJECT" in line) {
                    var rule = new Rule.from_line (line);
                    rules.add (rule);
                }
            }
        } catch (Error e) {
            warning (e.message);
        }
        return rules;
    }

    public void remove_rule (Rule rule) {
        try {
            Process.spawn_command_line_sync ("pkexec %s -6 \"%d\"".printf (get_helper_path (), rule.number));
        } catch (Error e) {
            warning (e.message);
        }
    }

    public void add_rule (Rule rule) {
        string rule_str = "";
        try {
            switch (rule.action) {
                case Rule.Action.DENY:
                    rule_str = "deny";
                    break;
                case Rule.Action.REJECT:
                    rule_str = "reject";
                    break;
                case Rule.Action.LIMIT:
                    rule_str = "limit";
                    break;
                default:
                    rule_str = "allow";
                    break;
            }

            switch (rule.direction) {
                case Rule.Direction.OUT:
                    rule_str = "%s out".printf (rule_str);
                    break;
                default:
                    rule_str = "%s in".printf (rule_str);
                    break;
            }

            switch (rule.protocol) {
                case Rule.Protocol.UDP:
                    rule_str = "%s %s/udp".printf (rule_str, rule.ports);
                    break;
                default:
                    rule_str = "%s %s/tcp".printf (rule_str, rule.ports);
                    break;
            }

            Process.spawn_command_line_sync ("pkexec %s -5 \"%s\"".printf (get_helper_path (), rule_str));
        } catch (Error e) {
            warning (e.message);
        }
    }

    public class Rule : GLib.Object {
        public enum Action {
            ALLOW,
            DENY,
            REJECT,
            LIMIT
        }

        public enum Protocol {
            UDP,
            TCP
        }

        public enum Direction {
            IN,
            OUT
        }

        public Action action;
        public Protocol protocol;
        public Direction direction;
        public string ports;
        public bool is_v6 = false;
        public int number;

        public Rule () {
            
        }

        public Rule.from_line (string line) {
            if (line.contains ("(v6)"))
                is_v6 = true;
            var first = line.replace ("(v6)", "").split ("] ");
            number = int.parse (first[0].replace ("[", ""));
            var second = first[1];
            var third = second.split ("/");
            ports = third[0];
            string current = "";
            int position = 0;
            foreach (var car in third[1].data) {
                if (car == ' ') {
                    if (current == "") {
                        continue;
                    }

                    if (position == 0) {
                        if ("udp" in current)
                            protocol = Protocol.UDP;
                        else if ("tcp" in current)
                            protocol = Protocol.TCP;
                    } else if (position == 1) {
                        if ("ALLOW" in current)
                            action = Action.ALLOW;
                        else if ("DENY" in current)
                            action = Action.DENY;
                        else if ("REJECT" in current)
                            action = Action.REJECT;
                        else if ("LIMIT" in current)
                            action = Action.LIMIT;
                    } else if (position == 2) {
                        if ("IN" in current)
                            direction = Direction.IN;
                        else if ("OUT" in current)
                            direction = Direction.OUT;
                        break;
                    }

                    current = "";
                    position++;
                    continue;
                }
                current = "%s%c".printf (current, car);
            }
        }
    }
}
