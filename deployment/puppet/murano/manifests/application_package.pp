define murano::application_package (
  $package_name     = $title,
  $package_category = '',
  $murano_manage    = 'murano-manage',
  $murano_user      = 'murano',
) {
  $package_path="/var/cache/murano/meta/${package_name}"

  $murano_manage_cmd = $package_category ? {
    ''       => "${murano_manage} --config-file=/etc/murano/murano.conf import-package '${package_path}'",
    default  => "${murano_manage} --config-file=/etc/murano/murano.conf import-package '${package_path}' -c '${package_category}'",
  }

  exec { "murano_import_package_${package_name}":
    path    => [ '/usr/bin', '/usr/sbin' ],
    command => $murano_manage_cmd,
    user    => $murano_user,
    group   => $murano_user,
    onlyif  => "test -d '${package_path}'",
  }
}
