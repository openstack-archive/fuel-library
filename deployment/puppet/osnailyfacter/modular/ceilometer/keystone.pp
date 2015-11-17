notice('MODULAR: ceilometer/keystone.pp')

$ceilometer_hash     = hiera_hash('ceilometer', {})
$public_vip          = hiera('public_vip')
$management_vip      = hiera('management_vip')
$public_ssl_hash     = hiera('public_ssl')
$ssl_hash            = hiera_hash('use_ssl', {})

if $public_ssl_hash['services'] or try_get_value($ssl_hash, 'ceilometer_public', false) {
  $public_protocol = 'https'
  $public_address  = pick(try_get_value($ssl_hash, 'ceilometer_public_hostname', ''), $public_ssl_hash['hostname'])
} else {
  $public_protocol = 'http'
  $public_address  = $public_vip
}

if try_get_value($ssl_hash, 'ceilometer_internal', false) {
  $internal_protocol = 'https'
  $internal_address  = try_get_value($ssl_hash, 'ceilometer_internal_hostname', $management_vip)
} else {
  $internal_protocol = 'http'
  $internal_address  = $management_vip
}

if try_get_value($ssl_hash, 'ceilometer_admin', false) {
  $admin_protocol = 'https'
  $admin_address  = try_get_value($ssl_hash, 'ceilometer_admin_hostname', $management_vip)
} else {
  $admin_protocol = 'http'
  $admin_address  = $management_vip
}

$region              = pick($ceilometer_hash['region'], hiera('region', 'RegionOne'))
$password            = $ceilometer_hash['user_password']
$auth_name           = pick($ceilometer_hash['auth_name'], 'ceilometer')
$configure_endpoint  = pick($ceilometer_hash['configure_endpoint'], true)
$configure_user      = pick($ceilometer_hash['configure_user'], true)
$configure_user_role = pick($ceilometer_hash['configure_user_role'], true)
$service_name        = pick($ceilometer_hash['service_name'], 'ceilometer')
$tenant              = pick($ceilometer_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

$public_url          = "${public_protocol}://${public_address}:8777"
$internal_url        = "${internal_protocol}://${internal_address}:8777"
$admin_url           = "${admin_protocol}://${admin_address}:8777"

class { '::ceilometer::keystone::auth':
  password            => $password,
  auth_name           => $auth_name,
  configure_endpoint  => $configure_endpoint,
  configure_user      => $configure_user,
  configure_user_role => $configure_user_role,
  service_name        => $service_name,
  public_url          => $public_url,
  internal_url        => $internal_url,
  admin_url           => $admin_url,
  region              => $region,
}
