notice('MODULAR: openstack-network/routers.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {

  $access_hash           = hiera('access', { })
  $keystone_admin_tenant = pick($access_hash['tenant'], 'admin')

  neutron_router { 'router04':
    ensure               => 'present',
    gateway_network_name => 'net04_ext',
    name                 => 'router04',
    tenant_name          => $keystone_admin_tenant,
  } ->

  neutron_router_interface { 'router04:net04__subnet':
    ensure => 'present',
  }

}
