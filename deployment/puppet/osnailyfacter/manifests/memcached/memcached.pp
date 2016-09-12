class osnailyfacter::memcached::memcached {

  notice('MODULAR: memcached/memcached.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  prepare_network_config(hiera_hash('network_scheme', {}))

  class { '::memcached':
    listen_ip  => get_network_role_property('mgmt/memcache', 'ipaddr'),
    max_memory => '50%',
    item_size  => '10m',
  }

}
