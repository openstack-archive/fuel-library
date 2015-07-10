notice('MODULAR: ironic/api.pp')

$ironic_hash    = hiera_hash('ironic', {})
$management_vip = hiera('management_vip', undef)


$admin_password = $ironic_hash[user_password]
$admin_tenant_name = pick($ironic_hash['tenant'], 'services')
$auth_uri = "http://${management_vip}:5000/v2.0/"
$auth_user = pick($ironic_hash['auth_name'], 'ironic')
$auth_host = $management_vip
$auth_port = '35357'
$auth_protocol = 'http'

$neutron_url = "http://${management_vip}:9696"

class { '::ironic::api':
  admin_password    => $admin_password,
  auth_uri          => $auth_uri,
  auth_host         => $auth_host,
  auth_port         => $auth_port,
  auth_protocol     => $auth_protocol,
  admin_tenant_name => $admin_tenant_name,
  admin_user        => $admin_user,
  neutron_url       => $neutron_url,
}
