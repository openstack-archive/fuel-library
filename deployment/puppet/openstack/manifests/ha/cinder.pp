# HA configuration for OpenStack Nova
class openstack::ha::cinder (
  $server_names,
  $ipaddresses,
) {

  openstack::ha::haproxy_service { 'cinder-api':
    order                  => '070',
    listen_port            => 8776,
    public                 => true,
    require_service        => 'cinder-api',
    server_names           => $server_names,
    ipaddresses            => $ipaddresses,
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }
}
