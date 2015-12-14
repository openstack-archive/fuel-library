notice('MODULAR: apache.pp')

# adjustments to defaults for LP#1485644 for scale
sysctl::value { 'net.core.somaxconn':           value => '4096' }
sysctl::value { 'net.ipv4.tcp_max_syn_backlog': value => '8192' }

# define log formats
$log_formats = {
  'forwarded' => '%{X-Forwarded-For}i %l %u %t \"%r\" %s %b \"%{Referer}i\" \"%{User-agent}i\"'
}

# Listen directives with host required for ip_based vhosts
class { 'osnailyfacter::apache':
  purge_configs => true,
  listen_ports  => hiera_array('apache_ports', ['0.0.0.0:80']),
  log_formats   => $log_formats,
}

include ::osnailyfacter::apache_mpm

