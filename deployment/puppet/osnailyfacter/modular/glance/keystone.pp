notice('MODULAR: glance/keystone.pp')

$glance_hash         = hiera_hash('glance', {})
$public_vip          = hiera('public_vip')
$public_ssl_hash     = hiera('public_ssl')
$management_vip      = hiera('management_vip')
$region              = pick($glance_hash['region'], hiera('region', 'RegionOne'))
$password            = $glance_hash['user_password']
$auth_name           = pick($glance_hash['auth_name'], 'glance')
$configure_endpoint  = pick($glance_hash['configure_endpoint'], true)
$configure_user      = pick($glance_hash['configure_user'], true)
$configure_user_role = pick($glance_hash['configure_user_role'], true)
$service_name        = pick($glance_hash['service_name'], 'glance')
$tenant              = pick($glance_hash['tenant'], 'services')
$ssl_hash            = hiera_hash('use_ssl', {})

if $public_ssl_hash['services'] or try_get_value($ssl_hash, 'glance_public_hostname', false) {
  $public_protocol = 'https'
  $public_address  = pick(try_get_value($ssl_hash, 'glance_public_hostname', ''), $public_ssl_hash['hostname'])
} else {
  $public_protocol = 'http'
  $public_address  = $public_vip
}

if try_get_value($ssl_hash, 'glance_internal_hostname', false) {
  $internal_protocol = 'https'
  $internal_address  = try_get_value($ssl_hash, 'glance_internal_hostname', '')
} else {
  $internal_protocol = 'http'
  $internal_address  = $management_vip
}

if try_get_value($ssl_hash, 'glance_admin_hostname', false) {
  $admin_protocol = 'https'
  $admin_address  = try_get_value($ssl_hash, 'glance_admin_hostname', '')
} else {
  $admin_protocol = 'http'
  $admin_address  = $management_vip
}

$public_url = "${public_protocol}://${public_address}:9292"
$internal_url = "${internal_protocol}://${internal_address}:9292"
$admin_url  = "${admin_protocol}://${admin_address}:9292"

validate_string($public_address)
validate_string($password)

class { '::glance::keystone::auth':
  password            => $password,
  auth_name           => $auth_name,
  configure_endpoint  => $configure_endpoint,
  configure_user      => $configure_user,
  configure_user_role => $configure_user_role,
  service_name        => $service_name,
  public_url          => $public_url,
  internal_url        => $internal_url,
  admin_url           => $admin_url,
  region              => $region,
}
