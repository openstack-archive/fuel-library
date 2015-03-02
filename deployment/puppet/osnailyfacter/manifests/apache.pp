# Configure apache and listen ports
class osnailyfacter::apache (
  $listen_ports = '80',
) {

  define apache_port {
    apache::listen { $name: }
    apache::namevirtualhost { "*:${name}": }
  }

  class { '::apache':
    mpm_module    => false,
    default_vhost => false,
    purge_configs => false,
    servername    => $::hostname,
  }

  apache_port { $listen_ports: }
}
