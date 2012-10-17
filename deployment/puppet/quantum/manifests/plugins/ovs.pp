class quantum::plugins::ovs (
  $bridge_uplinks      = ['br-virtual:eth1'],
  $bridge_mappings      = ['default:br-virtual'],
  $tenant_network_type  = "vlan",

  $network_vlan_ranges  = "default:1000:2000",
  $integration_bridge   = "br-int",

  $enable_tunneling    = "True",
  $tunnel_bridge        = "br-tun",
  $tunnel_id_ranges     = "1:1000",
  $local_ip             = "10.0.0.1",

  $server               = false,
  $root_helper          = "sudo quantum-rootwrap /etc/quantum/rootwrap.conf",
  $sql_connection       = "mysql://quantum_ovs:quantum_ovs@localhost/quantum_ovs"
) inherits quantum {
  include "quantum::params"

  if !$server {
    $package = $::quantum::params::ovs_agent_package
    $package_require = [Class['quantum']]
  } else {
    $package = $::quantum::params::ovs_server_package
    $package_require = [Class['quantum'], Service[$::quantum::params::server_service]]
  }

  Package["quantum-plugin-ovs"] -> Quantum_plugin_ovs<||>
  Quantum_config<||> ~> Service["quantum-plugin-ovs-service"]
  Quantum_plugin_ovs<||> ~> Service["quantum-plugin-ovs-service"]

  class {
    "vswitch":
      provider => ovs
  }

  vs_bridge {$integration_bridge:
    external_ids => "bridge-id=$ingration_bridge",
    ensure       => present
  }

  quantum::plugins::ovs::bridge{$bridge_mappings:}

  quantum::plugins::ovs::port{$bridge_uplinks:}

  package { "quantum-plugin-ovs":
    name    => $package,
    ensure  => $package_ensure,
    require => $package_require
  }

  $br_map_str = join($bridge_mappings, ",")
  quantum_plugin_ovs {
    "OVS/integration_bridge":   value => $integration_bridge;
    "OVS/network_vlan_ranges":  value => $network_vlan_ranges;
    "OVS/tenant_network_type":  value => $tenant_network_type;
    "OVS/bridge_mappings":      value => $br_map_str;
  }

  if ($tenant_network_type == "gre") and ($enable_tunneling) {
    vs_bridge {$tunnel_bridge:
      ensure => present
    }
    quantum_plugin_ovs {
      "OVS/enable_tunneling":   value => $enable_tunneling;
      "OVS/tunnel_bridge":      value => $tunnel_bridge;
      "OVS/tunnel_id_ranges":   value => $tunnel_id_ranges;
      "OVS/local_ip":           value => $local_ip;
    }
  }

  quantum_plugin_ovs {
    "AGENT/root_helper":  value => $root_helper;
    "DATABASE/sql_connection":  value => $sql_connection;
  }

  if $enabled {
    $service_ensure = "running"
  } else {
    $service_ensure = "stopped"
  }

  service { 'quantum-plugin-ovs-service':
    name    => $::quantum::params::ovs_agent_service,
    enable  => $enable,
    ensure  => $service_ensure,
    require => [Package[$package]]
  }
}
