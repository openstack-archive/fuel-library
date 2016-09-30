class osnailyfacter::openstack_haproxy::openstack_haproxy_ironic {

  notice('MODULAR: openstack_haproxy/openstack_haproxy_ironic.pp')

  $network_metadata     = hiera_hash('network_metadata')
  $public_ssl_hash      = hiera_hash('public_ssl', {})
  $ssl_hash             = hiera_hash('use_ssl', {})

  $public_ssl           = get_ssl_property($ssl_hash, $public_ssl_hash, 'ironic', 'public', 'usage', false)
  $public_ssl_path      = get_ssl_property($ssl_hash, $public_ssl_hash, 'ironic', 'public', 'path', [''])

  $ironic_address_map   = get_node_to_ipaddr_map_by_network_role(hiera('ironic_api_nodes'), 'ironic/api')

  $server_names         = hiera_array('ironic_server_names', sorted_hosts($ironic_address_map, 'host'))
  $ipaddresses          = hiera_array('ironic_ipaddresses', sorted_hosts($ironic_address_map, 'ip'))
  $public_virtual_ip    = hiera('public_vip')
  $internal_virtual_ip  = hiera('management_vip')

  $baremetal_virtual_ip = $network_metadata['vips']['baremetal']['ipaddr']
  $external_lb          = hiera('external_lb', false)

  if !$external_lb {
    # configure ironic ha proxy
    class { '::openstack::ha::ironic':
      internal_virtual_ip  => $internal_virtual_ip,
      ipaddresses          => $ipaddresses,
      public_virtual_ip    => $public_virtual_ip,
      server_names         => $server_names,
      public_ssl           => $public_ssl,
      public_ssl_path      => $public_ssl_path,
      baremetal_virtual_ip => $baremetal_virtual_ip,
    }
  }

}
