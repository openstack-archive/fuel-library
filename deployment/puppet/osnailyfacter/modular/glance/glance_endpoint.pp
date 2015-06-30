notice('MODULAR: glance/glance_endpoint.pp')

$glance_hash      = hiera_hash('glance', {})
$public_vip       = hiera('public_vip', undef)
$internal_address = hiera('internal_address', undef)
$management_vip   = hiera('management_vip', undef)
$region           = hiera('region', 'RegionOne')

$admin_address         = $management_vip
$glance_public_address = $public_vip
$glance_user_password  = $glance_hash['user_password']

if $internal_address {
  $glance_internal_address = $internal_address
} else {
  $glance_internal_address = $glance_public_address
}

if $admin_address {
  $glance_admin_address = $admin_address
} else {
  $glance_admin_address = $glance_internal_address
}

class { 'glance::keystone::auth':
  password         => $glance_user_password,
  public_address   => $glance_public_address,
  admin_address    => $glance_admin_address,
  internal_address => $glance_internal_address,
  region           => $region,
}
