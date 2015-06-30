notice('MODULAR: openstack-network/keystone.pp')

$neutron_hash     = hiera_hash('quantum_settings', {})
$public_address   = hiera('public_vip')
$internal_address = hiera('managment_vip', $public_address)
$region           = pick(neutron_hash['region'], 'RegionOne')

$password            = $neutron_hash['keystone']['admin_password']
$auth_name           = pick($neutron_hash['auth_name'], 'neutron')
$configure_endpoint  = pick($neutron_hash['configure_endpoint'], true)
$configure_user      = pick($neutron_hash['configure_user'], true)
$configure_user_role = pick($neutron_hash['configure_user_role'], true)
$service_name        = pick($neutron_hash['service_name'], $auth_name)
$tenant              = pick($neutron_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

class { 'neutron::keystone::auth':
  password            => $password,
  auth_name           => $auth_name,
  configure_endpoint  => $configure_endpoint,
  configure_user      => $configure_user,
  configure_user_role => $configure_user_role,
  service_name        => $service_name,
  public_address      => $public_address,
  admin_address       => $internal_address,
  internal_address    => $internal_address,
  region              => $region,
}
