class openstack_tasks::openstack_network::agents::l3 {

  notice('MODULAR: openstack_network/agents/l3.pp')

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $dvr = pick($neutron_advanced_config['neutron_dvr'], false)

  $neutron_controller_roles = hiera('neutron_roles')
  $neutron_compute_roles    = hiera('neutron_compute_nodes', ['compute'])
  $neutron_controller       = roles_include($neutron_controller_roles)
  $compute                  = roles_include($neutron_compute_roles)

  if $neutron_controller or ($dvr and $compute) {
    # override neutron options
    $override_configuration = hiera_hash('configuration', {})
  $override_values = values($override_configuration)
    if !empty($override_values) and has_key($override_values[0], 'data') {
      # Create resources of type 'override_resources'. These, in turn,
      # will either update existing resources in the catalog with new data,
      # or create these resources, if they do not actually exist.
      create_resources(override_resources, $override_configuration)
    } else {
      override_resources { 'neutron_l3_agent_config':
        data => $override_configuration['neutron_l3_agent_config']
      } ~> Service['neutron-l3']
    }
  }

  if $neutron_controller or ($dvr and $compute) {
    $debug                   = hiera('debug', true)
    $metadata_port           = '8775'
    $network_scheme          = hiera_hash('network_scheme', {})

    if $neutron_controller {
      if $dvr {
        $agent_mode = 'dvr_snat'
      } else {
        $agent_mode = 'legacy'
      }
    } else {
      # works on compute nodes only if dvr is enabled
      $agent_mode = 'dvr'
    }

    prepare_network_config($network_scheme)

    $ha_agent                = dig44($neutron_advanced_config, ['l3_agent_ha'], true)

    class { '::neutron::agents::l3':
      debug                   => $debug,
      metadata_port           => $metadata_port,
      external_network_bridge => ' ',
      manage_service          => true,
      enabled                 => true,
      agent_mode              => $agent_mode,
    }

    if ($ha_agent) and !($compute) {
      $primary_neutron = has_primary_role(intersection(hiera('neutron_roles'), hiera('roles')))
      cluster::neutron::l3 { 'default-l3' :
        primary => $primary_neutron,
      }
    }

    # stub package for 'neutron::agents::l3' class
    package { 'neutron':
      name   => 'binutils',
      ensure => 'installed',
    }

  }

}
