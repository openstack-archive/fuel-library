class mellanox_openstack::compute_install_mlnx_plugin {

  package { $::mellanox_openstack::params::mlnxvif_package:
    ensure => installed,
  }

  package { $::mellanox_openstack::params::eswitchd_package:
    ensure => installed,
  }

  # needs repackage by mirantis since this depends on openstack rpm, not mirantis
  package { $::mellanox_openstack::params::neutron_mlnx_packages:
    ensure => installed,
  }

}
