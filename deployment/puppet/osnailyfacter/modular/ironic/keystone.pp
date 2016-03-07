notice('MODULAR: ironic/keystone.pp')

$ironic_hash                = hiera_hash('ironic', {})
$public_vip                 = hiera('public_vip')
$management_vip             = hiera('management_vip')
$public_ssl_hash            = hiera('public_ssl')
$ironic_tenant              = pick($ironic_hash['tenant'],'services')
$ironic_user                = pick($ironic_hash['auth_name'],'ironic')
$ironic_user_password       = pick($ironic_hash['user_password'],'ironic')
$configure_endpoint         = pick($ironic_hash['configure_endpoint'], true)
$configure_user             = pick($ironic_hash['configure_user'], true)
$configure_user_role        = pick($ironic_hash['configure_user_role'], true)
$service_name               = pick($ironic_hash['service_name'], 'ironic')

Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['ironic::keystone::auth']

$public_address = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}
$public_protocol = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}

$region                     = hiera('region', 'RegionOne')
$tenant                     = pick($ironic_hash['tenant'], 'services')
$public_url                 = "${public_protocol}://${public_address}:6385"
$admin_url                  = "http://${management_vip}:6385"
$internal_url               = "http://${management_vip}:6385"

class {'::osnailyfacter::wait_for_keystone_backends':}
class { 'ironic::keystone::auth':
  password            => $ironic_user_password,
  region              => $region,
  tenant              => $tenant,
  public_url          => $public_url,
  internal_url        => $internal_url,
  admin_url           => $admin_url,
  configure_endpoint  => $configure_endpoint,
  configure_user      => $configure_user,
  configure_user_role => $configure_user_role,
  service_name        => $service_name,
}
