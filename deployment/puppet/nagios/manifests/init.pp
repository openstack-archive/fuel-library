class nagios {
  include nagios::common

  validate_hash(hiera('contacts'))
  validate_hash(hiera('contactgroups'))
  validate_array(hiera('hostgroups'))
  validate_array(hiera('servicegroups'))
  validate_hash(hiera('htpasswd'))
  validate_array(hiera('whitelist'))

  nagios::whitelist { '/etc/nagios/nrpe.cfg':
    whitelist => hiera('whitelist'),
  }

  file { '/etc/nagios/nrpe.d':
    force   => true,
    purge   => true,
    recurse => true,
    owner   => root,
    group   => root,
    mode    => '0644',
    notify  => Service['nagios-nrpe-server'],
    source  => 'puppet:///modules/nagios/common/etc/nagios/nrpe.d',
    require => Package['nagios-nrpe-server'],
  }

  file { '/usr/local/lib/nagios':
    force   => true,
    purge   => true,
    recurse => true,
    owner   => root,
    group   => staff,
    mode    => '0755',
    source  => 'puppet:///modules/nagios/common/usr/local/lib/nagios',
  }

  package { [
    'binutils',
    'libnagios-plugin-perl',
    'nagios-nrpe-server',
    'nagios-plugins-basic',
    'nagios-plugins-standard' ]:
    ensure => present,
  }

  service { 'nagios-nrpe-server':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => false,
    pattern    => 'nrpe',
    require    => [
      File['nrpe.cfg'],
      Package['nagios-nrpe-server']
    ],
  }
}
