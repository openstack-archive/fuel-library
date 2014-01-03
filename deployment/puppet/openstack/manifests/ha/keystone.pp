# HA configuration for OpenStack Keystone
class openstack::ha::keystone {

  openstack::ha::haproxy_service { 'keystone-1':
    order  => 20,
    port   => 5000,
    public => true,
  }

  openstack::ha::haproxy_service { 'keystone-2':
    order  => 30,
    port   => 35357,
    public => true,
  }
}
