class osnailyfacter::api_proxy::api_proxy {

  notice('MODULAR: api_proxy/api_proxy.pp')

  $max_header_size        = hiera('max_header_size', '81900')
  $apache_api_proxy_ports = hiera('apache_api_proxy_ports',
   ['443', '563', '5000', '6385', '8000', '8003', '8004', '8042', '8080', '8082', '8386', '8773', '8774', '8776', '8777', '9292', '9494', '9696'])

  # Listen directives with host required for ip_based vhosts
  class { '::osnailyfacter::apache':
    listen_ports => hiera_array('apache_ports', ['0.0.0.0:80', '0.0.0.0:8888']),
  }

  # API proxy vhost
  class { '::osnailyfacter::apache_api_proxy':
    master_ip       => hiera('master_ip'),
    max_header_size => $max_header_size,
    ports           => $apache_api_proxy_ports,
  }

  include ::tweaks::apache_wrappers

}
