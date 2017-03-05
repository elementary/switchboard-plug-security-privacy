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
                    rule_str = "%s proto udp".printf (rule_str);
                    break;
                case Rule.Protocol.BOTH:
                    break;
                default:
                    rule_str = "%s proto tcp".printf (rule_str);
                    break;
            }

            if (rule.to != "" && !rule.to.contains ("Anywhere")) {
                rule_str = "%s to %s".printf (rule_str, rule.to);
                if (rule.to_ports != "") {
                    rule_str = "%s port %s".printf (rule_str, rule.to_ports);                    
                }            
            } else {
                if (rule.version == Rule.Version.BOTH) {
                    rule_str = "%s to any".printf (rule_str);                
                } else if (rule.version == Rule.Version.IPV6) {
                    rule_str = "%s to ::/0".printf (rule_str);
                } else if (rule.version == Rule.Version.IPV4) {
                    rule_str = "%s to 0.0.0.0/0".printf (rule_str);
                }
                if (rule.to_ports != "") {
                    rule_str = "%s port %s".printf (rule_str, rule.to_ports);
                }
            }

            if (rule.from != "" && !rule.from.contains ("Anywhere")) {
                rule_str = "%s from %s".printf (rule_str, rule.from);
                if (rule.from_ports != "") {
                    rule_str = "%s port %s".printf (rule_str, rule.from_ports);
                }            
            } else {
                if (rule.version == Rule.Version.BOTH) {
                    rule_str = "%s from any".printf (rule_str);                
                } else if (rule.version == Rule.Version.IPV6) {
                    rule_str = "%s from ::/0".printf (rule_str);
                } else if (rule.version == Rule.Version.IPV4) {
                    rule_str = "%s from 0.0.0.0/0".printf (rule_str);
                }
                if (rule.from_ports != "") {
                    rule_str = "%s port %s".printf (rule_str, rule.from_ports);
                }
            }
        
            warning (rule_str);

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
            TCP,
            BOTH
        }

        public enum Direction {
            IN,
            OUT
        }

        public enum Version {
            IPV4,
            IPV6,
            BOTH
        }

        public Action action;
        public Protocol protocol;
        public Direction direction;
        public string to_ports = "";
        public string from_ports = "";
        public string to = "";
        public string from = "";
        public Version version = Version.BOTH;
        public int number;

        public Rule () {
            
        }

        public Rule.from_line (string line) {
            if (line.contains ("(v6)")) {
                version = Version.IPV6;
            } else {
                version = Version.IPV4;
            }

            try {
                var r = new Regex ("""\[\s*(\d+)\]\s{1}([A-Za-z0-9 \(\)/\.:]+?)\s{2,}([A-Z ]+?)\s{2,}([A-Za-z0-9 \(\)/\.:]+?)(?:\s{2,}.*)?$""");
                MatchInfo info;
                r.match (line, 0, out info);
                
                number = int.parse (info.fetch (1));

                MatchInfo port_info;
                string to_match = info.fetch (2);
                var port_regex = new Regex ("""^(?=.)((?:\d+\.\d+\.\d+\.\d+(?:\/\d+)?)?(?:[^\S\n])?(?:[A-Za-z]+)?)([\d,:]+)?(?:.+)?$""");
                port_regex.match (to_match, 0, out port_info);
                if (port_info.fetch (2) != null) {
                    to_ports = port_info.fetch(2);
                }

                if (port_info.fetch (1) != null) {
                    to = port_info.fetch (1);
                }

                string from_match = info.fetch (4);
                port_regex.match (from_match, 0, out port_info);
                if (port_info.fetch (2) != null) {
                    from_ports = port_info.fetch (2);
                }
                if(port_info.fetch (1) != null) {
                    from = port_info.fetch (1);
                }

                if (from.contains ("tcp")) {
                    protocol = Protocol.TCP;
                } else if (from.contains ("udp")) {
                    protocol = Protocol.UDP;
                } else {
                    protocol = Protocol.BOTH;
                }
                
                string type = info.fetch (3);

                if ("ALLOW" in type) {
                    action = Action.ALLOW;
                } else if ("DENY" in type) {
                    action = Action.DENY;
                } else if ("REJECT" in type) {
                    action = Action.REJECT;
                } else if ("LIMIT" in type) {
                    action = Action.LIMIT;
                }

                if ("IN" in type) {
                    direction = Direction.IN;
                } else if ("OUT" in type) {
                    direction = Direction.OUT;
                }
            } catch (Error e) {
                return;
            }
        }
    }
}
