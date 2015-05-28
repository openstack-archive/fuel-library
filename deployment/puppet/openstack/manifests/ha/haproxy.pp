# Configuration of HAProxy for OpenStack
class openstack::ha::haproxy (
  $controllers,
  $public_virtual_ip,
  $internal_virtual_ip,
  $horizon_use_ssl          = false,
  $services_use_ssl         = false,
  $neutron                  = false,
  $queue_provider           = 'rabbitmq',
  $custom_mysql_setup_class = 'galera',
  $swift_proxies            = undef,
  $rgw_servers              = undef,
  $ceilometer               = undef,
  $sahara                   = undef,
  $murano                   = undef,
  $is_primary_controller    = false,
) {

  Haproxy::Service        { use_include => true }
  Haproxy::Balancermember { use_include => true }

  Openstack::Ha::Haproxy_service {
    server_names        => filter_hash($controllers, 'name'),
    ipaddresses         => filter_hash($controllers, 'internal_address'),
    public_virtual_ip   => $public_virtual_ip,
    internal_virtual_ip => $internal_virtual_ip,
  }

  class { 'openstack::ha::horizon': use_ssl => $horizon_use_ssl }
  class { 'openstack::ha::keystone': public_ssl => $services_use_ssl }
  class { 'openstack::ha::nova': public_ssl => $services_use_ssl }
  class { 'openstack::ha::heat': public_ssl => $services_use_ssl }
  class { 'openstack::ha::glance': public_ssl => $services_use_ssl }
  class { 'openstack::ha::cinder': public_ssl => $services_use_ssl }

  if $neutron { class { 'openstack::ha::neutron': public_ssl => $services_use_ssl } }

  if $custom_mysql_setup_class == 'galera' {
    class { 'openstack::ha::mysqld':
      is_primary_controller => $is_primary_controller,
    }
  }

  if $swift_proxies { 
    class { 'openstack::ha::swift': 
      servers    => $swift_proxies,
      public_ssl => $services_use_ssl,
    } 
  }
  if $rgw_servers   { 
    class { 'openstack::ha::radosgw':
      servers    => $rgw_servers,
      public_ssl => $services_use_ssl,
    }
  }
  if $ceilometer    { class { 'openstack::ha::ceilometer': public_ssl => $services_use_ssl } }
  if $sahara        { class { 'openstack::ha::sahara': public_ssl => $services_use_ssl } }
  if $murano        { class { 'openstack::ha::murano': public_ssl => $services_use_ssl } }
}
