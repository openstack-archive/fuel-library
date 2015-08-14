notice('MODULAR: swift/keystone.pp')

$swift_hash       = hiera_hash('swift', {})
$public_vip       = hiera('public_vip')
$admin_address    = hiera('management_vip')
$region           = pick($swift_hash['region'], 'RegionOne')
$public_ssl_hash  = hiera('public_ssl')
$public_address   = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}
$public_protocol  = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}
$management_protocol = 'http'
$management_address  = hiera('management_vip')
$admin_address       = hiera('admin_vip', $public_address)
$admin_protocol      = hiera('admin_protocol', $public_protocol)
$password            = $swift_hash['user_password']
$auth_name           = pick($swift_hash['auth_name'], 'swift')
$configure_endpoint  = pick($swift_hash['configure_endpoint'], true)
$service_name        = pick($swift_hash['service_name'], 'swift')
$tenant              = pick($swift_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

$public_url     = "${public_protocol}://${public_address}:8080/v1/AUTH_%(tenant_id)s"
$admin_url      = "${admin_protocol}://${admin_address}:8080/v1/AUTH_%(tenant_id)s"
$management_url = "${management_protocol}://${management_address}:8080/v1/AUTH_%(tenant_id)s"

class { '::swift::keystone::auth':
  password           => $password,
  auth_name          => $auth_name,
  configure_endpoint => $configure_endpoint,
  service_name       => $service_name,
  public_url         => $public_url,
  internal_url       => $management_url,
  admin_url          => $admin_url,
  region             => $region,
}
