class openstack_tasks::openstack_controller::keystone {

  notice('MODULAR: openstack_controller/keystone.pp')

  $nova_hash           = hiera_hash('nova', {})
  $public_vip          = hiera('public_vip')
  $management_vip      = hiera('management_vip')
  $public_ssl_hash     = hiera_hash('public_ssl')
  $ssl_hash            = hiera_hash('use_ssl', {})

  $public_protocol     = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'protocol', 'http')
  $public_address      = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'hostname', [$public_vip])

  $internal_protocol   = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'protocol', 'http')
  $internal_address    = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'hostname', [$management_vip])

  $admin_protocol      = get_ssl_property($ssl_hash, {}, 'nova', 'admin', 'protocol', 'http')
  $admin_address       = get_ssl_property($ssl_hash, {}, 'nova', 'admin', 'hostname', [$management_vip])

  $compute_port      = '8774'
  $placement_port      = '8778'
  $public_base_url   = "${public_protocol}://${public_address}:${compute_port}"
  $internal_base_url = "${internal_protocol}://${internal_address}:${compute_port}"
  $admin_base_url    = "${admin_protocol}://${admin_address}:${compute_port}"

  $public_placement_url   = "${public_protocol}://${public_address}:${placement_port}"
  $internal_placement_url = "${internal_protocol}://${internal_address}:${placement_port}"
  $admin_placement_url    = "${admin_protocol}://${admin_address}:${placement_port}"


  $region              = pick($nova_hash['region'], hiera('region', 'RegionOne'))

  $password            = $nova_hash['user_password']
  $auth_name           = pick($nova_hash['auth_name'], 'nova')
  $configure_endpoint  = pick($nova_hash['configure_endpoint'], true)
  $configure_user      = pick($nova_hash['configure_user'], true)
  $configure_user_role = pick($nova_hash['configure_user_role'], true)
  $service_name        = pick($nova_hash['service_name'], 'nova')
  $tenant              = pick($nova_hash['tenant'], 'services')

  validate_string($public_address)
  validate_string($password)

  class { '::osnailyfacter::wait_for_keystone_backends':}->
  class { '::nova::keystone::auth':
    password              => $password,
    auth_name             => $auth_name,
    configure_endpoint    => $configure_endpoint,
    configure_user        => $configure_user,
    configure_user_role   => $configure_user_role,
    service_name          => $service_name,
    public_url            => "${public_base_url}/v2.1",
    internal_url          => "${internal_base_url}/v2.1",
    admin_url             => "${admin_base_url}/v2.1",
    region                => $region,
    tenant                => $tenant,
  }

  class { '::nova::keystone::auth_placement':
    password              => $password,
    configure_endpoint    => $configure_endpoint,
    configure_user        => $configure_user,
    configure_user_role   => $configure_user_role,
    public_url            => "${public_placement_url}/placement",
    internal_url          => "${internal_placement_url}/placement",
    admin_url             => "${admin_placement_url}/placement",
    region                => $region,
    tenant                => $tenant,
  }


  # support compute (v2) legacy endpoint
  keystone::resource::service_identity { 'nova_legacy':
    configure_user      => false,
    configure_user_role => false,
    configure_endpoint  => $configure_endpoint,
    service_type        => 'compute_legacy',
    service_description => 'Openstack Compute Legacy Service',
    service_name        => 'compute_legacy',
    region              => $region,
    auth_name           => "${auth_name}_legacy",
    public_url          => "${public_base_url}/v2/%(tenant_id)s",
    admin_url           => "${admin_base_url}/v2/%(tenant_id)s",
    internal_url        => "${internal_base_url}/v2/%(tenant_id)s",
  }

}
