pkgdatadir_declaration = configure_file(
    configuration: configuration_data,
    input: 'config.vala.in',
    output: '@BASENAME@'
)

plug_files = files(
    'BlackList.vala',
    'Plug.vala',
    'UFWHelpers.vala',
    'ZGUtilities.vala',
    'DBus/PermissionStore.vala',
    'Views/FirewallPanel.vala',
    'Views/HouseKeepingPanel.vala',
    'Views/LockPanel.vala',
    'Views/TrackPanel.vala',
    'Views/LocationPanel.vala',
    'Widgets/AppChooser.vala',
    'Widgets/AppRow.vala',
    'Widgets/ClearUsagePopover.vala',
    'Widgets/ExcludeTreeView.vala',
    'Widgets/IncludeTreeView.vala',
    'Widgets/ServiceItem.vala',
    'Widgets/ServiceList.vala'
)

plug_dependencies = [
        dependency('gio-2.0'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite-7'),
        dependency('gtk4'),
        dependency('zeitgeist-2.0'),
        meson.get_compiler('vala').find_library('posix'),
        polkit_dep,
        switchboard_dep
]

shared_module(
    meson.project_name(),
    pkgdatadir_declaration,
    plug_files,
    plug_resources,
    dependencies: plug_dependencies,
    install: true,
    install_dir : pkgdatadir
)
