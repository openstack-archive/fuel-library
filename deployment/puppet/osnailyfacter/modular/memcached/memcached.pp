notice('MODULAR: memcached.pp')
class { 'memcached':
  listen_ip  => hiera('internal_address'),
  max_memory => '50%',
}
