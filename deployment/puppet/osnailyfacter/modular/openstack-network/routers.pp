notice('MODULAR: openstack-network/routers.pp')

$access_hash           = hiera('access', {})
$keystone_admin_tenant = $access_hash['tenant']

openstack::network::create_router { 'router04' :
  internal_network => 'net04',
  external_network => 'net04_ext',
  tenant_name      => $keystone_admin_tenant
}
