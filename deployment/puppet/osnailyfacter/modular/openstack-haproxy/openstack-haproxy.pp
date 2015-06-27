notice('MODULAR: openstack-haproxy.pp')

$use_neutron                    = hiera('use_neutron', false)
$ceilometer_hash                = hiera('ceilometer',{})
$sahara_hash                    = hiera('sahara', {})
$murano_hash                    = hiera('murano', {})
$storage_hash                   = hiera('storage', {})
$controllers                    = hiera('controllers')
$public_ssl_hash                = hiera('public_ssl')
$internal_ssl_hash              = hiera('internal_ssl')

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
      public_virtual_ip        => $public_ssl_hash['horizon'] or $public_ssl_hash['services'] ? {
        true    => $public_ssl_hash['hostname'],
        default => hiera('public_vip'),
      },
      internal_virtual_ip      => $internal_ssl_hash['enable'] ? {
        true    => $internal_ssl_hash['hostname'],
        default => hiera('management_vip'),
      },
      horizon_use_ssl          => $public_ssl_hash['horizon'],
      services_use_ssl         => $public_ssl_hash['services'],
      internal_ssl             => $internal_ssl_hash['enable'],
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
