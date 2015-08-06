notice('MODULAR: api-proxy.pp')

# Apache and listen ports
class { 'osnailyfacter::apache':
  listen_ports => hiera_array('apache_ports', ['80', '8888']),
}

# API proxy vhost
class {'osnailyfacter::apache_api_proxy':
  master_ip => hiera('master_ip'),
}
