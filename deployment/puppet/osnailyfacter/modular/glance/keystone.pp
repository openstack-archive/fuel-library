notice('MODULAR: glance/keystone.pp')

$glance_hash      = hiera_hash('glance', {})
$public_address   = hiera('public_vip')
$internal_address = hiera('management_vip', $public_address)
$region           = pick($glance_hash['region'], 'RegionOne')

$password            = $glance_hash['user_password']
$auth_name           = pick($glance_hash['auth_name'], 'glance')
$configure_endpoint  = pick($glance_hash['configure_endpoint'], true)
$configure_user      = pick($glance_hash['configure_user'], true)
$configure_user_role = pick($glance_hash['configure_user_role'], true)
$service_name        = pick($glance_hash['service_name'], $auth_name)
$tenant              = pick($glance_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

class { 'glance::keystone::auth':
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
