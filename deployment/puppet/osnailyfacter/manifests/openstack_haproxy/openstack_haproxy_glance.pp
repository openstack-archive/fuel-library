class osnailyfacter::openstack_haproxy::openstack_haproxy_glance {

  notice('MODULAR: openstack_haproxy/openstack_haproxy_glance.pp')

  $glance_hash       = hiera_hash('glance', {})
  # enabled by default
  $use_glance        = pick($glance_hash['enabled'], true)
  $public_ssl_hash   = hiera_hash('public_ssl', {})
  $ssl_hash          = hiera_hash('use_ssl', {})

  $public_ssl        = get_ssl_property($ssl_hash, $public_ssl_hash, 'glance', 'public', 'usage', false)
  $public_ssl_path   = get_ssl_property($ssl_hash, $public_ssl_hash, 'glance', 'public', 'path', [''])

  $internal_ssl      = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'usage', false)
  $internal_ssl_path = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'path', [''])

  $external_lb       = hiera('external_lb', false)

  if ($use_glance and !$external_lb) {
    $glance_address_map  = get_node_to_ipaddr_map_by_network_role(hiera_hash('glance_nodes'), 'glance/api')
    $server_names        = hiera_array('glance_names', sorted_hosts($glance_address_map, 'host'))
    $ipaddresses         = hiera_array('glance_ipaddresses', sorted_hosts($glance_address_map, 'ip'))
    $public_virtual_ip   = hiera('public_vip')
    $internal_virtual_ip = hiera('management_vip')

    # configure glance ha proxy
    class { '::openstack::ha::glance':
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
