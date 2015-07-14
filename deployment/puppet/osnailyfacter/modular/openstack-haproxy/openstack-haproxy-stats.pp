notice('MODULAR: openstack-haproxy-stats.pp')

  $server_names        = 'localhost'
  $ipaddresses         = '127.0.0.1'
  $public_virtual_ip   = pick(hiera('public_service_endpoint', undef), hiera('public_vip'))
  $internal_virtual_ip = pick(hiera('service_endpoint', undef), hiera('management_vip'))

  # configure keystone ha proxy
  class { '::openstack::ha::stats':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
