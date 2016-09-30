class osnailyfacter::openstack_haproxy::openstack_haproxy_sahara {

  notice('MODULAR: openstack_haproxy/openstack_haproxy_sahara.pp')

  $sahara_hash       = hiera_hash('sahara', {})
  # NOT enabled by default
  $use_sahara        = pick($sahara_hash['enabled'], false)
  $public_ssl_hash   = hiera_hash('public_ssl', {})
  $ssl_hash          = hiera_hash('use_ssl', {})

  $public_ssl        = get_ssl_property($ssl_hash, $public_ssl_hash, 'sahara', 'public', 'usage', false)
  $public_ssl_path   = get_ssl_property($ssl_hash, $public_ssl_hash, 'sahara', 'public', 'path', [''])

  $internal_ssl      = get_ssl_property($ssl_hash, {}, 'sahara', 'internal', 'usage', false)
  $internal_ssl_path = get_ssl_property($ssl_hash, {}, 'sahara', 'internal', 'path', [''])

  $external_lb       = hiera('external_lb', false)

  if ($use_sahara and !$external_lb) {
    $sahara_address_map  = get_node_to_ipaddr_map_by_network_role(hiera('sahara_nodes'), 'sahara/api')
    $server_names        = hiera_array('sahara_names', sorted_hosts($sahara_address_map, 'host'))
    $ipaddresses         = hiera_array('sahara_ipaddresses', sorted_hosts($sahara_address_map, 'ip'))
    $public_virtual_ip   = hiera('public_vip')
    $internal_virtual_ip = hiera('management_vip')

    # configure sahara ha proxy
    class { '::openstack::ha::sahara':
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
