notice('MODULAR: openstack-network/keystone.pp')

$use_neutron         = hiera('use_neutron', false)
$neutron_hash        = hiera_hash('quantum_settings', {})
$public_vip          = hiera('public_vip')
$management_vip      = hiera('management_vip')
$public_ssl_hash     = hiera('public_ssl')
$ssl_hash            = hiera_hash('use_ssl', {})
if $public_ssl_hash['services'] or try_get_value($ssl_hash, 'neutron_public', false) {
  $public_protocol = 'https'
  $public_address = pick(try_get_value($ssl_hash, 'neutron_public_hostname', {}), $public_ssl_hash['hostname'])
} else {
  $public_protocol = 'http'
  $public_address = $public_vip
}
if try_get_value($ssl_hash, 'neutron_internal', false) {
  $internal_protocol = 'https'
  $internal_address  = pick($ssl_hash['neutron_internal_hostname'], $management_vip)
} else {
  $internal_protocol = 'http'
  $internal_address  = $management_vip
}
$admin_protocol      = $internal_protocol
$admin_address       = $internal_address

$region              = pick($neutron_hash['region'], hiera('region', 'RegionOne'))

$password            = $neutron_hash['keystone']['admin_password']
$auth_name           = pick($neutron_hash['auth_name'], 'neutron')
$configure_endpoint  = pick($neutron_hash['configure_endpoint'], true)
$configure_user      = pick($neutron_hash['configure_user'], true)
$configure_user_role = pick($neutron_hash['configure_user_role'], true)
$service_name        = pick($neutron_hash['service_name'], 'neutron')
$tenant              = pick($neutron_hash['tenant'], 'services')

$port                = '9696'

$public_url          = "${public_protocol}://${public_address}:${port}"
$internal_url        = "${internal_protocol}://${internal_address}:${port}"
$admin_url           = "${admin_protocol}://${admin_address}:${port}"


validate_string($public_address)
validate_string($password)

if $use_neutron {
  class { '::neutron::keystone::auth':
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
}
