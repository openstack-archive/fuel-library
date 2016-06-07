class osnailyfacter::apache::apache {

  notice('MODULAR: apache/apache.pp')

  # adjustments to defaults for LP#1485644 for scale
  sysctl::value { 'net.core.somaxconn':           value => '4096' }
  sysctl::value { 'net.ipv4.tcp_max_syn_backlog': value => '8192' }

  # Listen directives with host required for ip_based vhosts
  class { '::osnailyfacter::apache':
    purge_configs => false,
    listen_ports  => hiera_array('apache_ports', ['0.0.0.0:80']),
    log_formats   => {
      'combined'  => '%h %l %u %{%d/%b/%Y:%T}t.%{msec_frac}t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"',
      'common'    => '%h %l %u %{%d/%b/%Y:%T}t.%{msec_frac}t \"%r\" %>s %b',
      'forwarded' => '%{X-Forwarded-For}i %l %u %{%d/%b/%Y:%T}t.%{msec_frac}t \"%r\" %s %b \"%{Referer}i\" \"%{User-agent}i\"'
    }
  }

  include ::osnailyfacter::apache_mpm

}
