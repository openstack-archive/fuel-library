# HA configuration for OpenStack Keystone
class openstack::ha::keystone (
  $server_names,
  $ipaddresses,
) {

  openstack::ha::haproxy_service { 'keystone-1':
    order                  => '020',
    listen_port            => 5000,
    public                 => true,
    server_names           => $server_names,
    ipaddresses            => $ipaddresses,
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',

  }

  openstack::ha::haproxy_service { 'keystone-2':
    order                  => '030',
    listen_port            => 35357,
    public                 => false,
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',

  }
}
