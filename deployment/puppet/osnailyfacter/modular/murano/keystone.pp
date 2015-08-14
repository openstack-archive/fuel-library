notice('MODULAR: murano/keystone.pp')

$murano_hash                = hiera_hash('murano_hash', {})
$public_ip                  = hiera('public_vip')
$management_ip              = hiera('management_vip')
$service_endpoint           = hiera('service_endpoint', $management_ip)
$public_ssl                 = hiera('public_ssl')
$region                     = hiera('region', 'RegionOne')


$public_protocol = $public_ssl['services'] ? {
  true    => 'https',
  default => 'http',
}

$public_address = $public_ssl['services'] ? {
  true    => $public_ssl['hostname'],
  default => $public_ip,
}
$admin_address       = hiera('admin_vip', $public_ip)
$admin_protocol      = hiera('admin_protocol', $public_protocol)

$api_bind_port  = '8082'

$tenant         = pick($murano_hash['tenant'], 'services')
$public_url     = "${public_protocol}://${public_address}:${api_bind_port}"
$admin_url      = "${admin_protocol}://${admin_address}:${api_bind_port}"
$internal_url   = "http://${service_endpoint}:${api_bind_port}"

#################################################################

class { 'murano::keystone::auth':
  password     => $murano_hash['user_password'],
  service_type => 'application_catalog',
  region       => $region,
  tenant       => $tenant,
  public_url   => $public_url,
  admin_url    => $admin_url,
  internal_url => $admin_url,
}
