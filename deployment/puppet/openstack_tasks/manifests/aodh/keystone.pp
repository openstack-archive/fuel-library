class openstack_tasks::aodh::keystone {

  notice('MODULAR: aodh/keystone.pp')

  $aodh_hash            = hiera_hash('aodh', {})
  $aodh_user_name       = pick($aodh_hash['user'], 'aodh')
  $aodh_user_password   = $aodh_hash['user_password']
  $service_name         = pick($aodh_hash['service'], 'aodh')
  $region               = pick($aodh_hash['region'], hiera('region', 'RegionOne'))
  $tenant               = pick($aodh_hash['tenant'], 'services')

  $public_vip      = hiera('public_vip')
  $public_ssl_hash = hiera('public_ssl')
  $public_address  = $public_ssl_hash['services'] ? {
    true    => $public_ssl_hash['hostname'],
    default => $public_vip,
  }
  $public_protocol = $public_ssl_hash['services'] ? {
    true    => 'https',
    default => 'http',
  }

  $ssl_hash               = hiera_hash('use_ssl', {})
  $management_vip         = hiera('management_vip')
  $aodh_api_bind_port     = '8042'
  $public_url             = "${public_protocol}://${public_address}:${aodh_api_bind_port}"
  $internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $admin_url              = "${internal_auth_protocol}://${management_vip}:${aodh_api_bind_port}"

  #################################################################

  Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::aodh::keystone::auth']

  class { '::osnailyfacter::wait_for_keystone_backends':}

  class { '::aodh::keystone::auth':
    auth_name    => $aodh_user_name,
    password     => $aodh_user_password,
    service_type => 'alarming',
    service_name => $service_name,
    region       => $region,
    tenant       => $tenant,
    public_url   => $public_url,
    internal_url => $admin_url,
    admin_url    => $admin_url,
  }

}
