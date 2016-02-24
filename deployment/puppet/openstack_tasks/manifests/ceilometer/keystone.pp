class openstack_tasks::ceilometer::keystone {

  notice('MODULAR: ceilometer/keystone.pp')

  $ceilometer_hash     = hiera_hash('ceilometer', {})
  $public_vip          = hiera('public_vip')
  $management_vip      = hiera('management_vip')
  $public_ssl_hash     = hiera_hash('public_ssl')
  $ssl_hash            = hiera_hash('use_ssl', {})

  Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::ceilometer::keystone::auth']

  $public_protocol = get_ssl_property($ssl_hash, $public_ssl_hash, 'ceilometer', 'public', 'protocol', 'http')
  $public_address  = get_ssl_property($ssl_hash, $public_ssl_hash, 'ceilometer', 'public', 'hostname', [$public_vip])

  $internal_protocol = get_ssl_property($ssl_hash, {}, 'ceilometer', 'internal', 'protocol', 'http')
  $internal_address  = get_ssl_property($ssl_hash, {}, 'ceilometer', 'internal', 'hostname', [$management_vip])

  $admin_protocol = get_ssl_property($ssl_hash, {}, 'ceilometer', 'admin', 'protocol', 'http')
  $admin_address  = get_ssl_property($ssl_hash, {}, 'ceilometer', 'admin', 'hostname', [$management_vip])

  $region              = pick($ceilometer_hash['region'], hiera('region', 'RegionOne'))
  $password            = $ceilometer_hash['user_password']
  $auth_name           = pick($ceilometer_hash['auth_name'], 'ceilometer')
  $configure_endpoint  = pick($ceilometer_hash['configure_endpoint'], true)
  $configure_user      = pick($ceilometer_hash['configure_user'], true)
  $configure_user_role = pick($ceilometer_hash['configure_user_role'], true)
  $service_name        = pick($ceilometer_hash['service_name'], 'ceilometer')
  $tenant              = pick($ceilometer_hash['tenant'], 'services')
  validate_string($public_address)
  validate_string($password)

  $public_url          = "${public_protocol}://${public_address}:8777"
  $internal_url        = "${internal_protocol}://${internal_address}:8777"
  $admin_url           = "${admin_protocol}://${admin_address}:8777"

  class { '::osnailyfacter::wait_for_keystone_backends':}

  class { '::ceilometer::keystone::auth':
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
