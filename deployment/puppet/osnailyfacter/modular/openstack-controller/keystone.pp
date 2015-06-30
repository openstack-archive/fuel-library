notice('MODULAR: openstack-controller/keystone.pp')

$nova_hash  =       hiera_hash('nova', {})
$public_address   = hiera('public_vip')
$internal_address = pick(hiera('internal_address', undef), $public_address)
$admin_address    = pick(hiera('management_vip', undef), $internal_address)
$region           = pick($nova_hash['region'], 'RegionOne')

$password            = $nova_hash['user_password']
$auth_name           = pick($nova_hash['auth_name'], 'nova')
$configure_endpoint  = pick($nova_hash['configure_endpoint'], true)
$configure_user      = pick($nova_hash['configure_user'], true)
$configure_user_role = pick($nova_hash['configure_user_role'], true)
$service_name        = pick($nova_hash['service_name'], $auth_name)
$tenant              = pick($nova_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

class { 'nova::keystone::auth':
  password            => $password,
  auth_name           => $auth_name,
  configure_endpoint  => $configure_endpoint,
  configure_user      => $configure_user,
  configure_user_role => $configure_user_role,
  service_name        => $service_name,
  public_address      => $public_address,
  admin_address       => $admin_address,
  internal_address    => $internal_address,
  region              => $region,
}
