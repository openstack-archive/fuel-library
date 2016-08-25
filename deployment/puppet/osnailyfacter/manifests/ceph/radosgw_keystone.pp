class osnailyfacter::ceph::radosgw_keystone {

  notice('MODULAR: ceph/radosgw_keystone.pp')

  $storage_hash = hiera_hash('storage', {})

  $public_vip      = hiera('public_vip')
  $region          = hiera('region', 'RegionOne')
  $management_vip  = hiera('management_vip')
  $public_ssl_hash = hiera_hash('public_ssl')
  $ssl_hash        = hiera_hash('use_ssl', {})

  $public_protocol   = get_ssl_property($ssl_hash, $public_ssl_hash, 'radosgw', 'public', 'protocol', 'http')
  $public_address    = get_ssl_property($ssl_hash, $public_ssl_hash, 'radosgw', 'public', 'hostname', [$public_vip])

  $internal_protocol = get_ssl_property($ssl_hash, {}, 'radosgw', 'internal', 'protocol', 'http')
  $internal_address  = get_ssl_property($ssl_hash, {}, 'radosgw', 'internal', 'hostname', [$management_vip])

  $admin_protocol    = get_ssl_property($ssl_hash, {}, 'radosgw', 'admin', 'protocol', 'http')
  $admin_address     = get_ssl_property($ssl_hash, {}, 'radosgw', 'admin', 'hostname', [$management_vip])

  $public_url        = "${public_protocol}://${public_address}:8080/swift/v1"
  $internal_url      = "${internal_protocol}://${internal_address}:8080/swift/v1"
  $admin_url         = "${admin_protocol}://${admin_address}:8080/swift/v1"

  $public_url_s3     = "${public_protocol}://${public_address}:8080"
  $internal_url_s3   = "${internal_protocol}://${internal_address}:8080"
  $admin_url_s3      = "${admin_protocol}://${admin_address}:8080"

  class {'::osnailyfacter::wait_for_keystone_backends': }

  keystone::resource::service_identity { 'radosgw':
    configure_user      => false,
    configure_user_role => false,
    service_type        => 'object-store',
    service_description => 'Openstack Object-Store Service',
    service_name        => 'swift',
    region              => $region,
    public_url          => $public_url,
    admin_url           => $admin_url,
    internal_url        => $internal_url,
  }->

  keystone::resource::service_identity { 'radosgw_s3':
    configure_user      => false,
    configure_user_role => false,
    service_type        => 's3',
    service_description => 'Openstack Object-Store Service',
    service_name        => 'swift_s3',
    region              => $region,
    public_url          => $public_url_s3,
    admin_url           => $admin_url_s3,
    internal_url        => $internal_url_s3,
  }

  Class['::osnailyfacter::wait_for_keystone_backends'] -> Keystone::Resource::Service_Identity['radosgw']
}
