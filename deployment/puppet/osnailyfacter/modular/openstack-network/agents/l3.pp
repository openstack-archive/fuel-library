notice('MODULAR: openstack-network/agents/l3.pp')

$use_neutron = hiera('use_neutron', false)

class neutron {}
class { 'neutron' :}

if $use_neutron {
  $debug                   = hiera('debug', true)
  $metadata_port           = '8775'
  $agent_mode              = 'legacy'
  $network_scheme          = hiera('network_scheme', {})

  prepare_network_config($network_scheme)

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $ha_agent                = try_get_value($neutron_advanced_config, 'l3_agent_ha', true)
  $external_network_bridge = get_network_role_property('neutron/floating', 'interface')

  class { 'neutron::agents::l3':
    debug                    => $debug,
    metadata_port            => $metadata_port,
    external_network_bridge  => $external_network_bridge,
    manage_service           => true,
    enabled                  => true,
    router_delete_namespaces => true,
    agent_mode               => $agent_mode,
  }

  if $ha_agent {
    $primary_controller = hiera('primary_controller')
    cluster::neutron::l3 { 'default-l3' :
      primary => $primary_controller,
    }
  }

  #========================
  include neutron::params
  package { 'neutron':
    ensure => 'installed',
    name   => $neutron::params::package_name,
    tag    => ['openstack', 'neutron-package'],
  }

}
