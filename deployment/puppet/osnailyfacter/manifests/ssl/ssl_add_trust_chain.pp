class osnailyfacter::ssl::ssl_add_trust_chain {

  notice('MODULAR: ssl/ssl_add_trust_chain.pp')

  $public_ssl_hash    = hiera_hash('public_ssl')
  $ssl_hash           = hiera_hash('use_ssl', {})

  Exec {
    path => '/bin:/usr/bin:/sbin:/usr/sbin',
  }

  File {
    ensure => file,
  }

  define file_link {
    $service = $name
    if !empty(file("/etc/pki/tls/certs/public_${service}.pem",'/dev/null')) {
      file { "/usr/local/share/ca-certificates/${service}_public_haproxy.crt":
        source => "/etc/pki/tls/certs/public_${service}.pem",
      }
    }

    if !empty(file("/etc/pki/tls/certs/internal_${service}.pem",'/dev/null')) {
      file { "/usr/local/share/ca-certificates/${service}_internal_haproxy.crt":
        source => "/etc/pki/tls/certs/internal_${service}.pem",
      }
    }

    if !empty(file("/etc/pki/tls/certs/admin_${service}.pem",'/dev/null')) {
      file { "/usr/local/share/ca-certificates/${service}_admin_haproxy.crt":
        source => "/etc/pki/tls/certs/admin_${service}.pem",
      }
    }
  }

  if !empty($ssl_hash) {
    $services = [ 'horizon', 'keystone', 'nova', 'heat', 'glance', 'cinder',
      'neutron', 'swift', 'sahara', 'murano', 'ceilometer', 'radosgw']

    file_link { $services: }

  } elsif !empty($public_ssl_hash) {
    case $::osfamily {
      'RedHat': {
        file { '/etc/pki/ca-trust/source/anchors/public_haproxy.pem':
          source => '/etc/pki/tls/certs/public_haproxy.pem',
        }
      }

      'Debian': {
        file { '/usr/local/share/ca-certificates/public_haproxy.crt':
          source => '/etc/pki/tls/certs/public_haproxy.pem',
        }
      }

      default: {
        fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
      }
    }
  }

  case $::osfamily {
    'RedHat': {
      exec { 'enable_trust':
        command     => 'update-ca-trust force-enable',
        refreshonly => true,
        notify      => Exec['add_trust']
      }

      File <||> ~> Exec['enable_trust']
    }

    'Debian': {
      File <||> ~> Exec['add_trust']
    }

    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }

  exec { 'add_trust':
    command     => 'update-ca-certificates',
    refreshonly => true,
  }

}
