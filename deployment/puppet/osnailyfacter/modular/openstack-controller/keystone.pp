notice('MODULAR: openstack-controller/keystone.pp')

$nova_hash           = hiera_hash('nova', {})
$public_vip          = hiera('public_vip')
$management_vip      = hiera('management_vip')
$public_ssl_hash     = hiera('public_ssl')
$ssl_hash            = hiera_hash('use_ssl', {})
if $public_ssl_hash['services'] or try_get_value($ssl_hash, 'nova_public', false) {
  $public_address  = pick(try_get_value($ssl_hash, 'nova_public_hostname', ''), $public_ssl_hash['hostname'])
  $public_protocol = 'https'
} else {
  $public_address  = $public_vip
  $public_protocol = 'http'
}
if try_get_value($ssl_hash, 'nova_internal', false) {
  $internal_protocol = 'https'
  $internal_address  = pick($ssl_hash['nova_internal_hostname'], $management_vip)
} else {
  $internal_protocol = 'http'
  $internal_address  = $management_vip
}
if try_get_value($ssl_hash, 'nova_admin', false) {
  $admin_protocol = 'https'
  $admin_address  = pick($ssl_hash['nova_admin_hostname'], $management_vip)
} else {
  $admin_protocol = 'http'
  $admin_address  = $management_vip
}
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
  ec2_public_url        => $ec2_public_url,
  ec2_internal_url      => $ec2_internal_url,
  ec2_admin_url         => $ec2_admin_url,
}
