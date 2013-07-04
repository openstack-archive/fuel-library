class quantum::plugins::ovs (
  $package_ensure       = 'present',
  $sql_connection       = 'sqlite:////var/lib/quantum/ovs.sqlite',
  $sql_max_retries      = 10,
  $reconnect_interval   = 2,
  $bridge_mappings      = ['physnet1:br-ex'],
  $tenant_network_type  = 'vlan',
  $network_vlan_ranges  = 'physnet1:1000:2000',
  $integration_bridge   = 'br-int',
  $enable_tunneling     = 'False',
  $tunnel_bridge        = 'br-tun',
  $tunnel_id_ranges     = '1:1000',
  $polling_interval     = 2,
  $root_helper          = 'sudo /usr/bin/quantum-rootwrap /etc/quantum/rootwrap.conf'
) {

  include 'quantum::params'

  Package['quantum'] -> Package['quantum-plugin-ovs']
  Package['quantum-plugin-ovs'] -> Quantum_plugin_ovs<||>

  Quantum_plugin_ovs<||> ~> Service<| title == 'quantum-server' |>
  Quantum_plugin_ovs<||> ~> Service<| title == 'quantum-ovs-agent' |>

  Package['quantum-plugin-ovs'] -> Service<| title == 'quantum-server' |>
  File['/etc/quantum/plugin.ini'] -> Service<| title == 'quantum-server' |>

  validate_re($sql_connection, '(sqlite|mysql|posgres):\/\/(\S+:\S+@\S+\/\S+)?')

  case $sql_connection {
    /mysql:\/\/\S+:\S+@\S+\/\S+/: {
      require 'mysql::python'
    }
    /postgresql:\/\/\S+:\S+@\S+\/\S+/: {
      $backend_package = 'python-psycopg2'
    }
    /sqlite:\/\//: {
      $backend_package = 'python-pysqlite2'
    }
    defeault: {
      fail('Unsupported backend configured')
    }
  }

  file { '/etc/quantum/plugin.ini':
    ensure  => link,
    target  => '/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini',
    require => Package['quantum-plugin-ovs']
  }

  package { 'quantum-plugin-ovs':
    name    => $::quantum::params::ovs_server_package,
    ensure  => $package_ensure,
  }

  $br_map_str = join($bridge_mappings, ',')

  quantum_plugin_ovs {
    'DATABASE/sql_connection':      value => $sql_connection;
    'DATABASE/sql_max_retries':     value => $sql_max_retries;
    'DATABASE/reconnect_interval':  value => $reconnect_interval;
    'OVS/integration_bridge':       value => $integration_bridge;
    'OVS/tenant_network_type':      value => $tenant_network_type;
    'OVS/enable_tunneling':         value => $enable_tunneling;
    'AGENT/polling_interval':       value => $polling_interval;
    'AGENT/root_helper':            value => $root_helper;
  }

  case $tenant_network_type {
    'gre': {
      quantum_plugin_ovs {
        'OVS/tunnel_bridge':     value => $tunnel_bridge;
        'OVS/tunnel_id_ranges':  value => $tunnel_id_ranges;
      }
    }
    'vlan': {
      quantum_plugin_ovs {
        'OVS/network_vlan_ranges':  value => $network_vlan_ranges;
        'OVS/bridge_mappings':      value => $br_map_str;
      }

      if ! (defined(Package["$::quantum::params::vlan_package"]) or defined(Package["$::l23network::params::lnx_vlan_tools"])) {
        package {"$::l23network::params::lnx_vlan_tools":
          name    => "$::l23network::params::lnx_vlan_tools",
          ensure  => latest,
        }
      }
    } 
  }

}
