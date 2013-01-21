class nagios::master inherits nagios {
  include nagios::command
  include nagios::contact
  include nagios::host
  include nagios::service

  exec { 'external-commands':
    command => 'dpkg-statoverride --update --add nagios nagios 751 /var/lib/nagios3 && dpkg-statoverride --update --add nagios www-data 2710 /var/lib/nagios3/rw',
    unless  => 'dpkg-statoverride --list nagios nagios 751 /var/lib/nagios3 && dpkg-statoverride --list nagios www-data 2710 /var/lib/nagios3/rw',
    notify  => Service['nagios3'],
  }

  # Bug: 3299
  exec { 'fix-permissions':
    command     => 'chmod -R go+r /etc/nagios3/conf.d',
    refreshonly => true,
    notify      => Service['nagios3'],
  }

  if $::lsbdistcodename == 'squeeze' {
    file { '/etc/default/npcd':
      owner   => root,
      group   => root,
      mode    => '0644',
      alias   => 'npcd',
      source  => "puppet:///modules/nagios/${::lsbdistcodename}/etc/default/npcd",
      notify  => Service['npcd'],
      require => Package['pnp4nagios'],
    }
  }

  file { '/etc/nagios3':
    recurse => true,
    owner   => root,
    group   => root,
    mode    => '0644',
    alias   => 'configs',
    notify  => Service['nagios3'],
    source  => "puppet:///modules/nagios/${::lsbdistcodename}/etc/nagios3",
    require => Package['nagios3'],
  }

  file { '/etc/nagios3/htpasswd.users':
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('nagios/common/etc/nagios3/htpasswd.users.erb'),
    require => Package['nagios3'],
  }

  file { '/etc/nagios3/conf.d':
    recurse => true,
    owner   => root,
    group   => root,
    mode    => '0644',
    alias   => 'conf.d',
    notify  => Service['nagios3'],
    source  => [
      "puppet:///modules/nagios/${::lsbdistcodename}/etc/nagios3/conf.d",
      'puppet:///modules/nagios/common/etc/nagios3/conf.d'
    ],
    require => Package['nagios3'],
  }

  file { [
    '/etc/nagios3/conf.d/contacts_nagios2.cfg',
    '/etc/nagios3/conf.d/extinfo_nagios2.cfg',
    '/etc/nagios3/conf.d/generic-host_nagios2.cfg',
    '/etc/nagios3/conf.d/generic-service_nagios2.cfg',
    '/etc/nagios3/conf.d/hostgroups_nagios2.cfg',
    '/etc/nagios3/conf.d/localhost_nagios2.cfg',
    '/etc/nagios3/conf.d/services_nagios2.cfg',
    '/etc/nagios3/conf.d/timeperiods_nagios2.cfg' ]:
    ensure => absent,
  }

  package { [
    'nagios3',
    'nagios-nrpe-plugin' ]:
    ensure => present,
  }

  if $::lsbdistcodename == 'squeeze' {
    package { 'pnp4nagios':
      ensure => present,
    }
  }

  resources { 'nagios_command':
    purge => true,
  }

  resources { 'nagios_contact':
    purge => true,
  }

  resources { 'nagios_contactgroup':
    purge => true,
  }

  resources { 'nagios_host':
    purge => true,
  }

  resources { 'nagios_hostgroup':
    purge => true,
  }

  resources { 'nagios_hostextinfo':
    purge => true,
  }

  resources { 'nagios_service':
    purge => true,
  }

  resources { 'nagios_servicegroup':
    purge => true,
  }

  service { 'nagios3':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
      File['configs'],
      File['conf.d'],
      Package['nagios3']
    ],
  }

  if $::lsbdistcodename == 'squeeze' {
    service { 'npcd':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      require    => [
        File['npcd'],
        Package['pnp4nagios']
      ],
    }
  }
}