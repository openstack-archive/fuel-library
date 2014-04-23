# HA configuration for OpenStack Murano
class openstack::ha::murano {

  openstack::ha::haproxy_service { 'murano':
    order           => '180',
    listen_port     => 8082,
    public          => true,
    require_service => 'murano_api',
  }

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['murano_api']
}