class openstack_tasks::openstack_network::keystone {

  notice('MODULAR: openstack_network/keystone.pp')

  $neutron_hash        = hiera_hash('quantum_settings', {})
  $public_vip          = hiera('public_vip')
  $management_vip      = hiera('management_vip')
  $public_ssl_hash     = hiera_hash('public_ssl')
  $ssl_hash            = hiera_hash('use_ssl', {})

  $public_protocol     = get_ssl_property($ssl_hash, $public_ssl_hash, 'neutron', 'public', 'protocol', 'http')
  $public_address      = get_ssl_property($ssl_hash, $public_ssl_hash, 'neutron', 'public', 'hostname', [$public_vip])

  $internal_protocol   = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'protocol', 'http')
  $internal_address    = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'hostname', [$management_vip])

  $admin_protocol      = get_ssl_property($ssl_hash, {}, 'neutron', 'admin', 'protocol', 'http')
  $admin_address       = get_ssl_property($ssl_hash, {}, 'neutron', 'admin', 'hostname', [$management_vip])

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
  validate_string($internal_address)
  validate_string($password)

  Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::neutron::keystone::auth']

  class { '::osnailyfacter::wait_for_keystone_backends':}
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
    tenant              => $tenant,
  }
}
