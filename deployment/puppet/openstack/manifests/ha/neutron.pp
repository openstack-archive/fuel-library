# HA configuration for OpenStack Neutron
class openstack::ha::neutron {

  openstack::ha::haproxy_service { 'neutron':
    order                  => '085',
    listen_port            => 9696,
    public                 => true,
    define_backups         => false,
    #NOTE(bogdando) do not add require_service => 'neutron-server', will cause a loop
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['neutron-server']
  Openstack::Ha::Haproxy_service['neutron'] -> Class['neutron::waistline']
  Openstack::Ha::Haproxy_service['neutron'] -> Anchor['neutron-api-up']
}
