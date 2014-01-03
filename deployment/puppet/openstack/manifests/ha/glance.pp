# HA configuration for OpenStack Glance
class openstack::ha::glance {

  openstack::ha::haproxy_service { 'glance-api':
    # before neutron
    order       => '080',
    listen_port => 9292,
    public      => true,
  }

  openstack::ha::haproxy_service { 'glance-reg':
    # after neutron
    order       => '090',
    listen_port => 9191,
  }
}
