class nova::compute::multi_host(
  $enabled = false
) inherits nova::compute {

  Class['nova::compute'] { enabled => $enabled }

  nova_config { 'enabled_apis': value => 'metadata' }

  class { 'nova::api': enabled => $enabled }

  case $nova::network_manager {
    'nova.network.manager.FlatManager': {
      class { 'nova::network::flat':
        enabled                     => $enabled,
        flat_network_bridge         => $nova::flat_network_bridge,
        flat_network_bridge_ip      => $nova::flat_network_bridge_ip,
        flat_network_bridge_netmask => $nova::flat_network_bridge_netmask,
        configure_bridge            => false,
      }
    }
    'nova.network.manager.FlatDHCPManager': {
      class { 'nova::network::flatdhcp':
        enabled                     => $enabled,
        flat_interface              => $nova::flat_interface,
        flat_dhcp_start             => $nova::flat_dhcp_start,
        flat_injected               => $nova::flat_injected,
        flat_network_bridge_netmask => $nova::flat_network_bridge_netmask,
        configure_bridge            => false,
      }
    }
    'nova.network.manager.VlanManager': {
      class { 'nova::network::vlan':
        enabled => $enabled,
      }
    }
    default: {
      fail("Unsupported network manager: ${nova::network_manager} The supported network managers are nova.network.manager.FlatManager, nova.network.FlatDHCPManager and nova.network.manager.VlanManager")
    }
  }
}
