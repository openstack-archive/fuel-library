define murano::application_package (
  $package_name  = $title,
  $murano_manage = 'murano-manage',
  $murano_user   = 'murano',
) {
  if $package_name != '' {
    $package_path="/var/cache/murano/meta/$package_name"
    exec { "murano_import_package_${package_name}":
      path    => [ '/usr/bin', '/usr/sbin' ],
      command => "$murano_manage --config-file=/etc/murano/murano.conf import-package '$package_path'",
      user    => $murano_user,
      group   => $murano_user,
      onlyif  => "test -d '$package_path'",
    }
  }
}
