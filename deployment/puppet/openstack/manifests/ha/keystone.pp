# HA configuration for OpenStack Keystone
class openstack::ha::keystone {

  openstack::ha::haproxy_service { 'keystone-1':
    order           => '020',
    listen_port     => 5000,
    public          => true,
  }

  openstack::ha::haproxy_service { 'keystone-2':
    order           => '030',
    listen_port     => 35357,
    public          => true,
  }
  Openstack::Ha::Haproxy_service['keystone-1', 'keystone-2']->Service<| title=='keystone' |>
}
