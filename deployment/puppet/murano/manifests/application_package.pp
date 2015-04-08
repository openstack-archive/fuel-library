define murano::application_package (
  $package_name     = $title,
  $package_category = '',
  $murano_cli       = 'murano',
  $runas_user       = 'root',
  $mandatory        = false,
) {
  $package_path="/var/cache/murano/meta/${package_name}"

  $murano_cli_cmd = $package_category ? {
    ''       => "bash -c \"source /root/openrc; ${murano_cli} package-import '${package_path}' --is-public --exists-action u\"",
    default  => "bash -c \"source /root/openrc; ${murano_cli} package-import '${package_path}' -c '${package_category}' --is-public --exists-action u\""
  }

  exec { "murano_import_package_${package_name}":
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    command => $murano_cli_cmd,
    user    => $runas_user,
    group   => $runas_user,
    onlyif  => [
                 "test -e '${package_path}'",
                 "test -f '/root/openrc'"
               ]
  }
}
