notice('MODULAR: swift/keystone.pp')

$swift_hash       = hiera_hash('swift', {})
$public_vip       = hiera('public_vip')
# Allow a plugin to override the admin address using swift_hash:
$admin_address    = pick($swift_hash['management_vip'], hiera('management_vip'))
$region           = pick($swift_hash['region'], hiera('region', 'RegionOne'))
$public_ssl_hash  = hiera('public_ssl')
$public_address   = $public_ssl_hash['services'] ? {
  # Allow a plugin to override the public address using swift_hash:
  # TODO(sbog): with this approach you must use IP address in SAN field of
  # certificate on external swift. Change this in next iterations of TLS
  # implementation.
  true    => pick($swift_hash['public_vip'],
                  $public_ssl_hash['hostname']),
  default => $public_vip,
}
$public_protocol  = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}

$password            = $swift_hash['user_password']
$auth_name           = pick($swift_hash['auth_name'], 'swift')
$configure_endpoint  = pick($swift_hash['configure_endpoint'], true)
$service_name        = pick($swift_hash['service_name'], 'swift')
$tenant              = pick($swift_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

$public_url          = "${public_protocol}://${public_address}:8080/v1/AUTH_%(tenant_id)s"
$admin_url           = "http://${admin_address}:8080/v1/AUTH_%(tenant_id)s"

# Amazon S3 endpoints
$public_url_s3       = "${public_protocol}://${public_address}:8080"
$admin_url_s3        = "http://${admin_address}:8080"

class { '::swift::keystone::auth':
  password           => $password,
  auth_name          => $auth_name,
  configure_endpoint => $configure_endpoint,
  service_name       => $service_name,
  public_url         => $public_url,
  internal_url       => $admin_url,
  admin_url          => $admin_url,
  public_url_s3      => $public_url_s3,
  internal_url_s3    => $admin_url_s3,
  admin_url_s3       => $admin_url_s3,
  region             => $region,
}
