# HA configuration for OpenStack Swift
class openstack::ha::swift (
  $server_names,
  $ipaddresses,
  $public_ssl = false,
  $internal_ssl => false,
) {

  openstack::ha::haproxy_service { 'swift':
    order        => '120',
    listen_port  => 8080,
    server_names => $server_names,
    ipaddresses  => $ipaddresses,
    public       => true,
    haproxy_config_options => {
        'option'         => ['httpchk', 'httplog', 'httpclose'],
    },
    balancermember_options => 'check port 49001 inter 15s fastinter 2s downinter 8s rise 3 fall 3',
    public_ssl   => $public_ssl,
    internal_ssl => $internal_ssl,
  }
}
