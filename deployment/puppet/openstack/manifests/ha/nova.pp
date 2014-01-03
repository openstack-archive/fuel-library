# HA configuration for OpenStack Nova
class openstack::ha::nova {

  openstack::ha::haproxy_service { 'nova-api-1':
    order       => '040',
    listen_port => 8773,
    public      => true,
  }

  openstack::ha::haproxy_service { 'nova-api-2':
    order       => '050',
    listen_port => 8774,
    public      => true,
  }

  openstack::ha::haproxy_service { 'nova-metadata-api':
    order       => '060',
    listen_port => 8775,
  }

  openstack::ha::haproxy_service { 'nova-api-4':
    order       => '070',
    listen_port => 8776,
    public      => true,
  }
}
