# Configure apache and listen ports
class osnailyfacter::apache (
  $purge_configs = false,
  $listen_ports  = '80',
) {

  define apache_port {
    apache::listen { $name: }
    if $name =~ /:/ {
      apache::namevirtualhost { "${name}": }
    } else {
      apache::namevirtualhost { "*:${name}": }
    }
  }

  class { '::apache':
    mpm_module    => false,
    default_vhost => false,
    purge_configs => $purge_configs,
    servername    => $::hostname,
  }

  apache_port { $listen_ports: }
}
