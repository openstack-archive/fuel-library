notice('MODULAR: swift/keystone.pp')

$swift_hash       = hiera_hash('swift_hash', {})
$public_address   = hiera('public_vip')
$internal_address = pick(hiera('internal_address', undef), $public_address)
$admin_address    = pick(hiera('management_vip', undef), $internal_address)
$region           = pick($swift_hash['region'], 'RegionOne')

$password            = $swift_hash['user_password']
$auth_name           = pick($swift_hash['auth_name'], 'swift')
$configure_endpoint  = pick($swift_hash['configure_endpoint'], true)
$service_name        = pick($swift_hash['service_name'], $auth_name)
$tenant              = pick($swift_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

class { 'swift::keystone::auth':
  password            => $password,
  auth_name           => $auth_name,
  configure_endpoint  => $configure_endpoint,
  service_name        => $service_name,
  public_address      => $public_address,
  admin_address       => $admin_address,
  internal_address    => $internal_address,
  region              => $region,
}
