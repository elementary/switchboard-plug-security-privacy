public class SecurityPrivacy.Rule : Object {
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

        public string id { get; set; default = ""; }
        public Action action { get; set; default = Action.ALLOW; }
        public Protocol protocol { get; set; default = Protocol.BOTH; }
        public Direction direction { get; set; default = Direction.IN; }
        public string to { get; set; }
        public string from { get; set; }
        public string to_ports { get; set; default = null; }
        public string from_ports { get; set; default = null; }
        public Version version { get; set; }
        public bool enabled { get; set; default = true; }

        public Rule () {
            Object ();
        }

        public static Builder builder () {
            return new Builder ();
        }

        // Builder class for Rule
        public class Builder : Object {
            private string _id = "";
            private Action _action = Action.ALLOW;
            private Protocol _protocol = Protocol.BOTH;
            private Direction _direction = Direction.IN;
            private string _to = null;
            private string _from = null;
            private string _to_ports = null;
            private string _from_ports = null;
            private Version _version;
            private bool _enabled = true;

            public Builder id (string id) {
                this._id = id;
                return this;
            }

            public Builder action (Action action) {
                this._action = action;
                return this;
            }

            public Builder protocol (Protocol protocol) {
                this._protocol = protocol;
                return this;
            }

            public Builder direction (Direction direction) {
                this._direction = direction;
                return this;
            }

            public Builder to (string to) {
                this._to = to;
                return this;
            }

            public Builder from (string from) {
                this._from = from;
                return this;
            }

            public Builder to_ports (string to_ports) {
                this._to_ports = to_ports;
                return this;
            }

            public Builder from_ports (string from_ports) {
                this._from_ports = from_ports;
                return this;
            }

            public Builder version (Version version) {
                this._version = version;
                return this;
            }

            public Builder enabled (bool enabled) {
                this._enabled = enabled;
                return this;
            }

            public Rule build () {
                var rule = new Rule ();
                rule.action = this._action;
                rule.protocol = this._protocol;
                rule.direction = this._direction;
                rule.to = this._to;
                rule.from = this._from;
                rule.to_ports = this._to_ports;
                rule.from_ports = this._from_ports;
                rule.version = this._version;
                rule.id = this._id;
                rule.enabled = this._enabled;

                return rule;
            }
        }

        public static EqualFunc<Rule> equal_func = (a, b) => {
            if (a == null || b == null) {
                return false;
            }
            return a.action == b.action &&
                   a.protocol == b.protocol &&
                   a.direction == b.direction &&
                   a.to == b.to &&
                   a.from == b.from &&
                   a.to_ports == b.to_ports &&
                   a.from_ports == b.from_ports &&
                   a.version == b.version &&
                   a.id == b.id;
        };

        public string to_hash () {
            return "%s:%s:%s:%s:%d:%d:%d:%d".printf (
                this.to,
                this.to_ports,
                this.from,
                this.from_ports,
                (int)this.action,
                (int)this.protocol,
                (int)this.direction,
                (int)this.version
            )
            .hash ()
            .to_string ();
        }
}
