class openstack_tasks::swift::keystone {

  notice('MODULAR: swift/keystone.pp')

  $swift_hash         = hiera_hash('swift', {})
  $public_vip         = hiera('public_vip')
  # Allow a plugin to override the admin address using swift_hash:
  $management_vip     = pick($swift_hash['management_vip'], hiera('management_vip'))
  $region             = pick($swift_hash['region'], hiera('region', 'RegionOne'))
  $public_ssl_hash    = hiera_hash('public_ssl')
  $ssl_hash           = hiera_hash('use_ssl', {})

  $public_protocol    = get_ssl_property($ssl_hash, $public_ssl_hash, 'swift', 'public', 'protocol', 'http')
  $public_address     = get_ssl_property($ssl_hash, $public_ssl_hash, 'swift', 'public', 'hostname', [$swift_hash['public_vip'], $public_vip])

  $internal_protocol  = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'protocol', 'http')
  $internal_address   = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'hostname', [$management_vip])

  $admin_protocol  = get_ssl_property($ssl_hash, {}, 'swift', 'admin', 'protocol', 'http')
  $admin_address   = get_ssl_property($ssl_hash, {}, 'swift', 'admin', 'hostname', [$management_vip])

  $password            = $swift_hash['user_password']
  $auth_name           = pick($swift_hash['auth_name'], 'swift')
  $configure_endpoint  = pick($swift_hash['configure_endpoint'], true)
  $configure_user      = pick($swift_hash['configure_user'], true)
  $configure_user_role = pick($swift_hash['configure_user_role'], true)
  $service_name        = pick($swift_hash['service_name'], 'swift')
  $tenant              = pick($swift_hash['tenant'], 'services')

  Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::swift::keystone::auth']

  validate_string($public_address)
  validate_string($password)

  $public_url          = "${public_protocol}://${public_address}:8080/v1/AUTH_%(tenant_id)s"
  $internal_url        = "${internal_protocol}://${internal_address}:8080/v1/AUTH_%(tenant_id)s"
  $admin_url           = "${admin_protocol}://${admin_address}:8080/v1/AUTH_%(tenant_id)s"

  # Amazon S3 endpoints
  $public_url_s3       = "${public_protocol}://${public_address}:8080"
  $internal_url_s3     = "${internal_protocol}://${internal_address}:8080"
  $admin_url_s3        = "${admin_protocol}://${admin_address}:8080"

  class { '::osnailyfacter::wait_for_keystone_backends':}
  class { '::swift::keystone::auth':
    password            => $password,
    auth_name           => $auth_name,
    configure_endpoint  => $configure_endpoint,
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    service_name        => $service_name,
    public_url          => $public_url,
    internal_url        => $internal_url,
    admin_url           => $admin_url,
    public_url_s3       => $public_url_s3,
    internal_url_s3     => $internal_url_s3,
    admin_url_s3        => $admin_url_s3,
    region              => $region,
    tenant              => $tenant,
  }

}
