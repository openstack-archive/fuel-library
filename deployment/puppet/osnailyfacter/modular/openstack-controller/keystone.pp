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
$region              = pick($nova_hash['region'], hiera('region', 'RegionOne'))

$password            = $nova_hash['user_password']
$auth_name           = pick($nova_hash['auth_name'], 'nova')
$configure_endpoint  = pick($nova_hash['configure_endpoint'], true)
$configure_user      = pick($nova_hash['configure_user'], true)
$configure_user_role = pick($nova_hash['configure_user_role'], true)
$service_name        = pick($nova_hash['service_name'], 'nova')
$tenant              = pick($nova_hash['tenant'], 'services')

$compute_port     = '8774'
$public_base_url  = "${public_protocol}://${public_address}:${compute_port}"
$admin_base_url   = "${admin_protocol}://${admin_address}:${compute_port}"

$ec2_port         = '8773'
$ec2_public_url   = "${public_protocol}://${public_address}:${ec2_port}/services/Cloud"
$ec2_internal_url = "${admin_protocol}://${admin_address}:${ec2_port}/services/Cloud"
$ec2_admin_url    = "${admin_protocol}://${admin_address}:${ec2_port}/services/Admin"

validate_string($public_address)
validate_string($password)

class { '::nova::keystone::auth':
  password              => $password,
  auth_name             => $auth_name,
  configure_endpoint    => $configure_endpoint,
  configure_endpoint_v3 => $configure_endpoint,
  configure_user        => $configure_user,
  configure_user_role   => $configure_user_role,
  service_name          => $service_name,
  public_url            => "${public_base_url}/v2/%(tenant_id)s",
  public_url_v3         => "${public_base_url}/v3",
  internal_url          => "${admin_base_url}/v2/%(tenant_id)s",
  internal_url_v3       => "${admin_base_url}/v3",
  admin_url             => "${admin_base_url}/v2/%(tenant_id)s",
  admin_url_v3          => "${admin_base_url}/v3",
  region                => $region,
  ec2_public_url        => $ec2_public_url,
  ec2_internal_url      => $ec2_internal_url,
  ec2_admin_url         => $ec2_admin_url,
}
