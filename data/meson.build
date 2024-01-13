i18n.merge_file(
    input: 'security-privacy.policy.in',
    output: gettext_name + '.policy',
    po_dir: meson.project_source_root() / 'po' / 'extra',
    install: true,
    install_dir: polkit_actiondir
)

i18n.merge_file(
    input: 'security-privacy.metainfo.xml.in',
    output: gettext_name + '.metainfo.xml',
    po_dir: meson.project_source_root() / 'po' / 'extra',
    type: 'xml',
    install: true,
    install_dir: datadir / 'metainfo'
)

install_data(
    'security-privacy-plug-helper',
    install_mode: 'r-xr--r--',
    install_dir: pkgdatadir
)

install_data(
    'security-privacy.gschema.xml',
    rename: gettext_name + '.gschema.xml',
    install_dir: datadir / 'glib-2.0' / 'schemas'
)
