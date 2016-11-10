class osnailyfacter::openstack_haproxy::openstack_haproxy_neutron {

  notice('MODULAR: openstack_haproxy/openstack_haproxy_neutron.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  # NOT enabled by default
  $use_neutron         = hiera('use_neutron', false)
  $public_ssl_hash     = hiera_hash('public_ssl', {})
  $ssl_hash            = hiera_hash('use_ssl', {})

  $public_ssl          = get_ssl_property($ssl_hash, $public_ssl_hash, 'neutron', 'public', 'usage', false)
  $public_ssl_path     = get_ssl_property($ssl_hash, $public_ssl_hash, 'neutron', 'public', 'path', [''])

  $internal_ssl        = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'usage', false)
  $internal_ssl_path   = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'path', [''])

  $external_lb         = hiera('external_lb', false)

  if ($use_neutron and !$external_lb) {
    override_resources {'override-resources':
      configuration => $override_configuration,
      options       => $override_configuration_options,
    }

    $neutron_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('neutron_nodes'), 'neutron/api')
    $server_names        = hiera_array('neutron_names', keys($neutron_address_map))
    $ipaddresses         = hiera_array('neutron_ipaddresses', values($neutron_address_map))
    $public_virtual_ip   = hiera('public_vip')
    $internal_virtual_ip = hiera('management_vip')

    # configure neutron ha proxy
    class { '::openstack::ha::neutron':
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
