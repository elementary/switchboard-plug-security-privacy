project(
    'security-privacy',
    'vala', 'c',
    meson_version: '>= 0.58.0',
    version: '7.0.0'
)

gnome = import('gnome')

i18n = import('i18n')

gettext_name = meson.project_name() + '-plug'

prefix = get_option('prefix')
datadir = prefix / get_option('datadir')
libdir = prefix / get_option('libdir')

switchboard_dep = dependency('switchboard-2.0')
switchboard_plugsdir = switchboard_dep.get_variable('plugsdir', pkgconfig_define: ['libdir', libdir])
pkgdatadir = switchboard_plugsdir / 'personal'

polkit_dep = dependency('polkit-gobject-1')
polkit_actiondir = polkit_dep.get_variable('actiondir', pkgconfig_define: ['prefix', prefix])

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)

configuration_data = configuration_data()
configuration_data.set('PKGDATADIR', pkgdatadir)
configuration_data.set('GETTEXT_PACKAGE', gettext_name)
configuration_data.set('LOCALEDIR', prefix / get_option('localedir'))

plug_resources = gnome.compile_resources(
    'plug_resources',
    'data/icons.gresource.xml',
    source_dir: 'data'
)

subdir('data')
subdir('src')
subdir('po')

gnome.post_install(glib_compile_schemas: true)
