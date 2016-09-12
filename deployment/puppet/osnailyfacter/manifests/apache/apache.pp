class osnailyfacter::apache::apache {

  notice('MODULAR: apache/apache.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  # adjustments to defaults for LP#1485644 for scale
  sysctl::value { 'net.core.somaxconn':           value => '4096' }
  sysctl::value { 'net.ipv4.tcp_max_syn_backlog': value => '8192' }

  # Listen directives with host required for ip_based vhosts
  class { '::osnailyfacter::apache':
    purge_configs => false,
    listen_ports  => hiera_array('apache_ports', ['0.0.0.0:80']),
  }

  include ::osnailyfacter::apache_mpm

}
