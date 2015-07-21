notice('MODULAR: sahara/keystone.pp')

$sahara_hash      = hiera_hash('sahara', {})
$public_ssl_hash  = hiera('public_ssl')
$public_address   = hiera('public_vip')
$internal_address = hiera('management_vip', $public_address)

$api_bind_port   = '8386'
$sahara_user     = pick($sahara_hash['user'], 'sahara')
$sahara_password = pick($sahara_hash['user_password'])
$tenant          = pick($sahara_hash['tenant'], 'services')
$region          = pick($sahara_hash['region'], 'RegionOne')
$service_name    = pick($sahara_hash['service_name'], 'sahara')
$public_protocol = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}
$public_url      = "${public_protocol}://${public_address}:${api_bind_port}/v1.1/%(tenant_id)s"
$admin_url       = "http://${internal_address}:${api_bind_port}/v1.1/%(tenant_id)s"
$internal_url    = "http://${internal_address}:${api_bind_port}/v1.1/%(tenant_id)s"

class { 'sahara::keystone::auth':
  auth_name    => $sahara_user,
  password     => $sahara_password,
  service_type => 'data_processing',
  service_name => $service_name,
  region       => $region,
  tenant       => $tenant,
  public_url   => $public_url,
  admin_url    => $admin_url,
  internal_url => $internal_url,
}
