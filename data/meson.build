gettext_declaration = configure_file(
    configuration: configuration_data,
    input: 'org.pantheon.security-privacy.policy.in',
    output: '@BASENAME@'
)

install_data(
    gettext_declaration,
    install_dir: join_paths(get_option('datadir'), 'polkit-1', 'actions')
)

install_data(
    'security-privacy-plug-helper',
    install_mode: 'r-xr--r--',
    install_dir: pkgdatadir
)

install_data(
    'org.pantheon.security-privacy.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)
