# HA configuration for OpenStack Swift
class openstack::ha::swift (
  $servers,
) {

  openstack::ha::haproxy_service { 'swift':
    order        => '120',
    listen_port  => 8080,
    server_names => filter_hash($servers, 'name'),
    ipaddresses  => filter_hash($servers, 'storage_address'),
    public       => true,
    haproxy_config_options => {
        'option'         => ['httpchk', 'httplog', 'httpclose'],
    },
    balancermember_options => 'check port 49001 inter 15s fastinter 2s downinter 8s rise 3 fall 3',
  }
}
