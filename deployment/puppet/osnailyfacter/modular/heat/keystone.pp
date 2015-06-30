notice('MODULAR: heat/keystone.pp')

$heat_hash      = hiera_hash('heat_hash', {})
$public_address   = hiera('public_vip')
$internal_address = pick(hiera('internal_address', undef), $public_address)
$admin_address    = pick(hiera('management_vip', undef), $internal_address)
$region           = pick($heat_hash['region'], 'RegionOne')

$password            = $heat_hash['user_password']
$auth_name           = pick($heat_hash['auth_name'], 'heat')
$configure_endpoint  = pick($heat_hash['configure_endpoint'], true)
$configure_user      = pick($heat_hash['configure_user'], true)
$configure_user_role = pick($heat_hash['configure_user_role'], true)
$service_name        = pick($heat_hash['service_name'], $auth_name)
$tenant              = pick($heat_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

class { 'heat::keystone::auth':
  password               => $password,
  auth_name              => $auth_name,
  configure_endpoint     => $configure_endpoint,
  configure_user         => $configure_user,
  configure_user_role    => $configure_user_role,
  service_name           => $service_name,
  public_address         => $public_address,
  admin_address          => $admin_address,
  internal_address       => $internal_address,
  region                 => $region,
}

class { 'heat::keystone::auth_cfn':
  password            => $password,
  auth_name           => "${auth_name}-cfn",
  configure_endpoint  => $configure_endpoint,
  configure_user      => $configure_user,
  configure_user_role => $configure_user_role,
  service_name        => "$service_name-cfn",
  public_address      => $public_address,
  admin_address       => $admin_address,
  internal_address    => $internal_address,
  region              => $region,
}
