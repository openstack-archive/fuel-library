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

Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::glance::keystone::auth']

$public_protocol     = get_ssl_property($ssl_hash, $public_ssl_hash, 'glance', 'public', 'protocol', 'http')
$public_address      = get_ssl_property($ssl_hash, $public_ssl_hash, 'glance', 'public', 'hostname', [$public_vip])
$internal_protocol   = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
$internal_address    = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', [$management_vip])
$admin_protocol      = get_ssl_property($ssl_hash, {}, 'glance', 'admin', 'protocol', 'http')
$admin_address       = get_ssl_property($ssl_hash, {}, 'glance', 'admin', 'hostname', [$management_vip])

$public_url = "${public_protocol}://${public_address}:9292"
$internal_url = "${internal_protocol}://${internal_address}:9292"
$admin_url  = "${admin_protocol}://${admin_address}:9292"

validate_string($public_address)
validate_string($password)

class {'::osnailyfacter::wait_for_keystone_backends':}

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
  tenant              => $tenant,
}
