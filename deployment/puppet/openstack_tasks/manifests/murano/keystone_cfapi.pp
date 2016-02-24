class openstack_tasks::murano::keystone_cfapi {

  notice('MODULAR: murano/keystone_cfapi.pp')

  $murano_hash       = hiera_hash('murano', {})
  $public_ip         = hiera('public_vip')
  $management_ip     = hiera('management_vip')
  $region            = hiera('region', 'RegionOne')
  $public_ssl_hash   = hiera_hash('public_ssl')
  $ssl_hash          = hiera_hash('use_ssl', {})

  Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::murano::keystone::cfapi_auth']

  $public_protocol   = get_ssl_property($ssl_hash, $public_ssl_hash, 'murano', 'public', 'protocol', 'http')
  $public_address    = get_ssl_property($ssl_hash, $public_ssl_hash, 'murano', 'public', 'hostname', [$public_ip])

  $internal_protocol = get_ssl_property($ssl_hash, {}, 'murano', 'internal', 'protocol', 'http')
  $internal_address  = get_ssl_property($ssl_hash, {}, 'murano', 'internal', 'hostname', [$management_ip])

  $admin_protocol    = get_ssl_property($ssl_hash, {}, 'murano', 'admin', 'protocol', 'http')
  $admin_address     = get_ssl_property($ssl_hash, {}, 'murano', 'admin', 'hostname', [$management_ip])

  $api_bind_port     = '8083'
  $tenant            = pick($murano_hash['tenant'], 'services')
  $public_url        = "${public_protocol}://${public_address}:${api_bind_port}"
  $internal_url      = "${internal_protocol}://${internal_address}:${api_bind_port}"
  $admin_url         = "${admin_protocol}://${admin_address}:${api_bind_port}"

  #################################################################

  class { '::osnailyfacter::wait_for_keystone_backends':}
  class { '::murano::keystone::cfapi_auth':
    password     => $murano_hash['user_password'],
    region       => $region,
    tenant       => $tenant,
    public_url   => $public_url,
    internal_url => $internal_url,
    admin_url    => $admin_url,
  }

}
