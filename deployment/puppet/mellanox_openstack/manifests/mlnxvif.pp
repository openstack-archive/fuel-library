class mellanox_openstack::mlnxvif {
  include mellanox_openstack::params

  $package              = $::mellanox_openstack::params::mlnxvif_package
  $compute_service_name = $::mellanox_openstack::params::compute_service_name

  package { $package :
      ensure => installed,
  }

  Package[$package] ->
  Service[$compute_service_name]

}
