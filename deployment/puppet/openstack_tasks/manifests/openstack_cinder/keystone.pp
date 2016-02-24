class openstack_tasks::openstack_cinder::keystone {

  notice('MODULAR: openstack_cinder/keystone.pp')

  $cinder_hash         = hiera_hash('cinder', {})
  $public_ssl_hash     = hiera_hash('public_ssl')
  $ssl_hash            = hiera_hash('use_ssl', {})
  $public_vip          = hiera('public_vip')
  $management_vip      = hiera('management_vip')

  Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::cinder::keystone::auth']

  $public_protocol     = get_ssl_property($ssl_hash, $public_ssl_hash, 'cinder', 'public', 'protocol', 'http')
  $public_address      = get_ssl_property($ssl_hash, $public_ssl_hash, 'cinder', 'public', 'hostname', [$public_vip])

  $internal_protocol   = get_ssl_property($ssl_hash, {}, 'cinder', 'internal', 'protocol', 'http')
  $internal_address    = get_ssl_property($ssl_hash, {}, 'cinder', 'internal', 'hostname', [$management_vip])

  $admin_protocol      = get_ssl_property($ssl_hash, {}, 'cinder', 'admin', 'protocol', 'http')
  $admin_address       = get_ssl_property($ssl_hash, {}, 'cinder', 'admin', 'hostname', [$management_vip])

  $port = '8776'

  $public_base_url     = "${public_protocol}://${public_address}:${port}"
  $internal_base_url   = "${internal_protocol}://${internal_address}:${port}"
  $admin_base_url      = "${admin_protocol}://${admin_address}:${port}"

  $region              = pick($cinder_hash['region'], hiera('region', 'RegionOne'))
  $password            = $cinder_hash['user_password']
  $auth_name           = pick($cinder_hash['auth_name'], 'cinder')
  $configure_endpoint  = pick($cinder_hash['configure_endpoint'], true)
  $configure_user      = pick($cinder_hash['configure_user'], true)
  $configure_user_role = pick($cinder_hash['configure_user_role'], true)
  $service_name        = pick($cinder_hash['service_name'], 'cinder')
  $tenant              = pick($cinder_hash['tenant'], 'services')

  validate_string($public_address)
  validate_string($internal_address)
  validate_string($admin_address)
  validate_string($password)

  class { '::osnailyfacter::wait_for_keystone_backends':}
  class { '::cinder::keystone::auth':
    password            => $password,
    auth_name           => $auth_name,
    configure_endpoint  => $configure_endpoint,
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    service_name        => $service_name,
    public_url          => "${public_base_url}/v1/%(tenant_id)s",
    internal_url        => "${internal_base_url}/v1/%(tenant_id)s",
    admin_url           => "${admin_base_url}/v1/%(tenant_id)s",
    public_url_v2       => "${public_base_url}/v2/%(tenant_id)s",
    internal_url_v2     => "${internal_base_url}/v2/%(tenant_id)s",
    admin_url_v2        => "${admin_base_url}/v2/%(tenant_id)s",
    public_url_v3       => "${public_base_url}/v3/%(tenant_id)s",
    internal_url_v3     => "${internal_base_url}/v3/%(tenant_id)s",
    admin_url_v3        => "${admin_base_url}/v3/%(tenant_id)s",
    region              => $region,
    tenant              => $tenant,
  }

}
