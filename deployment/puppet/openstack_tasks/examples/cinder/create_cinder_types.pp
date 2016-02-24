#TODO (degorenko): remove this define, when Puppet will be upgraded to 4.x version
define create_cinder_types (
  $volume_backend_names,
  $os_password,
  $os_tenant_name = 'admin',
  $os_username    = 'admin',
  $os_auth_url    = 'http://127.0.0.1:5000/v2.0/',
  $os_region_name = 'RegionOne',
  $vtype          = $name,
  $key            = 'volume_backend_name',
) {

  include ::cinder::client

  cinder::type { $vtype:
    os_password    => $os_password,
    set_key        => $key,
    set_value      => $volume_backend_names[$vtype],
    os_tenant_name => $os_tenant_name,
    os_username    => $os_username,
    os_auth_url    => $os_auth_url,
    os_region_name => $os_region_name,
  }
}

$access_admin    = hiera_hash('access_hash', {})
$public_vip      = hiera('public_vip')
$public_ssl_hash = hiera('public_ssl')
$ssl_hash        = hiera_hash('use_ssl', {})
$region          = hiera('region', 'RegionOne')
$storage_hash    = hiera_hash('storage_hash', {})
$backends        = $storage_hash['volume_backend_names']

$public_protocol    = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'protocol', 'http')
$public_address     = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'hostname', [$public_vip])
$available_backends = delete_values($backends, false)
$backend_names      = keys($available_backends)

create_cinder_types { $backend_names:
  volume_backend_names => $available_backends,
  os_password          => $access_admin['password'],
  os_tenant_name       => $access_admin['tenant'],
  os_username          => $access_admin['user'],
  os_auth_url          => "${public_protocol}://${public_address}:5000/v2.0/",
  os_region_name       => $region,
}
