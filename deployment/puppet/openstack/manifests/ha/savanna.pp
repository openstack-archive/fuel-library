# HA configuration for OpenStack Savanna
class openstack::ha::savanna {

  openstack::ha::haproxy_service { 'savanna':
    order           => '150',
    listen_port     => 8386,
    public          => true,
    require_service => 'savanna-api',
  }

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['savanna-api']
}
