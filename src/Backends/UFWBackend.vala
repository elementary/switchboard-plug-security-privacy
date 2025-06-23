public class SecurityPrivacy.UFWBackend : AbstractFirewallBackend {

    public UFWBackend () {
        Object ();
    }

    public override void add_rule (Rule rule) {
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

            if (rule.to != null && rule.to != "" && !rule.to.contains ("Anywhere")) {
                rule_str = "%s to %s".printf (rule_str, rule.to);
                if (rule.to_ports != null && rule.to_ports != "") {
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
                if (rule.to_ports != null && rule.to_ports != "") {
                    rule_str = "%s port %s".printf (rule_str, rule.to_ports);
                }
            }

            if (rule.from != null && rule.from != "" && !rule.from.contains ("Anywhere")) {
                rule_str = "%s from %s".printf (rule_str, rule.from);
                if (rule.from_ports != null && rule.from_ports != "") {
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
                if (rule.from_ports != null && rule.from_ports != "") {
                    rule_str = "%s port %s".printf (rule_str, rule.from_ports);
                }
            }

            warning ("rule string: %s", rule_str);

            warning ("Rule fields: action=%s, direction=%s, protocol=%s, version=%s, to=%s, to_ports=%s, from=%s, from_ports=%s, id=%s",
                rule.action.to_string (),
                rule.direction.to_string (),
                rule.protocol.to_string (),
                rule.version.to_string (),
                rule.to,
                rule.to_ports,
                rule.from,
                rule.from_ports,
                rule.id
            );
            Process.spawn_command_line_sync ("pkexec %s -5 \"%s\"".printf (get_helper_path (), rule_str));
        } catch (Error e) {
            warning (e.message);
        }
    }

    public override void delete_active_rule (Rule rule) {
        try {
            Process.spawn_command_line_sync ("pkexec %s -6 \"%s\"".printf (get_helper_path (), rule.id));
        } catch (Error e) {
            warning (e.message);
        }
    }

    protected override List<Rule> list_active_rules () {
        var rules = new List<Rule> ();
        try {
            string standard_output;
            Process.spawn_command_line_sync ("pkexec %s -4".printf (get_helper_path ()), out standard_output);
            var lines = standard_output.split ("\n");
            foreach (unowned var line in lines) {
                if ("ALLOW" in line || "DENY" in line || "LIMIT" in line || "REJECT" in line) {
                    var rule = create_rule_from_line (line);
                    rules.append (rule);
                }
            }
        } catch (Error e) {
            warning (e.message);
        }

        return rules;
    }

    public override void enable_firewall () {
        try {
            Process.spawn_command_line_sync ("pkexec %s -2".printf (get_helper_path ()));
        } catch (Error e) {
            warning (e.message);
        }
    }

    public override void disable_firewall () {
        try {
            Process.spawn_command_line_sync ("pkexec %s -3".printf (get_helper_path ()));
        } catch (Error e) {
            warning (e.message);
        }
    }

    public override bool is_firewall_enabled () {
        try {
            string standard_output;
            Process.spawn_command_line_sync ("pkexec %s -4".printf (get_helper_path ()), out standard_output);
            return (standard_output.contains ("inactive") == false);
        } catch (Error e) {
            warning (e.message);
            return false;
        }
    }

    private string get_helper_path () {
        return "%s/security-privacy-plug-helper".printf (Build.PKGDATADIR);
    }

    private Rule? create_rule_from_line (string line) {
        var rule_builder = Rule.builder ();

        if (line.contains ("(v6)")) {
                rule_builder.version (Rule.Version.IPV6);
            } else {
                rule_builder.version (Rule.Version.IPV4);
            }

            if (line.contains ("tcp")) {
                rule_builder.protocol (Rule.Protocol.TCP);
            } else if (line.contains ("udp")) {
                rule_builder.protocol (Rule.Protocol.UDP);
            } else {
                rule_builder.protocol (Rule.Protocol.BOTH);
            }

            try {
                var r = new Regex ("""\[\s*(\d+)\]\s{1}([A-Za-z0-9 \(\)/\.:,]+?)\s{2,}([A-Z ]+?)\s{2,}([A-Za-z0-9 \(\)/\.:,]+?)(?:\s{2,}.*)?$""");
                MatchInfo info;
                r.match (line, 0, out info);
                var number = info.fetch (1);

                rule_builder.id (number);

                string to_match = info.fetch (2).replace (" (v6)", "");
                string from_match = info.fetch (4).replace (" (v6)", "");

                string to_ports = "", from_ports = "", to = "", from = "";

                get_address_and_port (to_match, ref to_ports, ref to);
                get_address_and_port (from_match, ref from_ports, ref from);

                rule_builder.to (to);
                rule_builder.from (from);
                rule_builder.to_ports (to_ports);
                rule_builder.from_ports (from_ports);

                string type = info.fetch (3);

                if ("ALLOW" in type) {
                    rule_builder.action (Rule.Action.ALLOW);
                } else if ("DENY" in type) {
                    rule_builder.action (Rule.Action.DENY);
                } else if ("REJECT" in type) {
                    rule_builder.action (Rule.Action.REJECT);
                } else if ("LIMIT" in type) {
                   rule_builder.action (Rule.Action.LIMIT);
                }

                if ("IN" in type) {
                    rule_builder.direction (Rule.Direction.IN);
                } else if ("OUT" in type) {
                    rule_builder.direction (Rule.Direction.IN);
                }
            } catch (Error e) {
                return null;
            }

            var rule = rule_builder.build ();

             warning ("Rule fields: action=%s, direction=%s, protocol=%s, version=%s, to=%s, to_ports=%s, from=%s, from_ports=%s, id=%s",
                rule.action.to_string (),
                rule.direction.to_string (),
                rule.protocol.to_string (),
                rule.version.to_string (),
                rule.to,
                rule.to_ports,
                rule.from,
                rule.from_ports,
                rule.id
            );

            return rule;
    }

    private void get_address_and_port (string input, ref string ports, ref string address) {
            var parts = input.split (" ");
            if (parts.length > 1) {
                ports = parts[1].split ("/")[0];
                address = parts[0];
            } else {
                var ip_parts = parts[0].split ("/");
                if (ip_parts.length > 1) {
                    if (ip_parts[1] == "tcp" || ip_parts[1] == "udp") {
                        ports = ip_parts[0];
                    } else {
                        address = parts[0];
                    }
                } else {
                    var ip = new InetAddress.from_string (ip_parts[0]);
                    if (ip == null) {
                        if (ip_parts[0].contains ("Anywhere")) {
                            address = "Anywhere";
                        } else {
                            ports = ip_parts[0];
                        }
                    } else if (ip.get_family () == SocketFamily.IPV6) {
                        address = ip_parts[0];
                    } else if (ip.get_family () == SocketFamily.IPV4) {
                        address = ip_parts[0];
                    }
                }
            }
        }
}
