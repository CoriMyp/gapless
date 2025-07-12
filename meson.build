project(
  'g4music', [ 'vala', 'c' ],
  version: '4.5',
  license: 'GPL3'
)

app_id = 'com.github.neithern.' + meson.project_name()
version = meson.project_version()

gnome = import('gnome')
i18n = import('i18n')

c_compiler = meson.get_compiler('c')
vala_compiler = meson.get_compiler('vala')
assert(vala_compiler.version().version_compare('>=0.56.10'))

add_project_arguments('-DGETTEXT_PACKAGE="' + meson.project_name() + '"', language: 'c')
add_project_arguments('--enable-experimental-non-null', language: 'vala')

gtk_dep = dependency('gtk4', version: '>=4.12')
adw_dep = dependency('libadwaita-1', version: '>=1.6')
libm_dep = c_compiler.find_library('m', required: false)
posix_dep = vala_compiler.find_library('posix', required: false)

dependencies = [
  dependency('gstreamer-1.0'),
  dependency('gstreamer-tag-1.0'),
  adw_dep,
  libm_dep,
  posix_dep,
]

subdir('data')
subdir('po')
subdir('src')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
