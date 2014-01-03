# HA configuration for OpenStack Ceilometer
class openstack::ha::ceilometer {

  openstack::ha::haproxy_service { 'ceilometer':
    order   => 98,
    port    => 8777,
    public  => true,
    service => 'ceilometer-api',
  }
}
