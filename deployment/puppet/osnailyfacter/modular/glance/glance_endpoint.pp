notice('MODULAR: glance/glance_endpoint.pp')

$glance_hash      = hiera_hash('glance', {})
$public_vip       = hiera('public_vip', undef)
$internal_address = hiera('internal_address', undef)
$management_vip   = hiera('management_vip', undef)

$public_address       = $public_vip
$admin_address        = $management_vip
$glance_user_password = $glance_hash['user_password']

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

if ($glance_public_address) {
  $glance_public_real = $glance_public_address
} else {
  $glance_public_real = $public_address
}

if ($glance_internal_address) {
  $glance_internal_real = $glance_internal_address
} else {
  $glance_internal_real = $internal_real
}

if ($glance_admin_address) {
  $glance_admin_real = $glance_admin_address
} else {
  $glance_admin_real = $admin_real
}

class { 'glance::keystone::auth':
  password         => $glance_user_password,
  public_address   => $glance_public_real,
  admin_address    => $glance_admin_real,
  internal_address => $glance_internal_real,
  region           => $region,
}
