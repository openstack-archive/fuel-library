class keystone::python (
  $client_package_name = $keystone::params::client_package_name,
  $ensure = 'present'
) inherits keystone::params {

  package { 'python-keystone' :
    name   => $client_package_name,
    ensure => $ensure,
  }

}
