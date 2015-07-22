# == Resource: murano::application
#
#  murano application importer
#
# === Parameters
#
# [*package_name*]
#  (Optional) Application package name
#  Defaults to $title
#
# [*package_category*]
#  (Optional) Application category
#  Defaults to ''
#
# [*murano_cli*]
#  (Optional) Executable name for murano CLI
#  Defaults to 'murano'
#
# [*runas_user*]
#  (Optional) User to execute murano CLI
#  Defaults to 'root'
#
# [*os_tenant_name*]
#  (Optional) Keystone tenant for murano
#  Defaults to 'admin'
#
# [*os_username*]
#  (Optional) Keystone username for murano
#  Defaults to 'admin'
#
# [*os_password*]
#  (Optional) Keystone password for murano
#  Defaults to 'ChangeMe'
#
# [*os_region*]
#  (Optional) Keystone region for murano
#  Defaults to 'RegionOne'
#
# [*os_auth_url*]
#  (Optional) Keystone public identity URL
#  Defaults to 'http://127.0.0.1:5000/v2.0/'
#
# [*mandatory*]
#  (Optional) Is this package mandatory
#  Defaults to false
#
define murano::application (
  $package_name     = $title,
  $package_category = '',
  $murano_cli       = 'murano',
  $runas_user       = 'root',
  $os_tenant_name   = 'admin',
  $os_username      = 'admin',
  $os_password      = 'ChangeMe',
  $os_region        = 'RegionOne',
  $os_auth_url      = 'http://127.0.0.1:5000/v2.0/',
  $mandatory        = false,
) {

  $package_path="/var/cache/murano/meta/${package_name}.zip"

  if $package_category {
    $murano_cli_cmd = "${murano_cli} package-import '${package_path}' -c '${package_category}' --is-public --exists-action u"
  } else {
    $murano_cli_cmd = "${murano_cli} package-import '${package_path}' --is-public --exists-action u"
  }

  $murano_cli_pkgcheck = "${murano_cli} package-list 2>&1 | grep -q ' ${package_name} '"

  exec { "murano_import_package_${package_name}":
    path        => '/sbin:/usr/sbin:/bin:/usr/bin',
    environment => [
      "OS_TENANT_NAME=${os_tenant_name}",
      "OS_USERNAME=${os_username}",
      "OS_PASSWORD=${os_password}",
      "OS_AUTH_URL=${os_auth_url}",
      'OS_ENDPOINT_TYPE=internalURL',
      "OS_REGION_NAME=${os_region}"
    ],
    command     => $murano_cli_cmd,
    user        => $runas_user,
    group       => $runas_user,
    tries       => 3,
    try_sleep   => 10,
    unless      => $murano_cli_pkgcheck,
  }
}
