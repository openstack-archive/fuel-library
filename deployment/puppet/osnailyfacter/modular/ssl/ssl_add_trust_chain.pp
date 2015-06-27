notice('MODULAR: ssl_add_trust_chain.pp')

$public_ssl_hash = hiera('public_ssl')
$internal_ssl_hash = hiera('internal_ssl')
$admin_ssl_hash = hiera('admin_ssl')

case $::osfamily {
  /(?i)redhat/: {
    if $public_ssl_hash['horizon'] or $public_ssl_hash['services'] {
      file { '/etc/pki/ca-trust/source/anchors/public_haproxy.pem':
        ensure => 'link',
        target => '/etc/pki/tls/certs/public_haproxy.pem',
        notify => Exec['enable_trust'],
      }
    }

    if $internal_ssl_hash['enable'] {
      file { '/etc/pki/ca-trust/source/anchors/internal_haproxy.pem':
        ensure => 'link',
        target => '/etc/pki/tls/certs/internal_haproxy.pem',
        notify => Exec['enable_trust'],
      }
    }

    if $admin_ssl_hash['enable'] {
      file { '/etc/pki/ca-trust/source/anchors/admin_haproxy.pem':
        ensure => 'link',
        target => '/etc/pki/tls/certs/admin_haproxy.pem',
        notify => Exec['enable_trust'],
      }
    }

    exec { 'enable_trust':
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      command => 'update-ca-trust enable',
    }->

    exec { 'add_trust':
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      command => 'update-ca-trust extract',
    }
  }
  /(?i)debian/: {
    if $public_ssl_hash['horizon'] or $public_ssl_hash['services'] {
      file { '/usr/local/share/ca-certificates/public_haproxy.crt':
        ensure => 'link',
        target => '/etc/pki/tls/certs/public_haproxy.pem',
        notify => Exec['add_trust'],
      }
    }

    if $internal_ssl_hash['enable'] {
      file { '/usr/local/share/ca-certificates/internal_haproxy.crt':
        ensure => 'link',
        target => '/etc/pki/tls/certs/internal_haproxy.pem',
        notify => Exec['add_trust'],
      }
    }

    if $admin_ssl_hash['enable'] {
      file { '/usr/local/share/ca-certificates/admin_haproxy.crt':
        ensure => 'link',
        target => '/etc/pki/tls/certs/admin_haproxy.pem',
        notify => Exec['add_trust'],
      }
    }

    exec { 'add_trust':
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      command => 'update-ca-certificates',
    }
  }
  default: {
    fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
  }
}

if $public_ssl_hash['horizon'] or $public_ssl_hash['services'] {
  host { $public_ssl_hash['hostname']:
    ensure => present,
    ip     => hiera('public_vip'),
  }
}

if $internal_ssl_hash['enable'] or $admin_ssl_hash['enable'] {
  host { $internal_ssl_hash['hostname']:
    ensure => present,
    ip     => hiera('management_vip'),
  }
}
