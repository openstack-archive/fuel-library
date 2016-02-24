notice('MODULAR: openstack-network/agents/dhcp.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {
  # override neutron options
  $override_configuration = hiera_hash('configuration', {})
  override_resources { 'neutron_dhcp_agent_config':
    data => $override_configuration['neutron_dhcp_agent_config']
  } ~> Service['neutron-dhcp-service']
}

class neutron {}
class { 'neutron' :}

if $use_neutron {

  $debug                   = hiera('debug', true)
  $resync_interval         = '30'
  $isolated_metadata       = try_get_value($neutron_config, 'metadata/isolated_metadata', true)

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $ha_agent                = try_get_value($neutron_advanced_config, 'dhcp_agent_ha', true)

  class { 'neutron::agents::dhcp':
    debug                    => $debug,
    resync_interval          => $resync_interval,
    manage_service           => true,
    enable_isolated_metadata => $isolated_metadata,
    dhcp_delete_namespaces   => true,
    enabled                  => true,
  }

  if $ha_agent {
    $primary_controller = hiera('primary_controller')
    class { 'cluster::neutron::dhcp' :
      primary => $primary_controller,
    }
  }

  # stub package for 'neutron::agents::dhcp' class
  package { 'neutron':
    name   => 'binutils',
    ensure => 'installed',
  }

}
