# HA configuration for OpenStack Nova
class openstack::ha::nova {

  openstack::ha::haproxy_service { 'nova-api-1':
    order  => 40,
    port   => 8773,
    public => true,
  }

  openstack::ha::haproxy_service { 'nova-api-2':
    order  => 50,
    port   => 8774,
    public => true,
  }

  openstack::ha::haproxy_service { 'nova-metadata-api':
    order => 60,
    port  => 8775,
  }

  openstack::ha::haproxy_service { 'nova-api-4':
    order  => 70,
    port   => 8776,
    public => true,
  }
}
