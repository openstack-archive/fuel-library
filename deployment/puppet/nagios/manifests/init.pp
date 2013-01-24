## This is class installed nagios NRPE
# ==Parameters
## proj_name => isolated configuration for project
## services  =>  array of services which you want use
## whitelist =>  array of IP addreses which NRPE trusts
## hostgroup =>  group wich will use in nagios master
# do not forget create it in nagios master
class nagios (
$services,
$servicegroups     = false,
$hostgroup         = false,
$proj_name         = 'nrpe.d',
$whitelist         = '127.0.0.1',
) inherits nagios::params  {

  validate_array($services)

  include nagios::common

  nagios::nrpeconfig { '/etc/nagios/nrpe.cfg':
    whitelist   => $whitelist,
    include_dir => "/etc/nagios/${proj_name}",
  }

  file { "/etc/nagios/${proj_name}":
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
