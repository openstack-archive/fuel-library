class nova::vncproxy(
 $package_name = $::nova::params::vncproxy_package_name
) {

  if($package_name) {
    package { 'nova-vncproxy':
      name   => $package_name,
      ensure => present,
      before => Exec['initial-db-sync'],
    }
  }

}
