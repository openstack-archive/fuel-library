notice('MODULAR: apache.pp')

# adjustments to defaults for LP#1485644 for scale
sysctl::value { 'net.core.somaxconn':           value => '4096' }
sysctl::value { 'net.ipv4.tcp_max_syn_backlog': value => '8192' }

class { 'osnailyfacter::apache':
  purge_configs => true,
  listen_ports  => hiera_array('apache_ports', ['80', '8888']),
}

include ::osnailyfacter::apache_mpm

