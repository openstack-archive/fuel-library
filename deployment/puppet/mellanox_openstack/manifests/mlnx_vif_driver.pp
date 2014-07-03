class mellanox_openstack::mlnx_vif_driver {

  package { $::mellanox_openstack::params::mlnxvif_package:
    ensure => installed,
  }

}
