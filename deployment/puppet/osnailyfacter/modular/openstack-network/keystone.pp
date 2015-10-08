notice('MODULAR: openstack-network/keystone.pp')

$use_neutron         = hiera('use_neutron', false)
$neutron_hash        = hiera_hash('quantum_settings', {})
$public_vip          = hiera('public_vip')
$public_ssl_hash     = hiera('public_ssl')
$public_address      = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}
$public_protocol     = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}
$admin_address       = hiera('management_vip')
$admin_protocol      = 'http'
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
$internal_url        = "${admin_protocol}://${admin_address}:${port}"
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
