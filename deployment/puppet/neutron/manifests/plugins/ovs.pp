class neutron::plugins::ovs (
  $neutron_config       = {},
) {


  # todo: Remove plugin section, add plugin to server class

  include 'neutron::params'
  include 'l23network::params'

  Anchor<| title=='neutron-server-config-done' |> ->
    Anchor['neutron-plugin-ovs']
  Anchor['neutron-plugin-ovs-done'] ->
    Anchor<| title=='neutron-server-done' |>

  anchor {'neutron-plugin-ovs':}

  Neutron_plugin_ovs<||> ~> Service<| title == 'neutron-server' |>

  case $neutron_config['database']['provider'] {
    /(?i)mysql/: {
      require 'mysql::python'
    }
    /(?i)postgresql/: {
      $backend_package = 'python-psycopg2'
    }
    /(?i)sqlite/: {
      $backend_package = 'python-pysqlite2'
    }
    defeault: {
      fail('Unsupported backend configured')
    }
  }

  if ! defined(File['/etc/neutron']) {
    file {'/etc/neutron':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    }
  }
  package { 'neutron-plugin-ovs':
    name    => $::neutron::params::ovs_server_package,
  } -> Neutron_plugin_ovs <||>

  File<| title == '/etc/neutron' |> ->
  file {'/etc/neutron/plugins':
    ensure  => directory,
    mode    => '0755',
  } ->
  file {'/etc/neutron/plugins/openvswitch':
    ensure  => directory,
    mode    => '0755',
  } ->
  file { '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini':
    ensure  => present,
    mode    => '0640',
    owner   => 'root',
    group   => 'neutron',
  } ->
  file { '/etc/neutron/plugin.ini':
    ensure  => link,
    target  => '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini',
  }
  Package['neutron-plugin-ovs'] -> File['/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini']

  if $::operatingsystem == 'Ubuntu' {
    File['/etc/neutron/plugin.ini'] ->
    file { '/etc/default/neutron-server':
      mode   => '0644',
      owner  => root,
      group  => root,
      source => "puppet:///modules/neutron/default__neutron-server",
    } ->
    Service<| title == 'neutron-server' |>
  }

  neutron_plugin_ovs {
    'DEFAULT/log_dir':             ensure => absent;
    'DEFAULT/log_file':            ensure => absent;
    'DEFAULT/log_config':          ensure => absent;
    'DEFAULT/use_syslog':          ensure => absent;
    'DEFAULT/use_stderr':          ensure => absent;
    'ovs/integration_bridge':       value => $neutron_config['L2']['integration_bridge'];
    'ovs/tenant_network_type':      value => $neutron_config['L2']['segmentation_type'];
    'ovs/enable_tunneling':         value => $neutron_config['L2']['enable_tunneling'];
    'agent/polling_interval':       value => $neutron_config['polling_interval'];
    'agent/root_helper':            value => $neutron_config['root_helper'];
    'securitygroup/firewall_driver': value => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver';
  }

  if $neutron_config['L2']['enable_tunneling'] {
      neutron_plugin_ovs {
        'ovs/tunnel_type':          value => $neutron_config['L2']['segmentation_type'];
        'ovs/tunnel_bridge':        value => $neutron_config['L2']['tunnel_bridge'];
        'ovs/tunnel_id_ranges':     value => $neutron_config['L2']['tunnel_id_ranges'];
        'ovs/l2_population':        value => 'False';  #todo: test 'ml2'
        'ovs/network_vlan_ranges':  value => join(keys($neutron_config['L2']['phys_nets']), ','); # do not belive OS documentation!!!
        'ovs/bridge_mappings':      value => $neutron_config['L2']['bridge_mappings'];
        #todo: remove ext_net from mappings. Affect NEutron
      }
  } else {
      neutron_plugin_ovs {
        'ovs/network_vlan_ranges':  value => $neutron_config['L2']['network_vlan_ranges'];
        'ovs/bridge_mappings':      value => $neutron_config['L2']['bridge_mappings'];
        'ovs/tunnel_bridge':        ensure  => absent;
        'ovs/tunnel_id_ranges':     ensure  => absent;
      }
  }

  File['/etc/neutron/plugin.ini'] ->
    Neutron_plugin_ovs<||> ->
      Anchor<| title=='neutron-server-config-done' |>

  File['/etc/neutron/plugin.ini'] ->
    Anchor['neutron-plugin-ovs-done']
  Anchor['neutron-plugin-ovs'] -> Anchor['neutron-plugin-ovs-done']

  anchor {'neutron-plugin-ovs-done':}
}
# vim: set ts=2 sw=2 et :
