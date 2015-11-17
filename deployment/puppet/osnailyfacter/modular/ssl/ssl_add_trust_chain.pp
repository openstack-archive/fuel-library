notice('MODULAR: ssl_add_trust_chain.pp')

$public_ssl_hash    = hiera('public_ssl')
$ssl_hash           = hiera_hash('use_ssl', {})

define file_link {
  $service = $name
  if !empty(file("/etc/pki/tls/certs/public_${service}.pem",'/dev/null')) {
    file { "/usr/local/share/ca-certificates/${service}_public_haproxy.crt":
      ensure => link,
      target => "/etc/pki/tls/certs/public_${service}.pem",
    }
  }
}

if !empty($ssl_hash) {
  $services = [ 'horizon', 'keystone', 'nova', 'heat', 'glance', 'cinder', 'neutron', 'swift', 'sahara', 'murano', 'ceilometer', 'radosgw']

  file_link { $services: }

} elsif !empty($public_ssl_hash) {
  case $::osfamily {
    /(?i)redhat/: {
      file { '/etc/pki/ca-trust/source/anchors/public_haproxy.pem':
        ensure => 'link',
        target => '/etc/pki/tls/certs/public_haproxy.pem',
      }
    }

    /(?i)debian/: {
      file { '/usr/local/share/ca-certificates/public_haproxy.crt':
        ensure => 'link',
        target => '/etc/pki/tls/certs/public_haproxy.pem',
      }
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }
}

case $::osfamily {
  /(?i)redhat/: {
    exec { 'enable_trust':
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      command => 'update-ca-trust force-enable',
    }->
    exec { 'add_trust':
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      command => 'update-ca-certificates',
    }
  }

  /(?i)debian/: {
    exec { 'add_trust':
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      command => 'update-ca-certificates',
    }
  }
  default: {
    fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
  }
}


File <| |> -> Exec['add_trust']
