notice('MODULAR: murano/keystone.pp')

$murano_hash   = hiera_hash('murano_hash', {})
$public_ip     = hiera('public_vip')
$management_ip = hiera('management_vip')
$region        = hiera('region', 'RegionOne')
$public_ssl    = hiera('public_ssl')
$ssl_hash      = hiera_hash('use_ssl', {})

if $public_ssl['services'] or try_get_value($ssl_hash, 'murano_public', false) {
  $public_protocol = 'https'
  $public_address  = pick(try_get_value($ssl_hash, 'murano_public_hostname', false), $public_ssl['hostname'])
} else {
  $public_protocol = 'http'
  $public_address  = $public_ip
}
if try_get_value($ssl_hash, 'murano_internal', false) {
  $internal_protocol = 'https'
  $internal_address  = pick(try_get_value($ssl_hash, 'murano_internal_hostname', false), $management_ip)
} else {
  $internal_protocol = 'http'
  $internal_address  = $management_ip
}
if try_get_value($ssl_hash, 'murano_admin', false) {
  $admin_protocol = 'https'
  $admin_address  = pick(try_get_value($ssl_hash, 'murano_admin_hostname', false), $management_ip)
} else {
  $admin_protocol = 'http'
  $admin_address  = $management_ip
}

$api_bind_port = '8082'
$tenant        = pick($murano_hash['tenant'], 'services')
$public_url    = "${public_protocol}://${public_address}:${api_bind_port}"
$internal_url  = "${internal_protocol}://${internal_address}:${api_bind_port}"
$admin_url     = "${admin_protocol}://${admin_address}:${api_bind_port}"

#################################################################

class { 'murano::keystone::auth':
  password     => $murano_hash['user_password'],
  service_type => 'application_catalog',
  region       => $region,
  tenant       => $tenant,
  public_url   => $public_url,
  internal_url => $internal_url,
  admin_url    => $admin_url,
}
