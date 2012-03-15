class nova::compute::libvirt (
  $libvirt_type = 'kvm',
  $flat_network_bridge = 'br100',
  $flat_network_bridge_ip,
  $flat_network_bridge_netmask
) inherits nova::compute{

  include nova::params

  package { 'libvirt':
    name   => $::nova::params::libvirt_package_name,
    ensure => present,
  }

  service {"libvirt" :
    name     => $::nova::params::libvirt_service_name,
    ensure   => running,
    provider => $::nova::params::special_service_provider,
    require  => Package['libvirt'],
  }

  Service['nova-compute'] {
    require +> Service['libvirt'],
  }

  nova_config { 'libvirt_type': value => $libvirt_type }
  nova_config { 'connection_type': value => 'libvirt' }

  nova::network::bridge { $flat_network_bridge:
    ip      => $flat_network_bridge_ip,
    netmask => $flat_network_bridge_netmask,
  }
}
