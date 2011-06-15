# flatdhcp.pp
class nova::network::flat ( $flat_network_bridge,
                            $flat_network_bridge_ip,
                            $flat_network_bridge_netmask,
                            $enabled = "true" ) inherits nova::network {

  nova_config {
    'network_manager': value => 'nova.network.manager.FlatManager';
    'flat_network_bridge': value => $flat_network_bridge;
  }

  # flatManager requires a network bridge be manually setup.
  nova::network::bridge { $flat_network_bridge:
    ip      => $flat_network_bridge_ip,
    netmask => $flat_network_bridge_netmask,
  }

}
