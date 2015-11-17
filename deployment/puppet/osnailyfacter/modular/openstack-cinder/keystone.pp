notice('MODULAR: cinder/keystone.pp')

$cinder_hash         = hiera_hash('cinder', {})
$public_ssl_hash     = hiera('public_ssl')
$ssl_hash            = hiera_hash('use_ssl', {})
$public_vip          = hiera('public_vip')
$management_vip      = hiera('management_vip')
if $public_ssl_hash['services'] or try_get_value($ssl_hash, 'cinder_public', {}) {
  $public_protocol   = 'https'
  $public_address    = pick(try_get_value($ssl_hash, 'cinder_public_hostname', {}), $public_ssl_hash['hostname'])
} else {
  $public_protocol   = 'http'
  $public_address    = $public_vip
}
if try_get_value($ssl_hash, 'cinder_internal', {}) {
  $internal_protocol = 'https'
  $internal_address  = try_get_value($ssl_hash, 'cinder_internal_hostname', {})
} else {
  $internal_protocol = 'http'
  $internal_address  = $management_vip
}
if try_get_value($ssl_hash, 'cinder_admin', {}) {
  $admin_protocol = 'https'
  $admin_address  = try_get_value($ssl_hash, 'cinder_admin_hostname', {})
} else {
  $admin_protocol = 'http'
  $admin_address  = $management_vip
}

$port = '8776'

$public_base_url     = "${public_protocol}://${public_address}:${port}"
$internal_base_url   = "${internal_protocol}://${internal_address}:${port}"
$admin_base_url      = "${admin_protocol}://${admin_address}:${port}"

$region              = pick($cinder_hash['region'], hiera('region', 'RegionOne'))
$password            = $cinder_hash['user_password']
$auth_name           = pick($cinder_hash['auth_name'], 'cinder')
$configure_endpoint  = pick($cinder_hash['configure_endpoint'], true)
$configure_user      = pick($cinder_hash['configure_user'], true)
$configure_user_role = pick($cinder_hash['configure_user_role'], true)
$service_name        = pick($cinder_hash['service_name'], 'cinder')
$tenant              = pick($cinder_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

class { '::cinder::keystone::auth':
  password            => $password,
  auth_name           => $auth_name,
  configure_endpoint  => $configure_endpoint,
  configure_user      => $configure_user,
  configure_user_role => $configure_user_role,
  service_name        => $service_name,
  public_url          => "${public_base_url}/v1/%(tenant_id)s",
  internal_url        => "${internal_base_url}/v1/%(tenant_id)s",
  admin_url           => "${admin_base_url}/v1/%(tenant_id)s",
  public_url_v2       => "${public_base_url}/v2/%(tenant_id)s",
  internal_url_v2     => "${internal_base_url}/v2/%(tenant_id)s",
  admin_url_v2        => "${admin_base_url}/v2/%(tenant_id)s",
  region              => $region,
}
