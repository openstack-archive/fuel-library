notice('MODULAR: openstack-network/nova.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {
  $neutron_config = hiera_hash('neutron_config')
  $management_vip = hiera('management_vip')
  $service_endpoint = hiera('service_endpoint', $management_vip)
  $neutron_endpoint = hiera('neutron_endpoint', $management_vip)
  $neutron_admin_password = try_get_value($neutron_config, 'keystone/admin_password')
  $neutron_admin_tenant_name = try_get_value($neutron_config, 'keystone/admin_tenant', 'services')
  $neutron_admin_username = try_get_value($neutron_config, 'keystone/admin_user', 'neutron')
  $neutron_region_name = hiera('region', 'RegionOne')
  $neutron_admin_auth_url = "http://${service_endpoint}:35357/v2.0"
  $neutron_url = "http://${neutron_endpoint}:9696"
  $neutron_ovs_bridge = 'br-int'
  $conf_nova = pick($neutron_config['conf_nova'], true)

  class { 'nova::network::neutron' :
    neutron_admin_password    => $neutron_admin_password,
    neutron_admin_tenant_name => $neutron_admin_tenant_name,
    neutron_region_name       => $neutron_region_name,
    neutron_admin_username    => $neutron_admin_username,
    neutron_admin_auth_url    => $neutron_admin_auth_url,
    neutron_url               => $neutron_url,
    neutron_ovs_bridge        => $neutron_ovs_bridge,
  }

  if $conf_nova {
    include nova::params
    service { 'nova-api':
      ensure => 'running',
      name   => $nova::params::api_service_name,
    }

    nova_config { 'DEFAULT/default_floating_pool': value => 'net04_ext' }
    Nova_config<| |> ~> Service['nova-api']
  }

} else {

  $ensure_package = 'installed'
  $private_interface = hiera('private_int', undef)
  $public_interface = hiera('public_int', undef)
  $fixed_range = hiera('fixed_network_range', undef)
  $network_manager = hiera('network_manager', undef)
  $network_config = hiera('network_config', { })
  $create_networks = true
  $num_networks = hiera('num_networks', undef)
  $network_size  = hiera('network_size', undef)
  $nameservers = hiera('dns_nameservers', undef)
  $enable_nova_net = false
  $install_service = true

  class { 'nova::network' :
    ensure_package    => $ensure_package,
    private_interface => $private_interface,
    public_interface  => $public_interface,
    fixed_range       => $fixed_range,
    floating_range    => false,
    network_manager   => $network_manager,
    config_overrides  => $network_config,
    create_networks   => $create_networks,
    num_networks      => $num_networks,
    network_size      => $network_size,
    nameservers       => $nameservers,
    enabled           => $enable_nova_net,
    install_service   => $install_service,
  }
  nova_config { 'DEFAULT/force_snat_range': value => '0.0.0.0/0' } # NOTE(aglarendil): lp/1381164

}
