notice('MODULAR: openstack-controller/keystone.pp')

$nova_hash           = hiera_hash('nova', {})
$public_vip          = hiera('public_vip')
$management_vip      = hiera('management_vip')
$public_ssl_hash     = hiera('public_ssl')
$ssl_hash            = hiera_hash('use_ssl', {})

$public_protocol     = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'protocol', 'http')
$public_address      = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'hostname', [$public_vip])

$internal_protocol   = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'protocol', 'http')
$internal_address    = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'hostname', [$management_vip])

$admin_protocol      = get_ssl_property($ssl_hash, {}, 'nova', 'admin', 'protocol', 'http')
$admin_address       = get_ssl_property($ssl_hash, {}, 'nova', 'admin', 'hostname', [$management_vip])

$compute_port      = '8774'
$public_base_url   = "${public_protocol}://${public_address}:${compute_port}"
$internal_base_url = "${internal_protocol}://${internal_address}:${compute_port}"
$admin_base_url    = "${admin_protocol}://${admin_address}:${compute_port}"

$ec2_port         = '8773'
$ec2_public_url   = "${public_protocol}://${public_address}:${ec2_port}/services/Cloud"
$ec2_internal_url = "${internal_protocol}://${internal_address}:${ec2_port}/services/Cloud"
$ec2_admin_url    = "${admin_protocol}://${admin_address}:${ec2_port}/services/Admin"

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

class {'::osnailyfacter::wait_for_keystone_backends':}->
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
  internal_url          => "${internal_base_url}/v2/%(tenant_id)s",
  internal_url_v3       => "${internal_base_url}/v3",
  admin_url             => "${admin_base_url}/v2/%(tenant_id)s",
  admin_url_v3          => "${admin_base_url}/v3",
  region                => $region,
  tenant                => $tenant,
  ec2_public_url        => $ec2_public_url,
  ec2_internal_url      => $ec2_internal_url,
  ec2_admin_url         => $ec2_admin_url,
}
