class openstack_tasks::openstack_network::agents::metadata {

  notice('MODULAR: openstack_network/agents/metadata.pp')

  $use_neutron              = hiera('use_neutron', false)
  $neutron_controller_roles = hiera('neutron_controller_roles', ['controller', 'primary-controller'])
  $neutron_compute_roles    = hiera('neutron_compute_nodes', ['compute'])
  $controller               = roles_include($neutron_controller_roles)
  $compute                  = roles_include($neutron_compute_roles)
  $neutron_advanced_config  = hiera_hash('neutron_advanced_configuration', { })
  $dvr                      = pick($neutron_advanced_config['neutron_dvr'], false)

  if $use_neutron and ($controller or ($dvr and $compute)) {
    # override neutron options
    $override_configuration = hiera_hash('configuration', {})
    override_resources { 'neutron_metadata_agent_config':
      data => $override_configuration['neutron_metadata_agent_config']
    } ~> Service['neutron-metadata']
  }

  if $use_neutron and ($controller or ($dvr and $compute)) {
    $debug                  = hiera('debug', true)
    $ha_agent               = try_get_value($neutron_advanced_config, 'metadata_agent_ha', true)
    $service_endpoint       = hiera('service_endpoint')
    $management_vip         = hiera('management_vip')
    $neutron_config         = hiera_hash('neutron_config')
    $shared_secret          = try_get_value($neutron_config, 'metadata/metadata_proxy_shared_secret')
    $nova_endpoint          = hiera('nova_endpoint', $management_vip)
    $nova_metadata_protocol = hiera('nova_metadata_protocol', 'http')

    $nova_internal_protocol = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'protocol', [$nova_metadata_protocol])
    $nova_internal_endpoint = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'hostname', [$nova_endpoint])

    class { '::neutron::agents::metadata':
      debug             => $debug,
      shared_secret     => $shared_secret,
      metadata_ip       => $nova_internal_endpoint,
      metadata_protocol => $nova_internal_protocol,
      manage_service    => true,
      enabled           => true,
    }

    if ($ha_agent) and !($compute) {
      $primary_controller = hiera('primary_controller')
      class { '::cluster::neutron::metadata' :
        primary => $primary_controller,
      }
    }

    # stub package for 'neutron::agents::metadata' class
    package { 'neutron':
      name   => 'binutils',
      ensure => 'installed',
    }

  }

}
