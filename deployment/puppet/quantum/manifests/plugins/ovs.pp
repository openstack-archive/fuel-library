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


  # todo: Remove plugin section, add plugin to server class

  include 'quantum::params'
  validate_re($sql_connection, '(sqlite|mysql|posgres):\/\/(\S+:\S+@\S+\/\S+)?')
  $br_map_str = join($bridge_mappings, ',')
  

  Anchor<| title=='quantum-server-config-done' |> -> 
    Anchor['quantum-plugin-ovs']
  Anchor['quantum-plugin-ovs-done'] -> 
    Anchor<| title=='quantum-server-done' |>
  
  anchor {'quantum-plugin-ovs':}

  Quantum_plugin_ovs<||> ~> Service<| title == 'quantum-server' |>
  # not need!!!
  # agent starts after server
  # Quantum_plugin_ovs<||> ~> Service<| title == 'quantum-ovs-agent' |>
  
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

  if ! defined(File['/etc/quantum']) {
    file {'/etc/quantum':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    } 
  }
  package { 'quantum-plugin-ovs':
    name    => $::quantum::params::ovs_server_package,
    ensure  => $package_ensure,
  } ->
  File['/etc/quantum'] ->
  file {'/etc/quantum/plugins':
    ensure  => directory,
    mode    => '0755',
  } ->
  file {'/etc/quantum/plugins/openvswitch':
    ensure  => directory,
    mode    => '0755',
  } ->
  file { '/etc/quantum/plugin.ini':
    ensure  => link,
    target  => '/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini',
  }
  quantum_plugin_ovs {
    'DATABASE/sql_connection':      value => $sql_connection;
    'DATABASE/sql_max_retries':     value => $sql_max_retries;
    'DATABASE/reconnect_interval':  value => $reconnect_interval;
  } ->
  quantum_plugin_ovs {
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
        } -> Package['quantum-plugin-ovs']
      }
    } 
  }

  File['/etc/quantum/plugin.ini'] -> 
    Quantum_plugin_ovs<||> -> 
      Anchor<| title=='quantum-server-config-done' |>

  File['/etc/quantum/plugin.ini'] -> 
    Anchor['quantum-plugin-ovs-done']
  Anchor['quantum-plugin-ovs'] -> Anchor['quantum-plugin-ovs-done']

  anchor {'quantum-plugin-ovs-done':}
}
#
###