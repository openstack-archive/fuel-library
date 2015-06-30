notice('MODULAR: openstack-cinder/openstack-cinder-endpoint.pp')

$cinder_hash      = hiera('cinder', {})
$public_vip       = hiera('public_vip', undef)
$internal_address = hiera('internal_address', undef)
$management_vip   = hiera('management_vip', undef)

$public_address       = $public_vip
$admin_address        = $management_vip
$cinder_user_password = $cinder_hash['user_password']

if $internal_address {
  $internal_real = $internal_address
} else {
  $internal_real = $public_address
}

if $admin_address {
  $admin_real = $admin_address
} else {
  $admin_real = $internal_real
}

if $cinder_public_address {
  $cinder_public_real = $cinder_public_address
} else {
  $cinder_public_real = $public_address
}

if $cinder_internal_address {
  $cinder_internal_real = $cinder_internal_address
} else {
  $cinder_internal_real = $internal_real
}

if $cinder_admin_address {
  $cinder_admin_real = $cinder_admin_address
} else {
  $cinder_admin_real = $admin_real
}

class { 'cinder::keystone::auth':
  password         => $cinder_user_password,
  public_address   => $cinder_public_real,
  admin_address    => $cinder_admin_real,
  internal_address => $cinder_internal_real,
  region           => $region,
}
