# HA configuration for OpenStack Neutron
class openstack::ha::neutron (
  $server_names,
  $ipaddresses,
) {

  openstack::ha::haproxy_service { 'neutron':
    order                  => '085',
    listen_port            => 9696,
    public                 => true,
    define_backups         => false,
    server_names           => $server_names,
    ipaddresses            => $ipaddresses,
    #NOTE(bogdando) do not add require_service => 'neutron-server', will cause a loop
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }
}
