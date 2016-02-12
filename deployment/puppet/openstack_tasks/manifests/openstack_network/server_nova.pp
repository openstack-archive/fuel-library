class openstack_tasks::openstack_network::server_nova {

  notice('MODULAR: openstack_network/server_nova.pp')

  $use_neutron = hiera('use_neutron', false)

  if $use_neutron {
    $neutron_config            = hiera_hash('neutron_config')
    $management_vip            = hiera('management_vip')
    $service_endpoint          = hiera('service_endpoint', $management_vip)
    $neutron_endpoint          = hiera('neutron_endpoint', $management_vip)
    $admin_password            = try_get_value($neutron_config, 'keystone/admin_password')
    $admin_tenant_name         = try_get_value($neutron_config, 'keystone/admin_tenant', 'services')
    $admin_username            = try_get_value($neutron_config, 'keystone/admin_user', 'neutron')
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
      neutron_ovs_bridge   => $neutron_ovs_bridge,
    }

    if $conf_nova {
      include ::nova::params
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
    $num_networks      = hiera('num_networks', undef)
    $network_size      = hiera('network_size', undef)
    $nameservers       = hiera('dns_nameservers', undef)
    $enable_nova_net   = false
    #NOTE(degorenko): lp/1501767
    if $nameservers {
      if count($nameservers) >= 2 {
        $dns_opts = "--dns1 ${nameservers[0]} --dns2 ${nameservers[1]}"
      } else {
        $dns_opts = "--dns1 ${nameservers[0]}"
      }
    } else {
      $dns_opts = ''
    }

    class { '::nova::network' :
      ensure_package    => $ensure_package,
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => false,
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => false, # lp/1501767
      num_networks      => $num_networks,
      network_size      => $network_size,
      dns1              => $nameservers[0],
      dns2              => $nameservers[1],
      enabled           => $enable_nova_net,
      install_service   => false, # because controller
    }

    #NOTE(degorenko): lp/1501767
    $primary_controller = hiera('primary_controller')
    if $primary_controller {
      exec { 'create_private_nova_network':
        path    => '/usr/bin',
        command => "nova-manage network create novanetwork ${fixed_range} ${num_networks} ${network_size} ${dns_opts}",
      }
    }

    # NOTE(aglarendil): lp/1381164
    nova_config { 'DEFAULT/force_snat_range' : value => '0.0.0.0/0' }

    # stub resource for 'nova::network' class
    file { '/etc/nova/nova.conf' : ensure => 'present' }

  }

}
