$use_neutron     = hiera('quantum')
$network_scheme  = hiera('network_scheme')
$disable_offload = hiera('disable_offload')

prepare_network_config($network_scheme)

if $disable_offload {
  L23network::L3::Ifconfig<||> {
    ethtool => {
      'K' => ['gso off',  'gro off'],
    }
  }
}

class { 'l23network' :
  use_ovs => $use_neutron,
}

class advanced_node_netconfig {
  $sdn = generate_network_config()
  notify {"SDN: ${sdn}": }
}

if $use_neutron {
  class {'advanced_node_netconfig': }
} else {
  class { 'osnailyfacter::network_setup': }
}
