notice('MODULAR: ceilometer/endpoint.pp')

$ceilometer_hash  = hiera_hash('ceilometer', {})
$public_vip       = hiera('public_vip', undef)
$internal_address = hiera('internal_address', undef)
$management_vip   = hiera('management_vip', undef)
$region           = hiera('region', 'RegionOne')

$admin_address             = $management_vip
$ceilometer_public_address = $public_vip
$ceilometer_user_password  = $ceilometer_hash['user_password']
$ceilometer_enabled        = $ceilometer_hash['enabled']

if $internal_address {
  $ceilometer_internal_address = $internal_address
} else {
  $ceilometer_internal_address = $ceilometer_public_address
}

if $admin_address {
  $ceilometer_admin_address = $admin_address
} else {
  $ceilometer_admin_address = $ceilometer_internal_address
}

if $ceilometer_enabled {
  class { 'ceilometer::keystone::auth':
    password         => $ceilometer_user_password,
    public_address   => $ceilometer_public_address,
    admin_address    => $ceilometer_admin_address,
    internal_address => $ceilometer_internal_address,
    region           => $region,
  }
}
