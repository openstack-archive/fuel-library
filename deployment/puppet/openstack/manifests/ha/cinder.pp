# HA configuration for OpenStack Nova
class openstack::ha::cinder {

  openstack::ha::haproxy_service { 'cinder-api':
    order                  => '070',
    listen_port            => 8776,
    public                 => true,
    require_service        => 'cinder-api',
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }
}
