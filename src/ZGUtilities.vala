// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011 Collabora Ltd.
 * Copyright (c) 2012 Manish Sinha <manishsinha@ubuntu.com>
 * Copyright (c) 2014 Security & Privacy Plug (http://launchpad.net/your-project)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 *              Siegfried-Angel Gevatter Pujals <siegfried@gevatter.com> (from Activity-Log-Manager)
 *              Seif Lotfy <seif@lotfy.com> (from Activity-Log-Manager)
 */

namespace SecurityPrivacy.Utilities {
    public static bool matches_event_template (Zeitgeist.Event event, Zeitgeist.Event template_event) {
        if (!check_field_match (event.interpretation, template_event.interpretation, "ev-int"))
            return false;
        //Check if manifestation is child of template_event or same
        if (!check_field_match (event.manifestation, template_event.manifestation, "ev-mani"))
            return false;
        //Check if actor is equal to template_event actor
        if (!check_field_match (event.actor, template_event.actor, "ev-actor"))
            return false;

        if (event.num_subjects () == 0)
            return true;

        for (int i = 0; i < event.num_subjects (); i++) {
            for (int j = 0; j < template_event.num_subjects (); j++) {
                if (matches_subject_template (event.get_subject (i), template_event.get_subject (j)))
                    return true;
            }
        }

        return false;
    }

    public static bool matches_subject_template (Zeitgeist.Subject subject, Zeitgeist.Subject template_subject) {
        if (!check_field_match (subject.uri, template_subject.uri, "sub-uri"))
            return false;
        if (!check_field_match (subject.interpretation, template_subject.interpretation, "sub-int"))
            return false;
        if (!check_field_match (subject.manifestation, template_subject.manifestation, "sub-mani"))
            return false;
        if (!check_field_match (subject.origin, template_subject.origin, "sub-origin"))
            return false;
        if (!check_field_match (subject.mimetype, template_subject.mimetype, "sub-mime"))
            return false;

        return true;
    }

    private static bool check_field_match (string? property, string? template_property, string property_name = "") {
        var matches = false;
        var parsed = template_property;
        var is_negated = template_property != null? parse_negation (ref parsed): false;
        if (parsed == "") {
            return true;
        } else if (parsed == property) {
            matches = true;
        }

        return (is_negated) ? !matches : matches;
    }

    public static bool parse_negation (ref string val) {
        if (!val.has_prefix ("!"))
            return false;
        val = val.substring (1);
        return true;
    }

    public static HashTable<string, Zeitgeist.Event> from_variant (Variant templates_variant) {
        var blacklist = new HashTable<string, Zeitgeist.Event> (str_hash, str_equal);
        foreach (Variant template_variant in templates_variant) {
            VariantIter iter = template_variant.iterator ();
            string template_id = iter.next_value ().get_string ();
            var ev_variant = iter.next_value ();
            if (ev_variant != null) {
                try {
                    Zeitgeist.Event template = new Zeitgeist.Event.from_variant (ev_variant);
                    blacklist.insert (template_id, template);
                } catch (Error e) {
                    warning (e.message);
                }
            }
        }

        return blacklist;
    }

    public static Variant to_variant (HashTable<string, Zeitgeist.Event> blacklist) {
        var vb = new VariantBuilder (new VariantType (SIG_BLACKLIST)); {
            var iter = HashTableIter<string, Zeitgeist.Event> (blacklist);
            string template_id;
            Zeitgeist.Event event_template;
            while (iter.next (out template_id, out event_template)) {
                vb.open (new VariantType ("{s(%s)}".printf (SIG_EVENT)));
                vb.add ("s", template_id);
                vb.add_value (event_template.to_variant ());
                vb.close ();
            }
        }

        return vb.end ();
    }
}