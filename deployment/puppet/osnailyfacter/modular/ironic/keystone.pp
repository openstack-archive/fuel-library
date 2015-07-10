notice('MODULAR: ironic/keystone.pp')

$ironic_hash = hiera_hash('ironic', {})
$public_address = hiera('public_vip')
$internal_address = pick(hiera('internal_address', undef), $public_address)
$admin_address = pick(hiera('management_vip', undef), $internal_address)
$region = pick($ironic_hash['region'], 'RegionOne')

$password = $ironic_hash['user_password']
$auth_name = pick($ironic_hash['auth_name'], 'ironic')
$configure_endpoint = pick($ironic_hash['configure_endpoint'], true)
$configure_user = pick($ironic_hash['configure_user'], true)
$configure_user_role = pick($ironic_hash['configure_user_role'], true)
$service_name = pick($ironic_hash['service_name'], $auth_name)
$tenant = pick($ironic_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

$public_port = '6385'
$admin_port = '6385'
$internal_port = '6385'
$public_protocol = 'http'

$public_url = "${public_protocol}://${public_address}:${public_port}"
$admin_url = "http://${admin_address}:${admin_port}"
$internal_url = "http://${internal_address}:${internal_port}"

class { 'ironic::keystone::auth':
  password            => $password,
  auth_name           => $auth_name,
  configure_endpoint  => $configure_endpoint,
  configure_user      => $configure_user,
  configure_user_role => $configure_user_role,
  service_name        => $service_name,
  region              => $region,
  public_url          => $public_url,
  internal_url        => $internal_url,
  admin_url           => $admin_url
}
