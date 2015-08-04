notice('MODULAR: openstack-haproxy-stats.pp')

$internal_virtual_ip = unique([hiera('management_vip'), hiera('database_vip'), hiera('service_endpoint')])

class { '::openstack::ha::stats':
  internal_virtual_ip => $internal_virtual_ip,
}
