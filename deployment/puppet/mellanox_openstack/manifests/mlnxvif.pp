class mellanox_openstack::mlnxvif {

  $package      = $::mellanox_openstack::params::mlnxvif_package
  $filters_dir  = $::mellanox_openstack::params::filters_dir
  $filters_file = $::mellanox_openstack::params::filters_file

  nova_config {
      'DEFAULT/compute_driver':  value => 'nova.virt.libvirt.driver.LibvirtDriver';
      'libvirt/vif_driver':      value => 'mlnxvif.vif.MlxEthVIFDriver';
  }

  package { $package :
      ensure => installed,
  }

  if $::osfamily == 'Debian' {
      File {
          owner  => 'root',
          group  => 'root',
      }

      file { 'filters_dir' :
          ensure => directory,
          path   => $filters_dir,
          mode   => '0755',
      }

      file { 'network.filters' :
          ensure => present,
          path   => $filters_file,
          mode   => '0644',
          source => 'puppet:///modules/mellanox_openstack/network.filters',
      }

      Nova_config <||> ->
      File['network.filters'] ->
      Service <| title == 'nova-compute' |>
  }

  Package[$package] ->
  Nova_config <||> ->
  Service <| title == 'nova-compute' |>

}