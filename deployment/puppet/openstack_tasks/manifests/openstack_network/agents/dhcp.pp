class openstack_tasks::openstack_network::agents::dhcp {

  notice('MODULAR: openstack_network/agents/dhcp.pp')

<<<<<<< HEAD
  $use_neutron = hiera('use_neutron', false)

  if $use_neutron {
    # override neutron options
    $override_configuration = hiera_hash('configuration', {})
    $override_values = values($override_configuration)
    if !empty($override_values) and has_key($override_values[0], 'data') {
      # Create resources of type 'override_resources'. These, in turn,
      # will either update existing resources in the catalog with new data,
      # or create these resources, if they do not actually exist.
      create_resources(override_resources, $override_configuration)
    } else {
      override_resources { 'neutron_dhcp_agent_config':
        data => $override_configuration['neutron_dhcp_agent_config']
      } ~> Service['neutron-dhcp-service']
    }
  }

  if $use_neutron {

    $debug                   = hiera('debug', true)
    $resync_interval         = '30'
    $isolated_metadata       = try_get_value($neutron_config, 'metadata/isolated_metadata', true)

    $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
    $ha_agent                = try_get_value($neutron_advanced_config, 'dhcp_agent_ha', true)

    class { '::neutron::agents::dhcp':
      debug                    => $debug,
      resync_interval          => $resync_interval,
      manage_service           => true,
      enable_isolated_metadata => $isolated_metadata,
      enabled                  => true,
    }

    if $ha_agent {
      $primary_controller = hiera('primary_controller')
      class { '::cluster::neutron::dhcp' :
        primary => $primary_controller,
      }
    }

    # stub package for 'neutron::agents::dhcp' class
    package { 'neutron':
      name   => 'binutils',
      ensure => 'installed',
    }

  }

}
