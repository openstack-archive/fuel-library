notice('MODULAR: openstack-network/agents/l3.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {
  $debug                   = hiera('debug', true)
  $metadata_port           = '9697'
  $send_arp_for_ha         = '3'
  $external_network_bridge = 'br-ex'
  $agent_mode              = 'legacy'

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $ha_agent = try_get_value($neutron_advanced_config, 'l3_agent_ha', true)

  class { '::neutron::agents::l3':
    debug                    => $debug,
    metadata_port            => $metadata_port,
    send_arp_for_ha          => $send_arp_for_ha,
    external_network_bridge  => $external_network_bridge,
    manage_service           => true,
    enabled                  => true,
    router_delete_namespaces => true,
    agent_mode               => $agent_mode,
  }

# TODO: disabled until new pacemaker merged
# if $ha_agents {
#   cluster::neutron::l3 { 'default-l3' :}
# }
}
