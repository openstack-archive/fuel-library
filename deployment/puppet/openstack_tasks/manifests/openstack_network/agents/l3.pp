class openstack_tasks::openstack_network::agents::l3 {

  notice('MODULAR: openstack_network/agents/l3.pp')

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $dvr = pick($neutron_advanced_config['neutron_dvr'], false)

  $neutron_controller_roles = hiera('neutron_controller_roles', ['controller', 'primary-controller'])
  $neutron_compute_roles    = hiera('neutron_compute_nodes', ['compute'])
  $controller               = roles_include($neutron_controller_roles)
  $compute                  = roles_include($neutron_compute_roles)

  if $controller or ($dvr and $compute) {
    # override neutron options
    $override_configuration = hiera_hash('configuration', {})
    override_resources { 'neutron_l3_agent_config':
      data => $override_configuration['neutron_l3_agent_config']
    } ~> Service['neutron-l3']
  }

  if $controller or ($dvr and $compute) {
    $debug                   = hiera('debug', true)
    $metadata_port           = '8775'
    $network_scheme          = hiera_hash('network_scheme', {})

    if $controller {
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

    $ha_agent                = try_get_value($neutron_advanced_config, 'l3_agent_ha', true)

    class { '::neutron::agents::l3':
      debug                    => $debug,
      metadata_port            => $metadata_port,
      external_network_bridge  => ' ',
      manage_service           => true,
      enabled                  => true,
      agent_mode               => $agent_mode,
    }

    if ($ha_agent) and !($compute) {
      $primary_controller = hiera('primary_controller')
      cluster::neutron::l3 { 'default-l3' :
        primary => $primary_controller,
      }
    }

    # stub package for 'neutron::agents::l3' class
    package { 'neutron':
      name   => 'binutils',
      ensure => 'installed',
    }

  }

}
