# HA configuration for OpenStack Nova
class openstack::ha::heat {

  openstack::ha::haproxy_service { 'heat-api':
    order           => '160',
    listen_port     => 8004,
    public          => true,
    require_service => 'heat-api',
    bind_options    => 'ssl crt /etc/haproxy/haproxy_ca.pem',
  }

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['heat-api']
}
