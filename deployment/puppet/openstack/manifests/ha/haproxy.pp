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

  $controllers_server_names = filter_hash($controllers, 'name')
  $controllers_ipaddresses  = filter_hash($controllers, 'internal_address')

  Openstack::Ha::Haproxy_service {
    server_names        => $controllers_server_names,
    ipaddresses         => $controllers_ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    internal_virtual_ip => $internal_virtual_ip,
  }

  $network_metadata = hiera_hash('network_metadata')

  $horizon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('horizon_nodes'), 'horizon')
  class { 'openstack::ha::horizon':
    use_ssl      => $horizon_use_ssl,
    server_names => hiera_array('horizon_names', keys($horizon_address_map)),
    ipaddresses  => hiera_array('horizon_ipaddresses', values($horizon_address_map)),
  }

  #todo(sv): change to 'keystone' as soon as keystone as node-role was ready
  $keystones_address_map = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller']), 'keystone/api')
  class { 'openstack::ha::keystone':
    server_names => hiera_array('keystone_names', keys($keystones_address_map)),
    ipaddresses  => hiera_array('keystone_ipaddresses', values($keystones_address_map)),
    public_ssl   => $services_use_ssl,
  }

  class { 'openstack::ha::nova':
    public_ssl   => $services_use_ssl,
    server_names => hiera_array('nova_names', $controllers_server_names),
    ipaddresses  => hiera_array('nova_ipaddresses', $controllers_ipaddresses),
  }

  class { 'openstack::ha::heat':
    public_ssl   => $services_use_ssl,
    server_names => hiera_array('heat_names', $controllers_server_names),
    ipaddresses  => hiera_array('heat_ipaddresses', $controllers_ipaddresses),
  }

  #todo(sv): change to 'glance' as soon as glance as node-role was ready
  $glances_address_map = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller']), 'glance/api')
  class { 'openstack::ha::glance':
    server_names => hiera_array('glance_names', keys($glances_address_map)),
    ipaddresses  => hiera_array('glance_ipaddresses', values($glances_address_map)),
    public_ssl   => $services_use_ssl,
  }

  $cinder_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('cinder_nodes'), 'cinder/api')
  class { 'openstack::ha::cinder':
    server_names => hiera_array('cinder_names', keys($cinder_address_map)),
    ipaddresses  => hiera_array('cinder_ipaddresses', values($cinder_address_map)),
    public_ssl   => $services_use_ssl,
  }

  if $neutron {
    class { 'openstack::ha::neutron':
      public_ssl   => $services_use_ssl,
      server_names => hiera_array('neutron_names', $controllers_server_names),
      ipaddresses  => hiera_array('neutron_ipaddresses', $controllers_ipaddresses),
    }
  }

  if ($custom_mysql_setup_class in ['galera', 'percona', 'percona_packages']) {
    $database_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('database_nodes'), 'mgmt/database')
    class { 'openstack::ha::mysqld':
      is_primary_controller => $is_primary_controller,
      server_names          => hiera_array('mysqld_names', keys($database_address_map)),
      ipaddresses           => hiera_array('mysqld_ipaddresses', values($database_address_map)),
    }
  }

  if $swift_proxies {
    $swift_proxies_address_map = get_node_to_ipaddr_map_by_network_role($swift_proxies, 'swift/api')
    class { 'openstack::ha::swift':
      server_names => hiera_array('swift_server_names', keys($swift_proxies_address_map)),
      ipaddresses  => hiera_array('swift_ipaddresses', values($swift_proxies_address_map)),
      public_ssl => $services_use_ssl,
    }
  }

  if $rgw_servers {
    $rgw_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_rgw_nodes'), 'ceph/radosgw')
    class { 'openstack::ha::radosgw':
      public_ssl => $services_use_ssl,
      server_names => hiera_array('radosgw_server_names', keys($rgw_address_map)),
      ipaddresses  => hiera_array('radosgw_ipaddresses', values($rgw_address_map)),
    }
  }

  if $ceilometer {
    $ceilometer_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceilometer_nodes'), 'ceilometer/api')
    class { 'openstack::ha::ceilometer':
      public_ssl => $services_use_ssl,
      server_names  => hiera_array('ceilometer_names', keys($ceilometer_address_map)),
      ipaddresses   => hiera_array('ceilometer_ipaddresses', values($ceilometer_address_map)),
    }
  }

  if $sahara {
     class { 'openstack::ha::sahara':
      public_ssl => $services_use_ssl,
      server_names => hiera_array('sahara_names', $controllers_server_names),
      ipaddresses  => hiera_array('sahara_ipaddresses', $controllers_ipaddresses),
    }
  }

  if $murano {
    class { 'openstack::ha::murano':
      public_ssl => $services_use_ssl,
      server_names => hiera_array('murano_names', $controllers_server_names),
      ipaddresses  => hiera_array('murano_ipaddresses', $controllers_ipaddresses),
    }
  }
}
