notice('MODULAR: apache.pp')

class { 'osnailyfacter::apache':
  purge_configs => true,
  listen_ports  => hiera_array('apache_ports', ['80', '8888']),
}

include ::osnailyfacter::apache_mpm

