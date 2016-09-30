class osnailyfacter::openstack_haproxy::openstack_haproxy_keystone {

  notice('MODULAR: openstack_haproxy/openstack_haproxy_keystone.pp')

  $keystone_hash     = hiera_hash('keystone', {})
  # enabled by default
  $use_keystone      = pick($keystone_hash['enabled'], true)
  $public_ssl_hash   = hiera_hash('public_ssl', {})
  $ssl_hash          = hiera_hash('use_ssl', {})

  $public_ssl        = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'usage', false)
  $public_ssl_path   = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'path', [''])

  $internal_ssl      = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'usage', false)
  $internal_ssl_path = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'path', [''])

  $admin_ssl         = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'usage', false)
  $admin_ssl_path    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'path', [''])

  $external_lb       = hiera('external_lb', false)

  if ($use_keystone and !$external_lb) {
    $keystone_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('keystone_nodes'), 'keystone/api')
    $server_names         = hiera_array('keystone_names', sorted_hosts($keystone_address_map, 'host'))
    $ipaddresses          = hiera_array('keystone_ipaddresses', sorted_hosts($keystone_address_map, 'ip'))
    $public_virtual_ip    = pick(hiera('public_service_endpoint', undef), hiera('public_vip'))
    $internal_virtual_ip  = pick(hiera('service_endpoint', undef), hiera('management_vip'))
    $keystone_federation  = pick($keystone_hash['federation'], false)

    # configure keystone ha proxy
    class { '::openstack::ha::keystone':
      internal_virtual_ip => $internal_virtual_ip,
      ipaddresses         => $ipaddresses,
      public_virtual_ip   => $public_virtual_ip,
      server_names        => $server_names,
      public_ssl          => $public_ssl,
      public_ssl_path     => $public_ssl_path,
      internal_ssl        => $internal_ssl,
      internal_ssl_path   => $internal_ssl_path,
      admin_ssl           => $admin_ssl,
      admin_ssl_path      => $admin_ssl_path,
      federation_enabled  => $keystone_federation,
    }
  }

}
