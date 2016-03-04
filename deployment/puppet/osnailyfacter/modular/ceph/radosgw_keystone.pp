$storage_hash = hiera_hash('storage', {})

if $storage_hash['objects_ceph'] {
  notice('MODULAR: radosgw/keystone.pp')
  $public_vip      = hiera('public_vip')
  $region          = hiera('region', 'RegionOne')
  $admin_address   = hiera('management_vip')
  $public_ssl_hash = hiera_hash('public_ssl')

  $public_address    = $public_ssl_hash['services'] ? {
    true    => $public_ssl_hash['hostname'],
    default => $public_vip,
  }
  $public_protocol   = $public_ssl_hash['services'] ? {
    true    => 'https',
    default => 'http',
  }
  $public_url        = "${public_protocol}://${public_address}:8080/swift/v1"
  $admin_url         = "http://${admin_address}:8080/swift/v1"

  validate_string($public_address)

  keystone::resource::service_identity { 'radosgw':
    configure_user      => false,
    configure_user_role => false,
    service_type        => 'object-store',
    service_description => 'Openstack Object-Store Service',
    service_name        => 'swift',
    region              => $region,
    public_url          => $public_url,
    admin_url           => $admin_url,
    internal_url        => $admin_url,
  }
}
