class openstack_tasks::heat::keystone {

  notice('MODULAR: heat/keystone.pp')

  $heat_hash         = hiera_hash('heat', {})
  $public_vip        = hiera('public_vip')
  $region            = pick($heat_hash['region'], hiera('region', 'RegionOne'))
  $management_vip    = hiera('management_vip')
  $public_ssl_hash   = hiera_hash('public_ssl')
  $ssl_hash          = hiera_hash('use_ssl', {})

  $public_protocol   = get_ssl_property($ssl_hash, $public_ssl_hash, 'heat', 'public', 'protocol', 'http')
  $public_address    = get_ssl_property($ssl_hash, $public_ssl_hash, 'heat', 'public', 'hostname', [$public_vip])

  $internal_protocol = get_ssl_property($ssl_hash, {}, 'heat', 'internal', 'protocol', 'http')
  $internal_address  = get_ssl_property($ssl_hash, {}, 'heat', 'internal', 'hostname', [hiera('heat_endpoint', ''), $management_vip])

  $admin_protocol    = get_ssl_property($ssl_hash, {}, 'heat', 'admin', 'protocol', 'http')
  $admin_address     = get_ssl_property($ssl_hash, {}, 'heat', 'admin', 'hostname', [hiera('heat_endpoint', ''), $management_vip])

  $password            = $heat_hash['user_password']
  $auth_name           = pick($heat_hash['auth_name'], 'heat')
  $configure_endpoint  = pick($heat_hash['configure_endpoint'], true)
  $configure_user      = pick($heat_hash['configure_user'], true)
  $configure_user_role = pick($heat_hash['configure_user_role'], true)
  $service_name        = pick($heat_hash['service_name'], 'heat')
  $tenant              = pick($heat_hash['tenant'], 'services')

  Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::heat::keystone::auth']
  Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::heat::keystone::auth_cfn']

  validate_string($public_address)
  validate_string($password)

  $public_url          = "${public_protocol}://${public_address}:8004/v1/%(tenant_id)s"
  $internal_url        = "${internal_protocol}://${internal_address}:8004/v1/%(tenant_id)s"
  $admin_url           = "${admin_protocol}://${admin_address}:8004/v1/%(tenant_id)s"
  $public_url_cfn      = "${public_protocol}://${public_address}:8000/v1"
  $internal_url_cfn    = "${internal_protocol}://${internal_address}:8000/v1"
  $admin_url_cfn       = "${admin_protocol}://${admin_address}:8000/v1"

  class { '::osnailyfacter::wait_for_keystone_backends': }

  class { '::heat::keystone::auth' :
    password               => $password,
    auth_name              => $auth_name,
    region                 => $region,
    tenant                 => $keystone_tenant,
    email                  => "${auth_name}@localhost",
    configure_endpoint     => true,
    configure_user         => $configure_user,
    configure_user_role    => $configure_user_role,
    trusts_delegated_roles => $trusts_delegated_roles,
    public_url             => $public_url,
    internal_url           => $internal_url,
    admin_url              => $admin_url,
  }

  class { '::heat::keystone::auth_cfn' :
    password            => $password,
    auth_name           => "${auth_name}-cfn",
    service_type        => 'cloudformation',
    region              => $region,
    tenant              => $keystone_tenant,
    email               => "${auth_name}-cfn@localhost",
    configure_endpoint  => true,
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    public_url          => $public_url_cfn,
    internal_url        => $internal_url_cfn,
    admin_url           => $admin_url_cfn,
  }

}
