class mellanox_openstack::mlnxvif {
  include mellanox_openstack::params

  $package      = $::mellanox_openstack::params::mlnxvif_package
  $filters_dir  = $::mellanox_openstack::params::filters_dir
  $filters_file = $::mellanox_openstack::params::filters_file

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

      File['/etc/nova/nova.conf'] ->
      File['filters_dir'] ->
      File['network.filters'] ~>
      Service <| title == 'nova-compute' |>
  }

  Package[$package] ->
  Service <| title == 'nova-compute' |>

}
