notice('MODULAR: openstack-haproxy-stats.pp')

$internal_virtual_ip = hiera('management_vip')

class { '::openstack::ha::stats':
  internal_virtual_ip => $internal_virtual_ip,
}
