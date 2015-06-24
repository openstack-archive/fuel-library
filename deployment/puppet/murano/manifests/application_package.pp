# Import of murano based base application

define murano::application_package (
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
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    environment => [
      "OS_TENANT_NAME=services",
      "OS_USERNAME=${os_username}",
      "OS_PASSWORD=${os_password}",
      "OS_AUTH_URL=${os_auth_url}",
      'OS_ENDPOINT_TYPE=internalURL'
    ],
    command => $murano_cli_cmd,
    user    => $runas_user,
    group   => $runas_user,
    tries   => 3,
    try_sleep => 10,
    unless  => $murano_cli_pkgcheck,
  }
}
