# Import of murano based base application

define murano::application_package (
  $package_name     = $title,
  $package_category = '',
  $murano_cli       = 'murano',
  $runas_user       = 'root',
  $os_tenant_name   = 'admin',
  $os_username      = 'admin',
  $os_password      = 'ChangeMe',
  $os_auth_url      = 'http://127.0.0.1:5000/v2.0/',
  $mandatory        = false,
) {
  $package_path="/var/cache/murano/meta/${package_name}"

  $murano_cli_cmd = $package_category ? {
    ''       => "${murano_cli} package-import '${package_path}' --is-public --exists-action u",
    default  => "${murano_cli} package-import '${package_path}' -c '${package_category}' --is-public --exists-action u"
  }

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
    onlyif  => [
                 "test -e '${package_path}'"
    ]
  }
}
