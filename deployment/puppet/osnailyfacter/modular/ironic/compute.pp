notice('MODULAR: ironic/compute_ironic.pp')

$ironic_hash    = hiera_hash('ironic', {})
$admin_user = pick($ironic_hash['auth_name'], 'ironic')
$admin_password = $ironic_hash[user_password]

$management_vip    = hiera('management_vip')
$service_endpoint  = hiera('service_endpoint', $management_vip)
$keystone_endpoint = hiera('keystone_endpoint', $service_endpoint)
$auth_url          = "http://${keystone_endpoint}:35357/v2.0"

$admin_tenant_name = pick($ironic_hash['tenant'], 'services')

$public_address = hiera('public_vip')
$internal_address = pick(hiera('internal_address', undef), $public_address)
$internal_port = '6385'
$internal_url = "http://${internal_address}:${internal_port}"

class {'::nova::compute::ironic':
#  admin_username    => $admin_user,
  admin_user        => $admin_user,
#  admin_password    => $admin_password,
  admin_passwd      => $admin_password,
  admin_url         => $auth_url,
  admin_tenant_name => $admin_tenant_name,
  api_endpoint      => $internal_url,
}
