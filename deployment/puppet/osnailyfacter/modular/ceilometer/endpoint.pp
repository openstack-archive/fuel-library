notice('MODULAR: ceilometer/endpoint.pp')

$ceilometer_hash  = hiera_hash('ceilometer', {})
$public_vip       = hiera('public_vip', undef)
$internal_address = hiera('internal_address', undef)
$management_vip   = hiera('management_vip', undef)

$public_address           = $public_vip
$admin_address            = $management_vip
$ceilometer_user_password = $ceilometer_hash['user_password']
$ceilometer_enabled       = $ceilometer_hash['enabled']

if ($internal_address) {
  $internal_real = $internal_address
} else {
  $internal_real = $public_address
}

if ($admin_address) {
  $admin_real = $admin_address
} else {
  $admin_real = $internal_real
}

if ($ceilometer_public_address) {
  $ceilometer_public_real = $ceilometer_public_address
} else {
  $ceilometer_public_real = $public_address
}

if ($ceilometer_internal_address) {
  $ceilometer_internal_real = $ceilometer_internal_address
} else {
  $ceilometer_internal_real = $internal_real
}

if ($ceilometer_admin_address) {
  $ceilometer_admin_real = $ceilometer_admin_address
} else {
  $ceilometer_admin_real = $admin_real
}

if ($ceilometer_enabled) {
  class { 'ceilometer::keystone::auth':
    password         => $ceilometer_user_password,
    public_address   => $ceilometer_public_real,
    admin_address    => $ceilometer_admin_real,
    internal_address => $ceilometer_internal_real,
    region           => $region,
  }
}
