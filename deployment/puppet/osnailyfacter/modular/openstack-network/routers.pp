notice('MODULAR: openstack-network/routers.pp')

$use_neutron    = hiera('use_neutron', false)
$neutron_config = hiera_hash('neutron_config')

if $use_neutron {

  $access_hash           = hiera('access', { })
  $keystone_admin_tenant = pick($access_hash['tenant'], 'admin')

  $neutron_router_name  = pick($neutron_config['default_router'], 'router04')
  $neutron_floating_net = pick($neutron_config['default_floating_net'], 'net04_ext')
  $neutron_private_net  = pick($neutron_config['default_private_net'], 'net04')

  $neutron_router_interface_name = "${neutron_router_name}:${neutron_private_net}__subnet"

  neutron_router { $neutron_router_name :
    ensure               => 'present',
    gateway_network_name => $neutron_floating_net,
    name                 => $neutron_router_name,
    tenant_name          => $keystone_admin_tenant,
  } ->

  neutron_router_interface { $neutron_router_interface_name :
    ensure => 'present',
  }

}
