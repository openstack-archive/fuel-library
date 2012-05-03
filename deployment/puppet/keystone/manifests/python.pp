class keystone::python (
  $client_package_name = $::keystone::params::client_package_name,
  $ensure = 'present',	
) {

  package { 'python-keystone' :
    name   => $client_package_name,
    ensure => $ensure,
  }

}
