notice('MODULAR: openstack-cinder/openstack-cinder-endpoint.pp')

$cinder_hash      = hiera_hash('cinder', {})
$public_vip       = hiera('public_vip', undef)
$internal_address = hiera('internal_address', undef)
$management_vip   = hiera('management_vip', undef)
$region           = hiera('region', 'RegionOne')

$admin_address         = $management_vip
$cinder_public_address = $public_vip
$cinder_user_password  = $cinder_hash['user_password']

if $internal_address {
  $cinder_internal_address = $internal_address
} else {
  $cinder_internal_address = $cinder_public_address
}

if $admin_address {
  $cinder_admin_address = $admin_address
} else {
  $cinder_admin_address = $cinder_internal_address
}

class { 'cinder::keystone::auth':
  password         => $cinder_user_password,
  public_address   => $cinder_public_address,
  admin_address    => $cinder_admin_address,
  internal_address => $cinder_internal_address,
  region           => $region,
}
