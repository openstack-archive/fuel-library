notice('MODULAR: ceilometer/keystone.pp')

$ceilometer_hash  = hiera_hash('ceilometer_hash', {})
$public_address   = hiera('public_vip')
$internal_address = pick(hiera('internal_address', undef), $public_address)
$admin_address    = pick(hiera('management_vip', undef), $internal_address)
$region           = pick($ceilometer_hash['region'], 'RegionOne')

$password            = $ceilometer_hash['user_password']
$auth_name           = pick($ceilometer_hash['auth_name'], 'glance')
$configure_endpoint  = pick($ceilometer_hash['configure_endpoint'], true)
$configure_user      = pick($ceilometer_hash['configure_user'], true)
$configure_user_role = pick($ceilometer_hash['configure_user_role'], true)
$service_name        = pick($ceilometer_hash['service_name'], $auth_name)
$tenant              = pick($ceilometer_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

class { 'ceilometer::keystone::auth':
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
