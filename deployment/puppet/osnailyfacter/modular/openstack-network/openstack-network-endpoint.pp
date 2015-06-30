notice('MODULAR: openstack-network/openstack-network-endpoint.pp')

$neutron_config   = hiera_hash('quantum_settings', {})
$public_vip       = hiera('public_vip', undef)
$internal_address = hiera('internal_address', undef)
$management_vip   = hiera('management_vip', undef)

$public_address        = $public_vip
$admin_address         = $management_vip
$neutron_user_password = $neutron_config['keystone']['admin_password']

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

if $neutron_public_address {
  $neutron_public_real = $neutron_public_address
} else {
  $neutron_public_real = $public_address
}

if $neutron_internal_address {
  $neutron_internal_real = $neutron_internal_address
} else {
  $neutron_internal_real = $internal_real
}

if $neutron_admin_address {
  $neutron_admin_real = $neutron_admin_address
} else {
  $neutron_admin_real = $admin_real
}

class { 'neutron::keystone::auth':
  password         => $neutron_user_password,
  public_address   => $neutron_public_real,
  admin_address    => $neutron_admin_real,
  internal_address => $neutron_internal_real,
  region           => $region,
}
