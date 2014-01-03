# HA configuration for OpenStack Ceilometer
class openstack::ha::ceilometer {

  openstack::ha::haproxy_service { 'ceilometer':
    order           => '140',
    listen_port     => 8777,
    public          => true,
    require_service => 'ceilometer-api',
  }

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['ceilometer-api']
}
