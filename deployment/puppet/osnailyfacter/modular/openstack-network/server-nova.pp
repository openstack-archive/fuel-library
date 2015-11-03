notice('MODULAR: openstack-network/server-nova.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {
  $neutron_config     = hiera_hash('neutron_config')
  $management_vip     = hiera('management_vip')
  $service_endpoint   = hiera('service_endpoint', $management_vip)
  $neutron_endpoint   = hiera('neutron_endpoint', $management_vip)
  $admin_password     = try_get_value($neutron_config, 'keystone/admin_password')
  $admin_tenant_name  = try_get_value($neutron_config, 'keystone/admin_tenant', 'services')
  $admin_username     = try_get_value($neutron_config, 'keystone/admin_user', 'neutron')
  $region_name        = hiera('region', 'RegionOne')
  $auth_api_version   = 'v2.0'
  $admin_identity_uri = "http://${service_endpoint}:35357"
  $admin_auth_url     = "${admin_identity_uri}/${auth_api_version}"
  $neutron_url        = "http://${neutron_endpoint}:9696"
  $neutron_ovs_bridge = 'br-int'
  $conf_nova          = pick($neutron_config['conf_nova'], true)
  $floating_net       = pick($neutron_config['default_floating_net'], 'net04_ext')

  class { 'nova::network::neutron' :
    neutron_admin_password    => $admin_password,
    neutron_admin_tenant_name => $admin_tenant_name,
    neutron_region_name       => $region_name,
    neutron_admin_username    => $admin_username,
    neutron_admin_auth_url    => $admin_auth_url,
    neutron_url               => $neutron_url,
    neutron_ovs_bridge        => $neutron_ovs_bridge,
  }

  if $conf_nova {
    include nova::params
    service { 'nova-api':
      ensure => 'running',
      name   => $nova::params::api_service_name,
    }

    nova_config { 'DEFAULT/default_floating_pool': value => $floating_net }
    Nova_config<| |> ~> Service['nova-api']
  }

} else {

  $ensure_package    = 'installed'
  $private_interface = hiera('private_int', undef)
  $public_interface  = hiera('public_int', undef)
  $fixed_range       = hiera('fixed_network_range', undef)
  $network_manager   = hiera('network_manager', undef)
  $network_config    = hiera('network_config', { })
  $create_networks   = true
  $num_networks      = hiera('num_networks', undef)
  $network_size      = hiera('network_size', undef)
  $nameservers       = hiera('dns_nameservers', undef)
  $enable_nova_net   = false

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
    dns1              => $nameservers[0],
    dns2              => $nameservers[1],
    enabled           => $enable_nova_net,
    install_service   => false, # bacause controller
  }

  # NOTE(aglarendil): lp/1381164
  nova_config { 'DEFAULT/force_snat_range' : value => '0.0.0.0/0' }

# =========================================================================

  file { '/etc/nova/nova.conf' : ensure => 'present' }

}
