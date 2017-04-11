class osnailyfacter::openstack_haproxy::openstack_haproxy_swift {

  notice('MODULAR: openstack_haproxy/openstack_haproxy_swift.pp')

  $storage_hash      = hiera_hash('storage', {})
  $swift_proxies     = hiera_hash('swift_proxies', undef)
  $public_ssl_hash   = hiera_hash('public_ssl', {})
  $ssl_hash          = hiera_hash('use_ssl', {})

  $public_ssl        = get_ssl_property($ssl_hash, $public_ssl_hash, 'swift', 'public', 'usage', false)
  $public_ssl_path   = get_ssl_property($ssl_hash, $public_ssl_hash, 'swift', 'public', 'path', [''])

  $internal_ssl      = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'usage', false)
  $internal_ssl_path = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'path', [''])

  $external_lb       = hiera('external_lb', false)

  if !$storage_hash['objects_ceph'] {
    $use_swift = true
  } else {
    $use_swift = false
  }

  if ($use_swift and !$external_lb) {
    $swift_proxy_address_map = get_node_to_ipaddr_map_by_network_role($swift_proxies, 'swift/api')
    $server_names            = hiera_array('swift_server_names', sorted_hosts($swift_proxy_address_map, 'host'))
    $ipaddresses             = hiera_array('swift_ipaddresses', sorted_hosts($swift_proxy_address_map, 'ip'))
    $public_virtual_ip       = hiera('public_vip')
    $internal_virtual_ip     = hiera('management_vip')

    $ironic_hash             = hiera_hash('ironic', {})

    if $ironic_hash['enabled'] {
      $network_metadata     = hiera_hash('network_metadata')
      $baremetal_virtual_ip = $network_metadata['vips']['baremetal']['ipaddr']
    }

    prepare_network_config(hiera_hash('network_scheme', {}))

    # Check swift proxy and internal VIP are from the same IP network. If no then it's possible
    # to get network failure, so proxy couldn't access Keystone via VIP. In such cases swift
    # health check returns OK, but all requests forwarded from HAproxy fail, see LP#1459772
    # In order to detect such bad swift backends we enable a service which checks Keystone
    # availability from swift node. HAProxy monitors that service to get proper backend status.
    # NOTE: this is the same logic in the swift proxy task so if this is updated
    # then it must be updated overthere as well. See LP#1548275
    $swift_api_network     = get_network_role_property('swift/api', 'network')
    $bind_to_one           = has_ip_in_network($internal_virtual_ip, $swift_api_network)

    # configure swift ha proxy
    class { '::openstack::ha::swift':
      internal_virtual_ip  => $internal_virtual_ip,
      ipaddresses          => $ipaddresses,
      public_virtual_ip    => $public_virtual_ip,
      server_names         => $server_names,
      public_ssl           => $public_ssl,
      public_ssl_path      => $public_ssl_path,
      internal_ssl         => $internal_ssl,
      internal_ssl_path    => $internal_ssl_path,
      baremetal_virtual_ip => $baremetal_virtual_ip,
      bind_to_one          => $bind_to_one,
    }
  }

}
