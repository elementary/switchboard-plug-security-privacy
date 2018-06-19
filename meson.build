project(
    'security-privacy',
    'vala', 'c',
    meson_version: '>= 0.46.1',
    version: '0.1.3'
)

switchboard_dep = dependency('switchboard-2.0')

gettext_name = meson.project_name() + '-plug'
pkgdatadir = join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'personal')
i18n = import('i18n')

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
