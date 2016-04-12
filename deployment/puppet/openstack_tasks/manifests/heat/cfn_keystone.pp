class openstack_tasks::heat::cfn_keystone {

  notice('MODULAR: heat/cfn_keystone.pp')

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
  $cfn_auth_name       = pick($heat_hash['cfn_auth_name'], 'heat-cfn')
  $configure_endpoint  = pick($heat_hash['configure_endpoint'], true)
  $configure_user      = pick($heat_hash['configure_user'], true)
  $configure_user_role = pick($heat_hash['configure_user_role'], true)
  $service_name        = pick($heat_hash['service_name'], 'heat')
  $tenant              = pick($heat_hash['tenant'], 'services')
  $cfn_auth_email      = pick($heat_hash['cfn_auth_email'], "${cfn_auth_name}@localhost")

  Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::heat::keystone::auth_cfn']

  validate_string($public_address)
  validate_string($password)

  $public_url_cfn      = "${public_protocol}://${public_address}:8000/v1"
  $internal_url_cfn    = "${internal_protocol}://${internal_address}:8000/v1"
  $admin_url_cfn       = "${admin_protocol}://${admin_address}:8000/v1"

  class { '::osnailyfacter::wait_for_keystone_backends': }

  class { '::heat::keystone::auth_cfn' :
    password            => $password,
    auth_name           => $cfn_auth_name,
    service_type        => 'cloudformation',
    region              => $region,
    tenant              => $keystone_tenant,
    email               => $cfn_auth_email,
    configure_endpoint  => true,
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    public_url          => $public_url_cfn,
    internal_url        => $internal_url_cfn,
    admin_url           => $admin_url_cfn,
  }

}
