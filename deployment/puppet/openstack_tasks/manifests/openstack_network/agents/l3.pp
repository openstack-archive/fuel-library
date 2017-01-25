class openstack_tasks::openstack_network::agents::l3 {

  notice('MODULAR: openstack_network/agents/l3.pp')

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $dvr = pick($neutron_advanced_config['neutron_dvr'], false)

  $neutron_controller_roles = hiera('neutron_roles')
  $neutron_compute_roles    = hiera('neutron_compute_nodes', ['compute'])
  $neutron_controller       = roles_include($neutron_controller_roles)
  $compute                  = roles_include($neutron_compute_roles)

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

    if is_file_updated('/etc/neutron/neutron.conf', $title) {
      notify{'neutron.conf has been changed, going to restart l3 agent':
      } ~> Service['neutron-l3']
    }
  }
}
