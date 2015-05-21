# HA configuration for OpenStack Glance
class openstack::ha::glance {

  openstack::ha::haproxy_service { 'glance-api':
    # before neutron
    order                  => '080',
    listen_port            => 9292,
    public                 => true,
    require_service        => 'glance-api',
    haproxy_config_options => {
        'option'         => ['httpchk', 'httplog','httpclose'],
        'timeout server' => '11m',
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'glance-registry':
    # after neutron
    order                  => '090',
    listen_port            => 9191,
    require_service        => 'glance-registry',
    haproxy_config_options => {
        'timeout server' => '11m',
    },
  }
}
