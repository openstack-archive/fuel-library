class osnailyfacter::openstack_haproxy::openstack_haproxy_heat {

  notice('MODULAR: openstack_haproxy/openstack_haproxy_heat.pp')

  $heat_hash         = hiera_hash('heat', {})
  # enabled by default
  $use_heat          = pick($heat_hash['enabled'], true)
  $public_ssl_hash   = hiera_hash('public_ssl', {})
  $ssl_hash          = hiera_hash('use_ssl', {})

  $public_ssl        = get_ssl_property($ssl_hash, $public_ssl_hash, 'heat', 'public', 'usage', false)
  $public_ssl_path   = get_ssl_property($ssl_hash, $public_ssl_hash, 'heat', 'public', 'path', [''])

  $internal_ssl      = get_ssl_property($ssl_hash, {}, 'heat', 'internal', 'usage', false)
  $internal_ssl_path = get_ssl_property($ssl_hash, {}, 'heat', 'internal', 'path', [''])

  $external_lb       = hiera('external_lb', false)

  if ($use_heat and !$external_lb) {
    $heat_address_map    = get_node_to_ipaddr_map_by_network_role(hiera_hash('heat_nodes'), 'heat/api')
    $server_names        = hiera_array('heat_names', sorted_hosts($heat_address_map, 'host'))
    $ipaddresses         = hiera_array('heat_ipaddresses', sorted_hosts($heat_address_map, 'ip'))
    $public_virtual_ip   = hiera('public_vip')
    $internal_virtual_ip = hiera('management_vip')

    # configure heat ha proxy
    class { '::openstack::ha::heat':
      internal_virtual_ip => $internal_virtual_ip,
      ipaddresses         => $ipaddresses,
      public_virtual_ip   => $public_virtual_ip,
      server_names        => $server_names,
      public_ssl          => $public_ssl,
      public_ssl_path     => $public_ssl_path,
      internal_ssl        => $internal_ssl,
      internal_ssl_path   => $internal_ssl_path,
    }
  }

}
