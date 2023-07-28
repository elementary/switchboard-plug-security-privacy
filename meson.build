project(
    'security-privacy',
    'vala', 'c',
    meson_version: '>= 0.46.1',
    version: '7.1.0'
)

gnome = import('gnome')

i18n = import('i18n')

gettext_name = meson.project_name() + '-plug'

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))

switchboard_dep = dependency('switchboard-2.0')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])
pkgdatadir = join_paths(switchboard_plugsdir, 'personal')

polkit_dep = dependency('polkit-gobject-1')
polkit_actiondir = polkit_dep.get_pkgconfig_variable('actiondir', define_variable: ['prefix', prefix])

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)

configuration_data = configuration_data()
configuration_data.set('PKGDATADIR', pkgdatadir)
configuration_data.set('GETTEXT_PACKAGE', gettext_name)
configuration_data.set('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))

plug_resources = gnome.compile_resources(
    'plug_resources',
    'data/icons.gresource.xml',
    source_dir: 'data'
)

subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('meson/post_install.py')
