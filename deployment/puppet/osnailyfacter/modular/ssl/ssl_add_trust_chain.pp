notice('MODULAR: ssl_add_trust_chain.pp')

if $::osfamily == "RedHat" {
  file { '/etc/pki/ca-trust/source/anchors/public_haproxy.pem':
    ensure => 'link',
    target => '/etc/pki/tls/certs/public_haproxy.pem',
  }->

  exec { 'enable_trust':
    path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    command => 'update-ca-trust enable',
  }->

  exec { 'add_trust':
    path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    command => 'update-ca-trust extract',
  }
} else {
  file { '/usr/local/share/ca-certificates/public_haproxy.crt':
    ensure => 'link',
    target => '/etc/pki/tls/certs/public_haproxy.pem',
  }->

  exec { 'add_trust':
    path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    command => 'update-ca-certificates',
  }
}
