notice('MODULAR: openstack-haproxy.pp')

$use_neutron                    = hiera('use_neutron', false)
$ceilometer_hash                = hiera('ceilometer',{})
$sahara_hash                    = hiera('sahara', {})
$murano_hash                    = hiera('murano', {})
$storage_hash                   = hiera('storage', {})
$controllers                    = hiera('controllers')

if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $use_swift = true
} else {
  $use_swift = false
}

if ($use_swift) {
  $swift_proxies = $controllers
} elsif ($storage_hash['objects_ceph']) {
  $rgw_servers = $controllers
}

class { '::openstack::ha::haproxy':
      controllers              => $controllers,
      public_virtual_ip        => hiera('public_vip'),
      internal_virtual_ip      => hiera('management_vip'),
      horizon_use_ssl          => hiera('horizon_use_ssl', false),
      neutron                  => $use_neutron,
      queue_provider           => 'rabbitmq',
      custom_mysql_setup_class => 'galera',
      swift_proxies            => $swift_proxies,
      rgw_servers              => $rgw_servers,
      ceilometer               => $ceilometer_hash['enabled'],
      sahara                   => $sahara_hash['enabled'],
      murano                   => $murano_hash['enabled'],
      is_primary_controller    => hiera('primary_controller'),
}
