notice('MODULAR: ssl_add_trust_chain.pp')

$public_ssl_hash = hiera('public_ssl')
$ip = hiera('public_vip')

case $::osfamily {
  /(?i)redhat/: {
    file { '/etc/pki/ca-trust/source/anchors/public_haproxy.pem':
      ensure => 'link',
      target => '/etc/pki/tls/certs/public_haproxy.pem',
    }->

    exec { 'enable_trust':
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      command => 'update-ca-trust force-enable',
    }->

    exec { 'add_trust':
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      command => 'update-ca-trust extract',
    }
  }
  /(?i)debian/: {
    file { '/usr/local/share/ca-certificates/public_haproxy.crt':
      ensure => 'link',
      target => '/etc/pki/tls/certs/public_haproxy.pem',
    }->

    exec { 'add_trust':
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      command => 'update-ca-certificates',
    }
  }
  default: {
    fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
  }
}

host { $public_ssl_hash['hostname']:
  ensure => present,
  ip     => $ip,
}
