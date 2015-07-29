notice('MODULAR: openstack-controller/keystone.pp')

$nova_hash           = hiera_hash('nova', {})
$public_vip          = hiera('public_vip')
$public_ssl_hash     = hiera('public_ssl')
$public_address      = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}
$public_protocol     = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}
$admin_protocol      = 'http'
$admin_address       = hiera('management_vip')
$region              = pick($nova_hash['region'], 'RegionOne')

$password            = $nova_hash['user_password']
$auth_name           = pick($nova_hash['auth_name'], 'nova')
$configure_endpoint  = pick($nova_hash['configure_endpoint'], true)
$configure_user      = pick($nova_hash['configure_user'], true)
$configure_user_role = pick($nova_hash['configure_user_role'], true)
$service_name        = pick($nova_hash['service_name'], 'nova')
$tenant              = pick($nova_hash['tenant'], 'services')

$compute_port    = '8774'
$compute_version = 'v2'
$public_url      = "${public_protocol}://${public_address}:${compute_port}/${compute_version}/%(tenant_id)s"
$admin_url       = "${admin_protocol}://${admin_address}:${compute_port}/${compute_version}/%(tenant_id)s"

$ec2_public_url   = "http://${public_address}:8773/services/Cloud"
$ec2_internal_url = "http://${admin_address}:8773/services/Cloud"
$ec2_admin_url    = "http://${admin_address}:8773/services/Admin"

validate_string($public_address)
validate_string($password)

class { '::nova::keystone::auth':
  password               => $password,
  auth_name              => $auth_name,
  configure_endpoint     => $configure_endpoint,
  configure_user         => $configure_user,
  configure_user_role    => $configure_user_role,
  service_name           => $service_name,
  public_url             => $public_url,
  internal_url           => $admin_url,
  admin_url              => $admin_url,
  region                 => $region,
  ec2_public_url         => $ec2_public_url,
  ec2_internal_url       => $ec2_internal_url,
  ec2_admin_url          => $ec2_admin_url,
}
