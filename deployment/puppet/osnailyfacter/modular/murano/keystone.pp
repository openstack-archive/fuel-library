notice('MODULAR: murano/keystone.pp')

$murano_hash                = hiera_hash('murano_hash', {})
$public_ip                  = hiera('public_vip')
$management_ip              = hiera('management_vip')
$service_endpoint           = hiera('service_endpoint')
$public_ssl_hash            = hiera('public_ssl')
$region                     = hiera('region', 'RegionOne')


if $public_ssl_hash['services'] {
  $public_protocol = 'https'
} else {
  $public_protocol = 'http'
}

$api_bind_port  = '8082'

$tenant         = pick($murano_hash['tenant'], 'services')
$public_url     = "${public_protocol}://${public_ip}:${api_bind_port}"
$admin_url      = "http://${service_endpoint}:${api_bind_port}"
$internal_url   = "http://${service_endpoint}:${api_bind_port}"

#################################################################

class { 'murano::keystone::auth':
  password     => $murano_hash['user_password'],
  service_type => 'application_catalog',
  region       => $region,
  tenant       => $tenant,
  public_url   => $public_url,
  admin_url    => $admin_url,
  internal_url => $internal_url,
}
