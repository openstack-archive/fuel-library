notice('MODULAR: openstack-controller/openstack-controller-endpoint.pp')

$nova_hash        = hiera('nova', {})
$public_vip       = hiera('public_vip', undef)
$internal_address = hiera('internal_address', undef)
$management_vip   = hiera('management_vip', undef)

$public_address     = $public_vip
$admin_address      = $management_vip
$nova_user_password = $nova_hash['user_password']

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

if $nova_public_address {
  $nova_public_real = $nova_public_address
} else {
  $nova_public_real = $public_address
}

if $nova_internal_address {
  $nova_internal_real = $nova_internal_address
} else {
  $nova_internal_real = $internal_real
}

if $nova_admin_address {
  $nova_admin_real = $nova_admin_address
} else {
  $nova_admin_real = $admin_real
}

class { 'nova::keystone::auth':
  password         => $nova_user_password,
  public_address   => $nova_public_real,
  admin_address    => $nova_admin_real,
  internal_address => $nova_internal_real,
  region           => $region,
}
