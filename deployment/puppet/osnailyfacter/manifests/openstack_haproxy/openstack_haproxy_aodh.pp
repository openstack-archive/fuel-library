class osnailyfacter::openstack_haproxy::openstack_haproxy_aodh {

  notice('MODULAR: openstack_haproxy/openstack_haproxy_aodh.pp')

  $ceilometer_hash         = hiera_hash('ceilometer',{})

  # enabled only in case of Ceilometer enabled
  $use_aodh                = pick($ceilometer_hash['enabled'], false)
  $public_ssl_hash         = hiera_hash('public_ssl', {})
  $ssl_hash                = hiera_hash('use_ssl', {})

  $public_ssl              = get_ssl_property($ssl_hash, $public_ssl_hash, 'aodh', 'public', 'usage', false)
  $public_ssl_path         = get_ssl_property($ssl_hash, $public_ssl_hash, 'aodh', 'public', 'path', [''])

  $internal_ssl            = get_ssl_property($ssl_hash, {}, 'aodh', 'internal', 'usage', false)
  $internal_ssl_path       = get_ssl_property($ssl_hash, {}, 'aodh', 'internal', 'path', [''])

  $external_lb             = hiera('external_lb', false)

  if ($use_aodh and !$external_lb) {
    $aodh_address_map       = get_node_to_ipaddr_map_by_network_role(hiera_hash('aodh_nodes'), 'aodh/api')
    $server_names           = hiera_array('aodh_names', sorted_hosts($aodh_address_map, 'host'))
    $ipaddresses            = hiera_array('aodh_ipaddresses', sorted_hosts($aodh_address_map, 'ip'))
    $public_virtual_ip      = hiera('public_vip')
    $internal_virtual_ip    = hiera('management_vip')

    # configure aodh ha proxy
    class { '::openstack::ha::aodh':
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
