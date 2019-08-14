gettext_declaration = configure_file(
    configuration: configuration_data,
    input: 'io.elementary.switchboard.security-privacy.policy.in.in',
    output: '@BASENAME@'
)

i18n.merge_file(
    input: gettext_declaration,
    output: '@BASENAME@',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(datadir, 'polkit-1', 'actions')
)

i18n.merge_file(
    input: 'io.elementary.switchboard.security-privacy.appdata.xml.in',
    output: 'io.elementary.switchboard.security-privacy.appdata.xml',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    install_dir: join_paths(datadir, 'metainfo'),
    install: true
)

install_data(
    'security-privacy-plug-helper',
    install_mode: 'r-xr--r--',
    install_dir: pkgdatadir
)

install_data(
    'io.elementary.switchboard.security-privacy.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas')
)
