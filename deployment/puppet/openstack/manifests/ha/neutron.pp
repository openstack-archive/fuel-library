# HA configuration for OpenStack Neutron
class openstack::ha::neutron {

  openstack::ha::haproxy_service { 'neutron':
    order          => 85,
    port           => 9696,
    public         => true,
    define_backend => true,
  }
}
