notice('MODULAR: cinder/keystone.pp')

$cinder_hash         = hiera_hash('cinder', {})
$public_ssl_hash     = hiera('public_ssl')
$public_vip          = hiera('public_vip')
$public_address      = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}
$public_protocol     = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}
$admin_protocol      = 'http'
$admin_address       = hiera('management_vip')
$region              = pick($cinder_hash['region'], hiera('region', 'RegionOne'))

$password            = $cinder_hash['user_password']
$auth_name           = pick($cinder_hash['auth_name'], 'cinder')
$configure_endpoint  = pick($cinder_hash['configure_endpoint'], true)
$configure_user      = pick($cinder_hash['configure_user'], true)
$configure_user_role = pick($cinder_hash['configure_user_role'], true)
$service_name        = pick($cinder_hash['service_name'], 'cinder')
$tenant              = pick($cinder_hash['tenant'], 'services')

$port = '8776'

$public_url      = "${public_protocol}://${public_address}:${port}/v1/%(tenant_id)s"
$admin_url       = "${admin_protocol}://${admin_address}:${port}/v1/%(tenant_id)s"

$public_url_v2   = "${public_protocol}://${public_address}:${port}/v2/%(tenant_id)s"
$admin_url_v2    = "${admin_protocol}://${admin_address}:${port}/v2/%(tenant_id)s"

validate_string($public_address)
validate_string($password)

class { '::cinder::keystone::auth':
  password            => $password,
  auth_name           => $auth_name,
  configure_endpoint  => $configure_endpoint,
  configure_user      => $configure_user,
  configure_user_role => $configure_user_role,
  service_name        => $service_name,
  public_url          => $public_url,
  internal_url        => $admin_url,
  admin_url           => $admin_url,
  public_url_v2       => $public_url_v2,
  internal_url_v2     => $admin_url_v2,
  admin_url_v2        => $admin_url_v2,
  region              => $region,
}
