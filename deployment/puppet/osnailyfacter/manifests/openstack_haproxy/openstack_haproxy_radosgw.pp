class osnailyfacter::openstack_haproxy::openstack_haproxy_radosgw {

  notice('MODULAR: openstack_haproxy/openstack_haproxy_radosgw.pp')

  $storage_hash     = hiera_hash('storage', {})
  $public_ssl_hash  = hiera_hash('public_ssl', {})
  $ssl_hash         = hiera_hash('use_ssl', {})

  $public_ssl       = get_ssl_property($ssl_hash, $public_ssl_hash, 'radosgw', 'public', 'usage', false)
  $public_ssl_path  = get_ssl_property($ssl_hash, $public_ssl_hash, 'radosgw', 'public', 'path', [''])

  $external_lb      = hiera('external_lb', false)

  if !$external_lb {
    if !$storage_hash['objects_ceph'] {
      $use_swift = true
    } else {
      $use_swift = false
    }
    if !($use_swift) and ($storage_hash['objects_ceph']) {
      $use_radosgw = true
    } else {
      $use_radosgw = false
    }

    if $use_radosgw {
      $rgw_address_map     = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_rgw_nodes'), 'ceph/radosgw')
      $server_names        = hiera_array('radosgw_server_names', sorted_hosts($rgw_address_map, 'host'))
      $ipaddresses         = hiera_array('radosgw_ipaddresses', sorted_hosts($rgw_address_map, 'ip'))
      $public_virtual_ip   = hiera('public_vip')
      $internal_virtual_ip = hiera('management_vip')

      $ironic_hash         = hiera_hash('ironic', {})

      if $ironic_hash['enabled'] {
        $network_metadata     = hiera_hash('network_metadata')
        $baremetal_virtual_ip = $network_metadata['vips']['baremetal']['ipaddr']
      }

      # configure radosgw ha proxy
      class { '::openstack::ha::radosgw':
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

}
