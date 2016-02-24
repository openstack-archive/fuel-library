class openstack_tasks::sahara::keystone {

  notice('MODULAR: sahara/keystone.pp')

  $sahara_hash     = hiera_hash('sahara', {})
  $public_ssl_hash = hiera_hash('public_ssl')
  $public_vip      = hiera('public_vip')
  $admin_address   = hiera('management_vip')
  $api_bind_port   = '8386'
  $sahara_user     = pick($sahara_hash['user'], 'sahara')
  $sahara_password = pick($sahara_hash['user_password'])
  $tenant          = pick($sahara_hash['tenant'], 'services')
  $region          = pick($sahara_hash['region'], hiera('region', 'RegionOne'))
  $service_name    = pick($sahara_hash['service_name'], 'sahara')
  $public_address = $public_ssl_hash['services'] ? {
    true    => $public_ssl_hash['hostname'],
    default => $public_vip,
  }
  $public_protocol = $public_ssl_hash['services'] ? {
    true    => 'https',
    default => 'http',
  }
  $public_url      = "${public_protocol}://${public_address}:${api_bind_port}/v1.1/%(tenant_id)s"
  $admin_url       = "http://${admin_address}:${api_bind_port}/v1.1/%(tenant_id)s"

  Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::sahara::keystone::auth']

  class { '::osnailyfacter::wait_for_keystone_backends':}
  class { '::sahara::keystone::auth':
    auth_name    => $sahara_user,
    password     => $sahara_password,
    service_type => 'data-processing',
    service_name => $service_name,
    region       => $region,
    tenant       => $tenant,
    public_url   => $public_url,
    admin_url    => $admin_url,
    internal_url => $admin_url,
  }

}
