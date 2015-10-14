notice('MODULAR: compute/cleanup.pp')

$roles = node_roles($nodes_hash, hiera('uid'))
$management_hash   = hiera_hash('cloud_management', {})
$keystone_user     = pick($management_hash['admin_user'], 'admin')
$keystone_tenant   = pick($management_hash['tenant'], 'admin')
$keystone_password = pick($management_hash['admin_password'], 'admin')
$service_endpoint  = hiera('service_endpoint')
$region            = hiera('region', 'RegionOne')

# only run cleanup on controller nodes
if member($roles, 'controller') or member($roles, 'primary-controller') {
  exec { 'remove down compute services':
    command     => '/usr/sbin/compute-down-services.sh cleanup',
    onlyif      => 'test -n "$(/usr/sbin/compute-down-services.sh list)"',
    path        => '/sbin:/usr/sbin:/bin:/usr/bin',
    environment => [
      "OS_TENANT_NAME=${keystone_tenant}",
      "OS_USERNAME=${keystone_user}",
      "OS_PASSWORD=${keystone_password}",
      "OS_AUTH_URL=http://${service_endpoint}:5000/v2.0/",
      'OS_ENDPOINT_TYPE=internalURL',
      "NOVA_ENDPOINT_TYPE=internalURL",
      "OS_REGION_NAME=${region}",
    ],

  }
}
