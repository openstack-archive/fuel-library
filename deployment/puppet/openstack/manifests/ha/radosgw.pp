# HA configuration for Ceph RADOS Gateway
class openstack::ha::radosgw (
  $server_names,
  $ipaddresses,
) {

  openstack::ha::haproxy_service { 'radosgw':
    order               => '130',
    listen_port         => 8080,
    balancermember_port => 6780,
    server_names        => $server_names,
    ipaddresses         => $ipaddresses,
    public              => true,

    haproxy_config_options => {
      'option'         => ['httplog', 'httpchk GET /'],
    },
  }
}
