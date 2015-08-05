notice('MODULAR: api-proxy.pp')

$max_header_size = hiera('max_header_size', '81900')

# Apache and listen ports
class { 'osnailyfacter::apache':
  listen_ports => hiera_array('apache_ports', ['80', '8888']),
}

# API proxy vhost
class {'osnailyfacter::apache_api_proxy':
  master_ip       => hiera('master_ip'),
  max_header_size => $max_header_size,
}

include ::tweaks::apache_wrappers
