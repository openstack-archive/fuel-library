# Configure the neutron server to use the OVS plugin.
# This configures the plugin for the API server, but does nothing
# about configuring the agents that must also run and share a config
# file with the OVS plugin if both are on the same machine.
#
# === Parameters
#
class neutron::plugins::ovs (
  $package_ensure       = 'present',
  $sql_connection       = false,
  $sql_max_retries      = false,
  $sql_idle_timeout     = false,
  $reconnect_interval   = false,
  $tenant_network_type  = 'vlan',
  # NB: don't need tunnel ID range when using VLANs,
  # *but* you do need the network vlan range regardless of type,
  # because the list of networks there is still important
  # even if the ranges aren't specified
  # if type is vlan or flat, a default of physnet1:1000:2000 is used
  # otherwise this will not be set by default.
  $network_vlan_ranges  = undef,
  $tunnel_id_ranges     = '1:1000',
  $vxlan_udp_port       = 4789
) {

  include neutron::params

  Package['neutron'] -> Package['neutron-plugin-ovs']
  Package['neutron-plugin-ovs'] -> Neutron_plugin_ovs<||>
  Neutron_plugin_ovs<||> ~> Service<| title == 'neutron-server' |>
  Package['neutron-plugin-ovs'] -> Service<| title == 'neutron-server' |>

  if ! defined(Package['neutron-plugin-ovs']) {
    package { 'neutron-plugin-ovs':
      ensure  => $package_ensure,
      name    => $::neutron::params::ovs_server_package,
    }
  }

  if $sql_connection {
    warning('sql_connection is deprecated for connection in the neutron::server class')
  }

  if $sql_max_retries {
    warning('sql_max_retries is deprecated for max_retries in the neutron::server class')
  }

  if $sql_idle_timeout {
    warning('sql_idle_timeout is deprecated for idle_timeout in the neutron::server class')
  }

  if $reconnect_interval {
    warning('reconnect_interval is deprecated for retry_interval in the neutron::server class')
  }

  neutron_plugin_ovs {
    'OVS/tenant_network_type': value => $tenant_network_type;
  }

  if $tenant_network_type in ['gre', 'vxlan']  {
    validate_tunnel_id_ranges($tunnel_id_ranges)
    neutron_plugin_ovs {
      # this is set by the plugin and the agent - since the plugin node has the agent installed
      # we rely on it setting it.
      # TODO(ijw): do something with a virtualised node
      # 'OVS/enable_tunneling': value => 'True';
      'OVS/tunnel_id_ranges':   value => $tunnel_id_ranges;
      'OVS/tunnel_type':        value => $tenant_network_type;
    }
  }

  validate_vxlan_udp_port($vxlan_udp_port)
  neutron_plugin_ovs { 'OVS/vxlan_udp_port': value => $vxlan_udp_port; }

  if ! $network_vlan_ranges {
    # If the user hasn't specified vlan_ranges, fail for the modes where
    # it is required, otherwise keep it absent
    if $tenant_network_type in ['vlan', 'flat'] {
      fail('When using the vlan network type, network_vlan_ranges is required')
    } else {
      neutron_plugin_ovs { 'OVS/network_vlan_ranges': ensure => absent }
    }
  } else {
    # This might be set by the user for the gre or vxlan case where
    # provider networks are in use
    if !is_array($network_vlan_ranges) {
      $arr_network_vlan_ranges = strip(split($network_vlan_ranges, ','))
    } else {
      $arr_network_vlan_ranges = $network_vlan_ranges
    }

    validate_network_vlan_ranges($arr_network_vlan_ranges)
    neutron_plugin_ovs {
      'OVS/network_vlan_ranges': value => join($arr_network_vlan_ranges, ',');
    }
  }

  # In RH, this link is used to start Neutron process but in Debian, it's used only
  # to manage database synchronization.
  file {'/etc/neutron/plugin.ini':
    ensure  => link,
    target  => '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini',
    require => Package['neutron-plugin-ovs']
  }
}
