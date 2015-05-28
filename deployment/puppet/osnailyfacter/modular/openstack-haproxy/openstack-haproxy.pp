notice('MODULAR: openstack-haproxy.pp')

$use_neutron                    = hiera('use_neutron', false)
$ceilometer_hash                = hiera_hash('ceilometer',{})
$sahara_hash                    = hiera_hash('sahara', {})
$murano_hash                    = hiera_hash('murano', {})
$storage_hash                   = hiera_hash('storage', {})
$controllers                    = hiera('controllers')
$haproxy_nodes                  = hiera('haproxy_nodes', $controllers)

$public_ssl_hash                = hiera('public_ssl')

if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $use_swift = true
} else {
  $use_swift = false
}

if ($use_swift) {
  $swift_proxies = hiera('swift_proxies', $haproxy_nodes)
} elsif ($storage_hash['objects_ceph']) {
  $rgw_servers = hiera('rgw_servers', $controllers)
}

class { '::openstack::ha::haproxy':
      controllers              => $haproxy_nodes,
      public_virtual_ip        => hiera('public_vip'),
      internal_virtual_ip      => hiera('management_vip'),
      horizon_use_ssl          => $public_ssl_hash['horizon'],
      services_use_ssl         => $public_ssl_hash['services'],
      neutron                  => $use_neutron,
      queue_provider           => 'rabbitmq',
      custom_mysql_setup_class => hiera('custom_mysql_setup_class','galera'),
      swift_proxies            => $swift_proxies,
      rgw_servers              => $rgw_servers,
      ceilometer               => $ceilometer_hash['enabled'],
      sahara                   => $sahara_hash['enabled'],
      murano                   => $murano_hash['enabled'],
      is_primary_controller    => hiera('primary_controller'),
}
