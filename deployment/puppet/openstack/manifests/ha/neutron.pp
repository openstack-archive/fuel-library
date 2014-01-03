# HA configuration for OpenStack Neutron
class openstack::ha::neutron {

  openstack::ha::haproxy_service { 'neutron':
    order          => '085',
    listen_port    => 9696,
    public         => true,
    define_backups => true,
  }

  Openstack::Ha::Haproxy_service['mysqld']  -> Class['neutron::waistline']
  Openstack::Ha::Haproxy_service['neutron'] -> Class['neutron::waistline']
}
