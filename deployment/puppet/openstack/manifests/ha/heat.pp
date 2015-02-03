# HA configuration for OpenStack Nova
class openstack::ha::heat {

  openstack::ha::haproxy_service { 'heat-api':
    order                  => '160',
    listen_port            => 8004,
    public                 => true,
    require_service        => 'heat-api',
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'heat-api-cfn':
    order                  => '161',
    listen_port            => 8003,
    public                 => true,
    require_service        => 'heat-api',
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'heat-api-cloudwatch':
    order                  => '162',
    listen_port            => 8000,
    public                 => true,
    require_service        => 'heat-api',
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }
}
