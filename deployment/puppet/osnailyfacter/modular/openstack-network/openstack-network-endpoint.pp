notice('MODULAR: openstack-network/openstack-network-endpoint.pp')

$neutron_hash     = hiera_hash('quantum_settings', {})
$public_vip       = hiera('public_vip', undef)
$internal_address = hiera('internal_address', undef)
$management_vip   = hiera('management_vip', undef)
$region           = hiera('region', 'RegionOne')

$admin_address          = $management_vip
$neutron_public_address = $public_vip
$neutron_user_password  = $neutron_hash['keystone']['admin_password']

if $internal_address {
  $neutron_internal_address = $internal_address
} else {
  $neutron_internal_address = $neutron_public_address
}

if $admin_address {
  $neutron_admin_address = $admin_address
} else {
  $neutron_admin_address = $neutron_internal_address
}

class { 'neutron::keystone::auth':
  password         => $neutron_user_password,
  public_address   => $neutron_public_address,
  admin_address    => $neutron_admin_address,
  internal_address => $neutron_internal_address,
  region           => $region,
}
