# VMWare network class for nova-network

class vmware::network::nova (

  $ensure_package = 'present',

)

{

  nova::generic_service { 'network':
    enabled        => true,
    package_name   => $::nova::params::network_package_name,
    service_name   => $::nova::params::network_service_name,
    ensure_package => $ensure_package,
    before         => Exec['networking-refresh']
  }

# $flat_network_bridge = 'br100'
#  nova_config {
#  'DEFAULT/flat_network_bridge':      value => $flat_network_bridge;
#  }

}
