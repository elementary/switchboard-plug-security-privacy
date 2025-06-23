public abstract class SecurityPrivacy.AbstractFirewallBackend : GLib.Object {
    private Settings settings;
    private Gee.HashMap<string, Rule> disabled_rules;

    public abstract void enable_firewall ();
    public abstract void disable_firewall ();
    public abstract bool is_firewall_enabled ();
    protected abstract List<Rule> list_active_rules ();
    public abstract void add_rule (Rule rule);
    protected abstract void delete_active_rule (Rule rule);

    construct {
        settings = new Settings ("io.elementary.settings.security-privacy");
        disabled_rules = new Gee.HashMap<string, Rule> ();
        load_disabled_rules ();
    }

    public List<Rule> list_rules () {
        List<Rule> rules = list_active_rules ();

        foreach (var entry in disabled_rules) {
            rules.append (entry.value);
        }

        return rules;
    }

    public void disable_rule (Rule rule) {
        var builder = new VariantBuilder (new VariantType ("a(ssssiiii)"));

        foreach (var entry in disabled_rules) {
            unowned var existing_rule = entry.value;
            builder.add ("(ssssiiii)", existing_rule.to,
                                       existing_rule.to_ports,
                                       existing_rule.from,
                                       existing_rule.from_ports,
                                       existing_rule.action,
                                       existing_rule.protocol,
                                       existing_rule.direction,
                                       existing_rule.version);
        }

        builder.add ("(ssssiiii)", rule.to,
                                   rule.to_ports,
                                   rule.from,
                                   rule.from_ports,
                                   rule.action,
                                   rule.protocol,
                                   rule.direction,
                                   rule.version);

        settings.set_value ("disabled-firewall-rules", builder.end ());
        load_disabled_rules ();

        delete_active_rule (rule);
    }

    public void enable_rule (Rule rule) {
        if (disabled_rules.has_key (rule.to_hash ())) {
            delete_disabled_rule (rule);
            add_rule (rule);
        }
    }

    public void remove_rule (Rule rule) {
        if (disabled_rules.has_key (rule.to_hash ())) {
            delete_disabled_rule (rule);
        } else {
            delete_active_rule (rule);
        }
    }

    protected void load_disabled_rules () {
        disabled_rules.clear ();

        string? to = "", to_ports = "", from = "", from_ports = "";
        int action = 0, protocol = 0, direction = 0, version = 0;
        var rules = settings.get_value ("disabled-firewall-rules");
        VariantIter iter = rules.iterator ();
        while (iter.next (
            "(ssssiiii)",
            ref to,
            ref to_ports,
            ref from,
            ref from_ports,
            ref action,
            ref protocol,
            ref direction,
            ref version
        )) {
            var rule = Rule.builder ()
                .to (to)
                .to_ports (to_ports)
                .from (from)
                .from_ports (from_ports)
                .action ((Rule.Action)action)
                .protocol ((Rule.Protocol)protocol)
                .direction ((Rule.Direction)direction)
                .version ((Rule.Version)version)
                .enabled (false)
                .build ();

            disabled_rules.set (rule.to_hash (), rule);
        }
    }

    protected void delete_disabled_rule (Rule rule) {
        if (disabled_rules.has_key (rule.to_hash ())) {
            disabled_rules.unset (rule.to_hash ());
            var builder = new VariantBuilder (new VariantType ("a(ssssiiii)"));

            foreach (var entry in disabled_rules) {
                var existing_rule = entry.value;
                builder.add ("(ssssiiii)", existing_rule.to,
                                               existing_rule.to_ports,
                                               existing_rule.from,
                                               existing_rule.from_ports,
                                               existing_rule.action,
                                               existing_rule.protocol,
                                               existing_rule.direction,
                                               existing_rule.version);
            }

            settings.set_value ("disabled-firewall-rules", builder.end ());
        }
    }
}
