notice('MODULAR: openstack-controller/openstack-controller-endpoint.pp')

$nova_hash        = hiera('nova', {})
$public_vip       = hiera('public_vip', undef)
$internal_address = hiera('internal_address', undef)
$management_vip   = hiera('management_vip', undef)
$region           = hiera('region', 'RegionOne')

$admin_address       = $management_vip
$nova_public_address = $public_vip
$nova_user_password  = $nova_hash['user_password']

if $internal_address {
  $nova_internal_address = $internal_address
} else {
  $nova_internal_address = $nova_public_address
}

if $admin_address {
  $nova_admin_address = $admin_address
} else {
  $nova_admin_address = $nova_internal_address
}

class { 'nova::keystone::auth':
  password         => $nova_user_password,
  public_address   => $nova_public_address,
  admin_address    => $nova_admin_address,
  internal_address => $nova_internal_address,
  region           => $region,
}
