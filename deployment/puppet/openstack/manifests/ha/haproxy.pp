# Configuration of HAProxy for OpenStack
class openstack::ha::haproxy (
  $controllers,
  $public_virtual_ip,
  $internal_virtual_ip,
  $horizon_use_ssl          = false,
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

  $disable_hash = hiera_hash('disable_ha_proxy', {})

  $controllers_server_names = filter_hash($controllers, 'name')
  $controllers_ipaddresses  = filter_hash($controllers, 'internal_address')

  Openstack::Ha::Haproxy_service {
    server_names        => $controllers_server_names,
    ipaddresses         => $controllers_ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    internal_virtual_ip => $internal_virtual_ip,
  }

  if !$disable_hash[horizon] {
    class { 'openstack::ha::horizon':
      use_ssl      => $horizon_use_ssl,
      server_names => hiera_array('horizon_names', $controllers_server_names),
      ipaddresses  => hiera_array('horizon_ipaddresses', $controllers_ipaddresses),
    }
  }


  if !$disable_hash[keystone] {
    class { 'openstack::ha::keystone':
      server_names => hiera_array('keystone_names', $controllers_server_names),
      ipaddresses  => hiera_array('keystone_ipaddresses', $controllers_ipaddresses),
    }
  }

  if !$disable_hash[nova] {
    class { 'openstack::ha::nova':
      server_names => hiera_array('nova_names', $controllers_server_names),
      ipaddresses  => hiera_array('nova_ipaddresses', $controllers_ipaddresses),
    }
  }

  if !$disable_hash[heat] {
    class { 'openstack::ha::heat':
      server_names => hiera_array('heat_names', $controllers_server_names),
      ipaddresses  => hiera_array('heat_ipaddresses', $controllers_ipaddresses),
    }
  }

  if !$disable_hash[glance] {
    class { 'openstack::ha::glance':
      server_names => hiera_array('glance_names', $controllers_server_names),
      ipaddresses  => hiera_array('glance_ipaddresses', $controllers_ipaddresses),
    }
  }

  if !$disable_hash[cinder] {
    class { 'openstack::ha::cinder':
      server_names => hiera_array('cinder_names', $controllers_server_names),
      ipaddresses  => hiera_array('cinder_ipaddresses', $controllers_ipaddresses),
    }
  }

  if $neutron and !$disable_hash[neutron] {
    class { 'openstack::ha::neutron':
      server_names => hiera_array('neutron_names', $controllers_server_names),
      ipaddresses  => hiera_array('neutron_ipaddresses', $controllers_ipaddresses),
    }
  }

  if ($custom_mysql_setup_class in ['galera', 'percona', 'percona_packages']) and !$disable_hash[mysqld] {
    class { 'openstack::ha::mysqld':
      is_primary_controller => $is_primary_controller,
      server_names          => hiera_array('mysqld_names', $controllers_server_names),
      ipaddresses           => hiera_array('mysqld_ipaddresses', $controllers_ipaddresses),
    }
  }

  if $swift_proxies and !$disable_hash[swift_proxies] {
    class { 'openstack::ha::swift':
      server_names => hiera_array('swift_server_names', filter_hash($swift_proxies, 'name')),
      ipaddresses  => hiera_array('swift_ipaddresses', filter_hash($swift_proxies, 'storage_address')),
    }
  }

  if $rgw_servers and !$disable_hash[rgw_servers] {
    class { 'openstack::ha::radosgw':
      server_names => hiera_array('radosgw_server_names', filter_hash($rgw_servers, 'name')),
      ipaddresses  => hiera_array('radosgw_ipaddresses', filter_hash($rgw_servers, 'internal_address')),
    }
  }

  if $ceilometer and !$disable_hash[ceilometer] {
    class { 'openstack::ha::ceilometer':
      server_names => hiera_array('ceilometer_names', $controllers_server_names),
      ipaddresses  => hiera_array('ceilometer_ipaddresses', $controllers_ipaddresses),
    }
  }

  if $sahara and !$disable_hash[sahara] {
     class { 'openstack::ha::sahara':
      server_names => hiera_array('sahara_names', $controllers_server_names),
      ipaddresses  => hiera_array('sahara_ipaddresses', $controllers_ipaddresses),
    }
  }

  if $murano and !$disable_hash[murano] {
    class { 'openstack::ha::murano':
      server_names => hiera_array('murano_names', $controllers_server_names),
      ipaddresses  => hiera_array('murano_ipaddresses', $controllers_ipaddresses),
    }
  }
}
