project(
    'security-privacy',
    'vala', 'c',
    meson_version: '>= 0.46.1',
    version: '2.2.1'
)
i18n = import('i18n')

gettext_name = meson.project_name() + '-plug'

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))

switchboard_dep = dependency('switchboard-2.0')
pkgdatadir = join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'personal')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)

configuration_data = configuration_data()
configuration_data.set('PKGDATADIR', pkgdatadir)
configuration_data.set('GETTEXT_PACKAGE', gettext_name)

subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('meson/post_install.py')
