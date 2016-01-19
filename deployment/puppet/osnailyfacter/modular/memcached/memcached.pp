notice('MODULAR: memcached.pp')

prepare_network_config(hiera_hash('network_scheme', {}))

class { 'memcached':
  listen_ip  => get_network_role_property('mgmt/memcache', 'ipaddr'),
  max_memory => '50%',
}
