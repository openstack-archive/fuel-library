# HA configuration for OpenStack Nova
class openstack::ha::nova {

  openstack::ha::haproxy_service { 'nova-api-1':
    order           => '040',
    listen_port     => 8773,
    public          => true,
    require_service => 'nova-api',
  }

  openstack::ha::haproxy_service { 'nova-api-2':
    order           => '050',
    listen_port     => 8774,
    public          => true,
    require_service => 'nova-api',
  }

  openstack::ha::haproxy_service { 'nova-metadata-api':
    order           => '060',
    listen_port     => 8775,
    require_service => 'nova-api',
  }

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['nova-api']
}
