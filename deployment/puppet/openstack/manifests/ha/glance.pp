# HA configuration for OpenStack Glance
class openstack::ha::glance {

  openstack::ha::haproxy_service { 'glance-api':
    # before neutron
    order           => '080',
    listen_port     => 9292,
    public          => true,
    require_service => 'glance-api',
  }

  openstack::ha::haproxy_service { 'glance-registry':
    # after neutron
    order           => '090',
    listen_port     => 9191,
    require_service => 'glance-registry',
  }

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['glance-api']
  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['glance-registry']
}
