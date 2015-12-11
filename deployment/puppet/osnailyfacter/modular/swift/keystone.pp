notice('MODULAR: swift/keystone.pp')

$swift_hash         = hiera_hash('swift', {})
$public_vip         = hiera('public_vip')
# Allow a plugin to override the admin address using swift_hash:
$management_vip     = pick($swift_hash['management_vip'], hiera('management_vip'))
$region             = pick($swift_hash['region'], hiera('region', 'RegionOne'))
$public_ssl_hash    = hiera('public_ssl')
$ssl_hash           = hiera_hash('use_ssl', {})

$public_protocol    = get_ssl_property($ssl_hash, $public_ssl_hash, 'swift', 'public', 'protocol', 'http')
$public_address     = get_ssl_property($ssl_hash, $public_ssl_hash, 'swift', 'public', 'hostname', [$swift_hash['public_vip'], $public_vip])

$internal_protocol  = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'protocol', 'http')
$internal_address   = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'hostname', [$management_vip])

$password           = $swift_hash['user_password']
$auth_name          = pick($swift_hash['auth_name'], 'swift')
$configure_endpoint = pick($swift_hash['configure_endpoint'], true)
$service_name       = pick($swift_hash['service_name'], 'swift')
$tenant             = pick($swift_hash['tenant'], 'services')

$backends_to_wait    = pick(hiera('backends_to_wait',['keystone-1','keystone-2']))
$service_endpoint    = hiera('service_endpoint')

validate_string($public_address)
validate_string($password)

$public_url          = "${public_protocol}://${public_address}:8080/v1/AUTH_%(tenant_id)s"
$admin_url           = "${internal_protocol}://${internal_address}:8080/v1/AUTH_%(tenant_id)s"

# Amazon S3 endpoints
$public_url_s3       = "${public_protocol}://${public_address}:8080"
$admin_url_s3        = "${internal_protocol}://${internal_address}:8080"

$haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

class {'::osnailyfacter::wait_for_backend':
  backends_list => $backends_to_wait,
  url           => $haproxy_stats_url
}->
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
