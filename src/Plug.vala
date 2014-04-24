// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014 Security & Privacy Plug (http://launchpad.net/your-project)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */
namespace SecurityPrivacy {

    public static Plug plug;
    public static Gtk.LockButton lock_button;
    public static Blacklist blacklist;

    public class Plug : Switchboard.Plug {
        Gtk.Grid main_grid;
        Gtk.Stack stack;

        public Plug () {
            Object (category: Category.PERSONAL,
                    code_name: Build.PLUGCODENAME,
                    display_name: _("Security & Privacy"),
                    description: _("Privacy and Activity Manager"),
                    icon: "activity-log-manager");
            plug = this;
        }

        public override Gtk.Widget get_widget () {
            if (main_grid == null) {
                main_grid = new Gtk.Grid ();
            }

            if (blacklist == null) {
                blacklist = new Blacklist ();
            }

            return main_grid;
        }

        public override void shown () {
            if (main_grid.get_children ().length () > 0)
                return;

            stack = new Gtk.Stack ();
            stack.expand = true;

            try {
                var permission = new Polkit.Permission.sync ("org.pantheon.security-privacy", Polkit.UnixProcess.new (Posix.getpid ()));
                var infobar = new Gtk.InfoBar ();
                infobar.message_type = Gtk.MessageType.INFO;
                lock_button = new Gtk.LockButton (permission);
                var area = infobar.get_action_area () as Gtk.Container;
                var content = infobar.get_content_area () as Gtk.Container;
                var label = new Gtk.Label (_("Some settings require administrator rights to be changed"));
                area.add (lock_button);
                content.add (label);
                main_grid.attach (infobar, 0, 0, 1, 1);
                infobar.no_show_all = true;
                stack.notify["visible-child-name"].connect (() => {
                    if (permission.allowed == false && stack.visible_child_name == "firewall") {
                        infobar.no_show_all = false;
                        infobar.show_all ();
                    } else {
                        infobar.no_show_all = true;
                        infobar.hide ();
                    }
                });
                permission.notify["allowed"].connect (() => {
                    if (permission.allowed == false && stack.visible_child_name == "firewall") {
                        infobar.no_show_all = false;
                        infobar.show_all ();
                    } else {
                        infobar.no_show_all = true;
                        infobar.hide ();
                    }
                });
            } catch (Error e) {
                critical (e.message);
            }

            var stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.set_stack (stack);
            stack_switcher.halign = Gtk.Align.CENTER;
            stack_switcher.margin = 12;

            var locking = new LockPanel ();
            stack.add_titled (locking, "locking", _("Locking"));
            var tracking = new TrackPanel ();
            stack.add_titled (tracking, "tracking", _("Privacy"));
            var firewall = new FirewallPanel ();
            stack.add_titled (firewall, "firewall", _("Firewall"));

            main_grid.attach (stack_switcher, 0, 1, 1, 1);
            main_grid.attach (stack, 0, 2, 1, 1);
            main_grid.show_all ();
        }

        public override void hidden () {
            
        }

        public override void search_callback (string location) {
            
        }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            return new Gee.TreeMap<string, string> (null, null);
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Security & Privacy plug");
    var plug = new SecurityPrivacy.Plug ();
    return plug;
}
