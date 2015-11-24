notice('MODULAR: openstack-network/routers.pp')

$use_neutron              = hiera('use_neutron', false)
$neutron_advanced_config  = hiera_hash('neutron_advanced_configuration', { })
# In case of L3 HA enabled this task must be executed on a post-deployment stage.
# as HA routers can't be created when less then 2 L3 agents are available (Neutron limitation)
$l3_ha                    = pick($neutron_advanced_config['neutron_l3_ha'], false)
$neutron_controller_roles = hiera('neutron_controller_roles', ['controller', 'primary-controller'])
$controllers_num          = size(get_nodes_hash_by_roles(hiera('network_metadata'), $neutron_controller_roles))

if $use_neutron {

  $access_hash           = hiera('access', { })
  $keystone_admin_tenant = pick($access_hash['tenant'], 'admin')
  $neutron_config        = hiera_hash('neutron_config')
  $floating_net          = try_get_value($neutron_config, 'default_floating_net', 'net04_ext')
  $private_net           = try_get_value($neutron_config, 'default_private_net', 'net04')
  $default_router        = try_get_value($neutron_config, 'default_router', 'router04')
  $nets                  = $neutron_config['predefined_networks']

  if ($l3_ha) and ($controllers_num < 2) {
    warning ("Not enough controllers to create an HA router")
  } else {
    neutron_router { $default_router:
      ensure               => 'present',
      gateway_network_name => $floating_net,
      name                 => $default_router,
      tenant_name          => $keystone_admin_tenant,
    } ->

    neutron_router_interface { "${default_router}:${private_net}__subnet":
      ensure => 'present',
    }

    if has_key($nets, 'baremetal') {
      neutron_router_interface { "${default_router}:baremetal__subnet":
          ensure  => 'present',
          require => Neutron_router[$default_router]
      }
    }
  }
}
