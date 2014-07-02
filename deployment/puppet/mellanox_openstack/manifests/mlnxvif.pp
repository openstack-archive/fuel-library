class mellanox_openstack::mlnxvif {

  $package = $::mellanox_openstack::params::mlnxvif_package
  $filters = $::mellanox_openstack::params::filters

  nova_config {
      'DEFAULT/compute_driver':  value => 'nova.virt.libvirt.driver.LibvirtDriver';
      'libvirt/vif_driver':      value => 'mlnxvif.vif.MlxEthVIFDriver';
  }

  package { $package :
      ensure => installed,
  }

  file { 'network.filters' :
      ensure => present,
      path   => $filters,
      owner  => 'root',
      group  => 'root',
      mode   => '0655',
      source => 'puppet:///modules/mellanox_openstack/network.filters',
  }

  Package[$package] ->
  Nova_config <||> ->
  File['network.filters'] ->
  Service <| title == 'nova-compute' |>

}