notice('MODULAR: sahara/keystone.pp')

$sahara_hash         = hiera_hash('sahara_hash', {})
$public_vip          = hiera('public_vip')
$public_ssl_hash     = hiera('public_ssl')
$public_address  = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}
$public_protocol = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}
$admin_address       = hiera('management_vip')
$region              = pick($sahara_hash['region'], hiera('region', 'RegionOne'))
$password            = $sahara_hash['user_password']
$auth_name           = pick($sahara_hash['auth_name'], 'sahara')
$configure_endpoint  = pick($sahara_hash['configure_endpoint'], true)
#FIXME(mattymo): Add configure_user and configure_user_role to
#  sahara::keystone::auth
#$configure_user      = pick($sahara_hash['configure_user'], true)
#$configure_user_role = pick($sahara_hash['configure_user_role'], true)
$service_name        = pick($sahara_hash['service_name'], 'sahara')
$tenant              = pick($sahara_hash['tenant'], 'services')


validate_string($public_address)
validate_string($password)

$api_bind_port  = '8386'
$public_url      = "${public_protocol}://${public_address}:${api_bind_port}/v1.1/%(tenant_id)s"
$admin_url       = "http://${admin_address}:${api_bind_port}/v1.1/%(tenant_id)s"
#################################################################

class { 'sahara::keystone::auth':
  password            => $password,
  auth_name           => $auth_name,
  tenant              => $tenant,
  configure_endpoint  => $configure_endpoint,
#FIXME(mattymo): Add configure_user and configure_user_role to
#  sahara::keystone::auth
#  configure_user      => $configure_user,
#  configure_user_role => $configure_user_role,
  service_name        => $service_name,
  public_url          => $public_url,
  internal_url        => $admin_url,
  admin_url           => $admin_url,
  region              => $region,
}
