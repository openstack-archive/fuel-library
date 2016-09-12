class osnailyfacter::memcached::memcached {

  notice('MODULAR: memcached/memcached.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  prepare_network_config(hiera_hash('network_scheme', {}))

  class { '::memcached':
    listen_ip  => get_network_role_property('mgmt/memcache', 'ipaddr'),
    max_memory => '50%',
    item_size  => '10m',
  }

}
