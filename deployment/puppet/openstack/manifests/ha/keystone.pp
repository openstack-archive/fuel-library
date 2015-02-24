# HA configuration for OpenStack Keystone
class openstack::ha::keystone {

  openstack::ha::haproxy_service { 'keystone-1':
    order                  => '020',
    listen_port            => 5000,
    public                 => true,
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
