class heat::client (
  $ensure = 'present'
) {

  include heat::params


  package { 'python-heatclient':
    ensure  => $ensure,
    name    => $::heat::params::client_package_name,
    require => Package['python-routes'],
  }

}
