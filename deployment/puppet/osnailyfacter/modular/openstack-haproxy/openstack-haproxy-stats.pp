notice('MODULAR: openstack-haproxy-stats.pp')

$public_virtual_ip   = pick(hiera('public_service_endpoint', undef), hiera('public_vip'))
$internal_virtual_ip = pick(hiera('service_endpoint', undef), hiera('management_vip'))

class { '::openstack::ha::stats':
  internal_virtual_ip => $internal_virtual_ip,
  public_virtual_ip   => $public_virtual_ip,
}
