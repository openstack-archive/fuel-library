notice('MODULAR: memcached.pp')
class { 'memcached':
  listen_ip => hiera('internal_address'),
}
