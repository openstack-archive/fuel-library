class mellanox_openstack::mlnxvif {
  include mellanox_openstack::params

  $package      = $::mellanox_openstack::params::mlnxvif_package

  package { $package :
      ensure => installed,
  }

  Package[$package] ->
  Service <| title == 'nova-compute' |>

}
