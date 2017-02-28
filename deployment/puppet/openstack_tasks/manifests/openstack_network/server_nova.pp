class openstack_tasks::openstack_network::server_nova {

  notice('MODULAR: openstack_network/server_nova.pp')

  $neutron_config            = hiera_hash('neutron_config')
  $management_vip            = hiera('management_vip')
  $service_endpoint          = hiera('service_endpoint', $management_vip)
  $neutron_endpoint          = hiera('neutron_endpoint', $management_vip)
  $admin_password            = dig44($neutron_config, ['keystone', 'admin_password'])
  $admin_tenant_name         = dig44($neutron_config, ['keystone', 'admin_tenant'], 'services')
  $admin_username            = dig44($neutron_config, ['keystone', 'admin_user'], 'neutron')
  $region_name               = hiera('region', 'RegionOne')
  $auth_api_version          = 'v3'
  $ssl_hash                  = hiera_hash('use_ssl', {})

  $admin_auth_protocol       = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_auth_endpoint       = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [hiera('service_endpoint', ''), $management_vip])

  $neutron_internal_protocol = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'protocol', 'http')
  $neutron_internal_endpoint = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'hostname', [$neutron_endpoint])

  $neutron_auth_url          = "${admin_auth_protocol}://${admin_auth_endpoint}:35357/${auth_api_version}"
  $neutron_url               = "${neutron_internal_protocol}://${neutron_internal_endpoint}:9696"
  $neutron_ovs_bridge        = 'br-int'
  $conf_nova                 = pick($neutron_config['conf_nova'], true)
  $floating_net              = pick($neutron_config['default_floating_net'], 'net04_ext')

  class { '::nova::network::neutron' :
    neutron_password     => $admin_password,
    neutron_project_name => $admin_tenant_name,
    neutron_region_name  => $region_name,
    neutron_username     => $admin_username,
    neutron_auth_url     => $neutron_auth_url,
    neutron_url          => $neutron_url,
    neutron_url_timeout  => '60',
    neutron_ovs_bridge   => $neutron_ovs_bridge,
  }

  # Remove this once nova package is updated and contains
  # use_neutron set to true by default LP #1668623
  ensure_resource('nova_config', 'DEFAULT/use_neutron', {'value' => true })

  if $conf_nova {
    include ::nova::params
    service { 'nova-api':
      ensure => 'running',
      name   => $nova::params::api_service_name,
    }

    nova_config { 'DEFAULT/default_floating_pool': value => $floating_net }
    Nova_config<| |> ~> Service['nova-api']
  }
}
