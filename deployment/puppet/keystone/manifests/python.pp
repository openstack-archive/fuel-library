#
# installs client python libraries for keystone
#
#
class keystone::python (
  $client_package_name = $keystone::params::client_package_name,
  $ensure = 'present'
) inherits keystone::params {

  package { 'python-keystone' :
    ensure => $ensure,
    name   => $client_package_name,
  }

}
