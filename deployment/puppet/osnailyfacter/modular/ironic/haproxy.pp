notice('MODULAR: haproxy.pp')


# HA configuration for OpenStack Ironic
$controllers                    = hiera('controllers')
$haproxy_nodes                  = hiera('haproxy_nodes', $controllers)
$controllers_server_names = filter_hash($controllers, 'name')
$controllers_ipaddresses  = filter_hash($controllers, 'internal_address')

$public_virtual_ip = hiera('public_vip')
$internal_virtual_ip = hiera('management_vip')

Openstack::Ha::Haproxy_service {
  server_names        => $controllers_server_names,
  ipaddresses         => $controllers_ipaddresses,
  public_virtual_ip   => $public_virtual_ip,
  internal_virtual_ip => $internal_virtual_ip,
}

$server_names = hiera_array('keystone_names', $controllers_server_names)
$ipaddresses = hiera_array('keystone_ipaddresses', $controllers_ipaddresses)

notify {"$server_names":}
notify {"$ipaddresses":}


openstack::ha::haproxy_service { 'ironic-api':
  order                  => '200',
  listen_port            => 6385,
  public                 => true,
  require_service        => 'ironic-api',
  server_names           => $server_names,
  ipaddresses            => $ipaddresses,
  haproxy_config_options => {
      option => ['httpchk', 'httplog','httpclose'],
  },
  balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
}
