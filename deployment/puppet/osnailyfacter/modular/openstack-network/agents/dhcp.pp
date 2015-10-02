notice('MODULAR: openstack-network/agents/dhcp.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {

  $debug                   = hiera('debug', true)
  $resync_interval         = '30'
  $isolated_metadata       = try_get_value($neutron_config, 'metadata/isolated_metadata', true)

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $ha_agent                = try_get_value($neutron_advanced_config, 'l2_agent_dhcp', true)

  class { 'neutron::agents::dhcp':
    debug                    => $debug,
    resync_interval          => $resync_interval,
    manage_service           => true,
    enable_isolated_metadata => $isolated_metadata,
    dhcp_delete_namespaces   => true,
    enabled                  => true,
  }

# TODO: disabled until new pacemaker merged
#  if $ha_agents {
#    class { 'cluster::neutron::dhcp' :}
#  }

}
