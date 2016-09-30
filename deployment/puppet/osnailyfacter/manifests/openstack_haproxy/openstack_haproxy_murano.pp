class osnailyfacter::openstack_haproxy::openstack_haproxy_murano {

  notice('MODULAR: openstack_haproxy/openstack_haproxy_murano.pp')

  $murano_hash        = hiera_hash('murano', {})
  $murano_cfapi_hash  = hiera_hash('murano-cfapi', {})
  # NOT enabled by default
  $use_murano         = pick($murano_hash['enabled'], false)
  $use_murano_cfapi   = pick($murano_cfapi_hash['enabled'], false)
  $public_ssl_hash    = hiera_hash('public_ssl', {})
  $ssl_hash           = hiera_hash('use_ssl', {})

  $public_ssl         = get_ssl_property($ssl_hash, $public_ssl_hash, 'murano', 'public', 'usage', false)
  $public_ssl_path    = get_ssl_property($ssl_hash, $public_ssl_hash, 'murano', 'public', 'path', [''])

  $internal_ssl       = get_ssl_property($ssl_hash, {}, 'murano', 'internal', 'usage', false)
  $internal_ssl_path  = get_ssl_property($ssl_hash, {}, 'murano', 'internal', 'path', [''])

  $external_lb        = hiera('external_lb', false)

  if ($use_murano and !$external_lb) {
    $murano_address_map  = get_node_to_ipaddr_map_by_network_role(hiera_hash('murano_nodes'), 'murano/api')
    $server_names        = hiera_array('murano_names', sorted_hosts($murano_address_map, 'host'))
    $ipaddresses         = hiera_array('murano_ipaddresses', sorted_hosts($murano_address_map, 'ip'))
    $public_virtual_ip   = hiera('public_vip')
    $internal_virtual_ip = hiera('management_vip')

    # configure murano ha proxy
    class { '::openstack::ha::murano':
      internal_virtual_ip => $internal_virtual_ip,
      ipaddresses         => $ipaddresses,
      public_virtual_ip   => $public_virtual_ip,
      server_names        => $server_names,
      public_ssl          => $public_ssl,
      public_ssl_path     => $public_ssl_path,
      internal_ssl        => $internal_ssl,
      internal_ssl_path   => $internal_ssl_path,
      murano_cfapi        => $use_murano_cfapi,
    }
  }

}
